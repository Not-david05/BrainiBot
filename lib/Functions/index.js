const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

const MODEL_NAME = "mistralai/Mistral-7B-Instruct-v0.3";
const API_URL = `https://api-inference.huggingface.co/models/${MODEL_NAME}`;

const BOT_ID = "HF_Mistral_Bot";
const BOT_ERROR_ID = "HF_Mistral_Error";
const BOT_EMAIL = "bot@brainibot-mistral.com";

// --- INSTRUCCIÓN DEL SISTEMA ACTUALIZADA ---
const SYSTEM_INSTRUCTION = `You are a helpful AI assistant. Your primary goal is to directly answer the last user message.
You have been provided with sections titled 'User Profile Information' and 'User Task List' below, if available.
Refer to this information when the user's query seems related to their personal profile, tasks, or schedule.

TASK MANAGEMENT CAPABILITIES:
You can help the user create and delete tasks.
- To CREATE a task:
  - Gather all necessary details: title (required), category (required, choose from: Estudios, Diaria, Recados, Trabajo, Personal, Otros), priority (required, choose from: Urgente 5★, Alta 4★, Media 3★, Baja 2★, Opcional 1★), date (required, format YYYY-MM-DD), time (optional, format HH:MM in 24-hour), description (optional).
  - If 'Otros' category is chosen, ask for a custom category name.
  - Once you have all details, confirm with the user. If they agree, include the following structured command in your response (DO NOT show this command to the user, it's for internal processing):
    [TOOL_CREATE_TASK]{"title": "Task Title", "category": "CategoryName", "customCategory": "CustomCategoryNameIfOtros", "priority": "PriorityLevel", "date": "YYYY-MM-DD", "time": "HH:MM", "description": "Task Description"}[/TOOL_CREATE_TASK]
  - Example user request: "Create a task to buy milk for tomorrow, category Recados, priority Alta." You should ask for the exact date for "tomorrow".
- To DELETE a task:
  - The 'User Task List' provides tasks with an 'id' (e.g., id: abc123xyz).
  - Ask the user to confirm which task they want to delete, ideally by referencing information from the list.
  - Once confirmed, include the following structured command in your response (DO NOT show this command to the user):
    [TOOL_DELETE_TASK]{"task_id": "firestore_document_id_of_the_task"}[/TOOL_DELETE_TASK]
  - Example user request: "Delete my task 'Doctor appointment'." If there's a task with that title, confirm and use its ID.

IMPORTANT:
- After a tool command, your response to the user should be a natural language confirmation (e.g., "Okay, I've created the task..." or "Alright, I've deleted the task...").
- Do not generate any 'User:' or 'Human:' turns yourself after your response.
- Provide only the assistant's response to the user's question, without repeating the user's question before your answer.
- If the user asks about something in their profile or tasks, use the provided information to answer.
- If profile/task information is not relevant to the current question, you can ignore it.`;
// --- FIN INSTRUCCIÓN DEL SISTEMA ---

async function getChatHistory(chatId, userId, limit = 10) {
    const snapshot = await db
      .collection("UsersChat").doc(userId)
      .collection("Chats").doc(chatId)
      .collection("Missatges")
      .orderBy("timestamp", "desc")
      .limit(limit)
      .get();

    if (snapshot.empty) {
        return [];
    }

    return snapshot.docs.reverse().map(doc => {
        const data = doc.data();
        const role = data.idAutor === userId ? "user" :
                     data.idAutor === BOT_ID    ? "assistant" : null;
        if (!role) return null;
        if (role === 'user') {
            return `User: ${data.missatge}`;
        }
        return `Assistant: ${data.missatge}`;
    }).filter(Boolean);
}

// --- FUNCIÓN ACTUALIZADA PARA OBTENER DATOS DEL USUARIO (PERFIL Y TAREAS) ---
async function getUserContextData(userId, tasksLimit = 5) {
    let userContextString = "";

    try {
        // 1. Obtener Datos del Perfil
        const perfilDoc = await db
            .collection("Usuaris")
            .doc(userId)
            .collection("Perfil")
            .doc("DatosPersonales")
            .get();

        if (perfilDoc.exists) {
            const perfilData = perfilDoc.data();
            userContextString += "User Profile Information:\n";
            if (perfilData.nombre) userContextString += `- Name: ${perfilData.nombre} ${perfilData.apellidos || ''}\n`;
            if (perfilData.fechaNacimiento) userContextString += `- Date of Birth: ${perfilData.fechaNacimiento}\n`;
            if (perfilData.genero) userContextString += `- Gender: ${perfilData.genero}\n`;
            if (perfilData.situacionLaboral) userContextString += `- Employment Status: ${perfilData.situacionLaboral}\n`;
            userContextString += "---\n";
        }

        // 2. Obtener Tareas Recientes/Importantes
        const tasksSnapshot = await db
            .collection("TareasUsers")
            .doc(userId)
            .collection("Tareas")
            .where("completed", "==", false)
            .orderBy("date", "asc")
            .limit(tasksLimit)
            .get();

        if (!tasksSnapshot.empty) {
            userContextString += "User Task List (Upcoming/Pending):\n";
            tasksSnapshot.docs.forEach(doc => {
                const taskData = doc.data();
                // AÑADIR EL ID DEL DOCUMENTO DE LA TAREA PARA POSIBLE ELIMINACIÓN
                let taskStr = `- Task (id: ${doc.id}): ${taskData.title || "Untitled Task"}`;
                if (taskData.category) taskStr += ` (Category: ${taskData.category})`;
                if (taskData.priority) taskStr += ` (Priority: ${taskData.priority})`;
                if (taskData.date) {
                    const date = taskData.date.toDate ? taskData.date.toDate() : new Date(taskData.date);
                    taskStr += ` (Due: ${date.toLocaleDateString()})`;
                }
                if (taskData.time) taskStr += ` (Time: ${taskData.time})`;
                userContextString += `${taskStr}\n`;
            });
        }

        return userContextString.trim() || null;

    } catch (error) {
        logger.error("Error fetching user context data for user:", userId, error);
        return null;
    }
}
// --- FIN DE LA FUNCIÓN ACTUALIZADA ---

// --- NUEVAS FUNCIONES HELPER PARA TAREAS ---
async function createTaskInFirestore(userId, taskData) {
    logger.info("Attempting to create task for user:", userId, "with data:", taskData);

    if (!taskData.title || !taskData.category || !taskData.priority || !taskData.date) {
        throw new HttpsError("invalid-argument", "Missing required task fields (title, category, priority, date).");
    }

    let categoryToSave = taskData.category;
    if (taskData.category.toLowerCase() === 'otros' && taskData.customCategory) {
        categoryToSave = taskData.customCategory.trim();
    } else if (taskData.category.toLowerCase() === 'otros' && !taskData.customCategory) {
        throw new HttpsError("invalid-argument", "Custom category name is required when 'Otros' is selected.");
    }

    // Validar formato de fecha YYYY-MM-DD
    if (!/^\d{4}-\d{2}-\d{2}$/.test(taskData.date)) {
        throw new HttpsError("invalid-argument", "Invalid date format. Please use YYYY-MM-DD.");
    }
    const dateObject = new Date(taskData.date);
    if (isNaN(dateObject.getTime())) {
         throw new HttpsError("invalid-argument", "Invalid date value.");
    }
    // Ajustar a UTC para evitar problemas de zona horaria al guardar, Firestore lo guardará como timestamp
    const utcDate = new Date(Date.UTC(dateObject.getUTCFullYear(), dateObject.getUTCMonth(), dateObject.getUTCDate()));


    let taskTime = null;
    if (taskData.time) {
        // Validar formato de hora HH:MM
        if (!/^\d{2}:\d{2}$/.test(taskData.time)) {
            throw new HttpsError("invalid-argument", "Invalid time format. Please use HH:MM (24-hour).");
        }
        taskTime = taskData.time;
    }

    const newTask = {
        title: taskData.title.trim(),
        category: categoryToSave,
        priority: taskData.priority,
        date: admin.firestore.Timestamp.fromDate(utcDate),
        time: taskTime, // Puede ser null
        description: taskData.description ? taskData.description.trim() : "",
        completed: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        userId: userId, // Guardar el userId para referencia si es necesario
    };

    try {
        const taskRef = await db.collection("TareasUsers").doc(userId).collection("Tareas").add(newTask);
        logger.info("Task created successfully with ID:", taskRef.id);
        return `Task "${newTask.title}" created successfully.`;
    } catch (error) {
        logger.error("Error creating task in Firestore:", error);
        throw new HttpsError("internal", "Failed to create task in database.");
    }
}

async function deleteTaskInFirestore(userId, taskId) {
    logger.info("Attempting to delete task for user:", userId, "with task ID:", taskId);

    if (!taskId) {
        throw new HttpsError("invalid-argument", "Task ID is required for deletion.");
    }

    try {
        const taskRef = db.collection("TareasUsers").doc(userId).collection("Tareas").doc(taskId);
        const taskDoc = await taskRef.get();

        if (!taskDoc.exists) {
            logger.warn("Task not found for deletion:", taskId);
            return `Task with ID "${taskId}" not found or already deleted.`;
            // throw new HttpsError("not-found", "Task not found."); No lanzar error, el bot puede decirlo
        }
        const taskTitle = taskDoc.data().title || "Untitled Task";
        await taskRef.delete();
        logger.info("Task deleted successfully:", taskId);
        return `Task "${taskTitle}" (ID: ${taskId}) deleted successfully.`;
    } catch (error) {
        logger.error("Error deleting task in Firestore:", error);
        throw new HttpsError("internal", "Failed to delete task from database.");
    }
}
// --- FIN NUEVAS FUNCIONES HELPER ---


exports.generateOpenAIResponse = onCall({
    memory: "1GiB", // Aumentado por si el prompt y contexto crecen más
    timeoutSeconds: 300,
    region: "us-central1", // Mantén tu región original si es us-central1
    secrets: ["HUGGINGFACE_TOKEN"],
}, async (request) => {
    const HUGGINGFACE_API_KEY = process.env.HUGGINGFACE_TOKEN;

    if (!HUGGINGFACE_API_KEY) {
        logger.error("El secreto HUGGINGFACE_TOKEN no está disponible en process.env.");
        throw new HttpsError("internal", "Error de configuración: La clave API para el servicio de IA no está disponible.");
    }

    if (!request.auth) {
        throw new HttpsError("unauthenticated", "El usuario debe estar autenticado.");
    }

    const userId = request.auth.uid;
    const userMessage = request.data.message;
    const chatId = request.data.chatId;

    if (!userMessage || !chatId) {
        throw new HttpsError("invalid-argument", "Faltan 'message' o 'chatId'.");
    }

    try {
        const [chatHistoryLines, userContext] = await Promise.all([
            getChatHistory(chatId, userId),
            getUserContextData(userId, 10) // Aumentar un poco el límite de tareas para mejor contexto
        ]);

        const promptElements = [];
        promptElements.push(SYSTEM_INSTRUCTION);
        promptElements.push("---");

        if (userContext) {
            promptElements.push(userContext);
            promptElements.push("---");
        }

        if (chatHistoryLines.length > 0) {
            promptElements.push("Chat History:");
            promptElements.push(...chatHistoryLines);
            promptElements.push("---");
        }

        promptElements.push(`User: ${userMessage}`);
        promptElements.push(`Assistant:`); // Model will continue from here

        const prompt = promptElements.join("\n\n");
        
        logger.info("Prompt enviado a Hugging Face (longitud):", prompt.length);
        if (prompt.length < 2000) { // Loggear prompts cortos para debug
             logger.info("Prompt enviado a Hugging Face (contenido):", { prompt });
        }


        const hfResponse = await axios.post(
            API_URL,
            {
                inputs: prompt,
                parameters: {
                    max_new_tokens: 500, // Aumentado para permitir JSON de tools + respuesta
                    return_full_text: false,
                    stop: ["\nUser:", " User:", "\nHuman:", " Human:"], // Agregado Human stop
                    temperature: 0.7, // Un poco de creatividad
                    top_p: 0.9,
                    do_sample: true,
                }
            },
            {
                headers: {
                    Authorization: `Bearer ${HUGGINGFACE_API_KEY}`,
                    "Content-Type": "application/json"
                },
                timeout: 240000, // 4 minutos
            }
        );

        logger.info("Respuesta RAW de Hugging Face:", hfResponse.data);
        let rawGeneratedText = hfResponse.data?.[0]?.generated_text;
        let finalBotResponseText = "No se pudo generar una respuesta."; // Default
        let taskActionResultMessage = null;

        if (rawGeneratedText) {
            rawGeneratedText = rawGeneratedText.trim();
            finalBotResponseText = rawGeneratedText; // Inicialmente, la respuesta es todo lo generado

            // --- PROCESAMIENTO DE TOOLS ---
            const createToolRegex = /\[TOOL_CREATE_TASK\]([\s\S]*?)\[\/TOOL_CREATE_TASK\]/;
            const deleteToolRegex = /\[TOOL_DELETE_TASK\]([\s\S]*?)\[\/TOOL_DELETE_TASK\]/;

            const createMatch = rawGeneratedText.match(createToolRegex);
            const deleteMatch = rawGeneratedText.match(deleteToolRegex);

            if (createMatch && createMatch[1]) {
                try {
                    const taskData = JSON.parse(createMatch[1].trim());
                    logger.info("Tool Create Task detected. Data:", taskData);
                    taskActionResultMessage = await createTaskInFirestore(userId, taskData);
                    // Eliminar el tag de la respuesta final al usuario
                    finalBotResponseText = finalBotResponseText.replace(createToolRegex, "").trim();
                    // Si la respuesta del bot estaba vacía después de quitar el tag, usar el mensaje de la acción
                    if (!finalBotResponseText && taskActionResultMessage) finalBotResponseText = taskActionResultMessage;
                    else if (taskActionResultMessage) finalBotResponseText += ` (${taskActionResultMessage})`;


                } catch (toolError) {
                    logger.error("Error processing TOOL_CREATE_TASK:", toolError);
                    // Podrías querer que el bot informe de este error específico
                    finalBotResponseText = `Hubo un error al intentar crear la tarea: ${toolError.message || "datos inválidos"}. Por favor, inténtalo de nuevo o revisa los datos.`;
                    finalBotResponseText = finalBotResponseText.replace(createToolRegex, "").trim(); // Asegurar que se quite el tag
                }
            } else if (deleteMatch && deleteMatch[1]) {
                try {
                    const { task_id } = JSON.parse(deleteMatch[1].trim());
                    logger.info("Tool Delete Task detected. Task ID:", task_id);
                    taskActionResultMessage = await deleteTaskInFirestore(userId, task_id);
                    finalBotResponseText = finalBotResponseText.replace(deleteToolRegex, "").trim();
                     if (!finalBotResponseText && taskActionResultMessage) finalBotResponseText = taskActionResultMessage;
                     else if (taskActionResultMessage) finalBotResponseText += ` (${taskActionResultMessage})`;

                } catch (toolError) {
                    logger.error("Error processing TOOL_DELETE_TASK:", toolError);
                    finalBotResponseText = `Hubo un error al intentar eliminar la tarea: ${toolError.message || "ID inválido"}.`;
                    finalBotResponseText = finalBotResponseText.replace(deleteToolRegex, "").trim();
                }
            }
            
            // Limpiar cualquier posible eco del prompt si return_full_text fuera true o el modelo lo hiciera
            const potentialEchoPrefix = `Assistant:`; // Si el modelo empieza con esto tras la señal
            if (finalBotResponseText.startsWith(potentialEchoPrefix)) {
                 finalBotResponseText = finalBotResponseText.substring(potentialEchoPrefix.length).trim();
            }
            // Otra forma de eco
             const fullUserMessagePrefix = `User: ${userMessage}\n\nAssistant:`;
            if (finalBotResponseText.startsWith(fullUserMessagePrefix)) {
                logger.info("Eco completo del prompt detectado, eliminándolo.");
                finalBotResponseText = finalBotResponseText.substring(fullUserMessagePrefix.length).trim();
            }


            if (finalBotResponseText.trim() === "") {
                finalBotResponseText = taskActionResultMessage || "Acción procesada, pero no se generó texto adicional.";
            }
        }
        
        const botResponse = finalBotResponseText.trim() || "No he podido generar una respuesta esta vez.";
        logger.info("Respuesta final del bot:", { botResponse });

        await db.collection("UsersChat").doc(userId)
            .collection("Chats").doc(chatId)
            .collection("Missatges").add({
                missatge: botResponse,
                idAutor: BOT_ID,
                emailAutor: BOT_EMAIL,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

        return { success: true, response: botResponse };

    } catch (error) {
        let errorMessage = "Error desconocido al procesar la solicitud.";
        let errorDetails = {};

        if (error instanceof HttpsError) { // Si es un error que ya hemos lanzado (e.g. validación de taskData)
            logger.warn("HttpsError capturado:", { code: error.code, message: error.message, details: error.details });
            errorMessage = error.message;
            errorDetails = error.details || { originalCode: error.code };
             // No sobreescribir el mensaje de error específico
        } else if (axios.isAxiosError(error)) {
            logger.error("Error de Axios en Hugging Face:", {
                message: error.message,
                status: error.response?.status,
                data: error.response?.data,
            });
            errorMessage = `Error al contactar el servicio de IA: ${error.message}`;
            if (error.response?.status === 401) {
                errorMessage = `Error de autenticación con el servicio de IA (${BOT_ERROR_ID}). Verifica la API Key (Secreto).`;
            } else if (error.response?.status === 422) {
                 errorMessage = `El servicio de IA (Hugging Face) indica un problema con los datos enviados (Error 422). Esto puede ser por un prompt demasiado largo. Detalles: ${JSON.stringify(error.response.data)}`;
            } else if (error.response?.status === 503) {
                errorMessage = `El servicio de IA (Hugging Face) está temporalmente sobrecargado o no disponible (Error 503). Inténtalo más tarde.`;
            } else if (error.response?.status) {
                errorMessage = `Error del servicio de IA (${error.response.status}): ${error.response.data?.error || error.message}`;
            }
            errorDetails = {
                originalError: error.message,
                statusCode: error.response?.status,
                responseData: error.response?.data
            };
        } else {
            logger.error("Error general en la función:", {
                message: error.message,
                stack: error.stack,
            });
            errorMessage = error.message; // Mantenemos el mensaje original del error si es genérico
            errorDetails = { originalError: error.message };
        }

        // El mensaje de fallback ahora usa el errorMessage que hemos construido
        const fallbackMsg = `Ho sento, he tingut un problema: ${errorMessage.startsWith("Error") ? errorMessage : BOT_ERROR_ID + " - " + errorMessage}.`;

        try {
            await db.collection("UsersChat").doc(userId)
                .collection("Chats").doc(chatId)
                .collection("Missatges").add({
                    missatge: fallbackMsg,
                    idAutor: BOT_ERROR_ID,
                    emailAutor: BOT_EMAIL,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
        } catch (dbError) {
            logger.error("Error al guardar mensaje de error en DB:", dbError);
        }
        // Propagar el error con el mensaje detallado que se guardó en el chat
        throw new HttpsError("internal", fallbackMsg, errorDetails);
    }
});