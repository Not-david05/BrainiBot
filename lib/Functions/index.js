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

// INSTRUCCIÓN DEL SISTEMA ACTUALIZADA
const SYSTEM_INSTRUCTION = `You are a helpful AI assistant. Your primary goal is to directly answer the last user message.
You have been provided with sections titled 'User Profile Information' and 'User Task List' below, if available.
Refer to this information when the user's query seems related to their personal profile, tasks, or schedule.
Do not generate any 'User:' or 'Human:' turns yourself after your response.
Provide only the assistant's response to the user's question, without repeating the user's question before your answer.
If the user asks about something in their profile or tasks, use the provided information to answer.
If this information is not relevant to the current question, you can ignore it.`;

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
            userContextString += "---\n"; // Separador
        }

        // 2. Obtener Tareas Recientes/Importantes
        const tasksSnapshot = await db
            .collection("TareasUsers")
            .doc(userId)
            .collection("Tareas")
            .where("completed", "==", false) // Ejemplo: solo tareas no completadas
            .orderBy("date", "asc") // Ordenar por fecha más próxima
            .limit(tasksLimit)
            .get();

        if (!tasksSnapshot.empty) {
            userContextString += "User Task List (Upcoming/Pending):\n";
            tasksSnapshot.docs.forEach(doc => {
                const taskData = doc.data();
                let taskStr = `- Task: ${taskData.title || "Untitled Task"}`;
                if (taskData.category) taskStr += ` (Category: ${taskData.category})`;
                if (taskData.priority) taskStr += ` (Priority: ${taskData.priority})`;
                if (taskData.date) {
                    const date = taskData.date.toDate ? taskData.date.toDate() : new Date(taskData.date); // Manejar Timestamp o string
                    taskStr += ` (Due: ${date.toLocaleDateString()})`;
                }
                if (taskData.time) taskStr += ` (Time: ${taskData.time})`;
                userContextString += `${taskStr}\n`;
            });
        }

        return userContextString.trim() || null; // Retornar null si no se encontró nada

    } catch (error) {
        logger.error("Error fetching user context data for user:", userId, error);
        return null; // No bloquear el chat si esto falla
    }
}
// --- FIN DE LA FUNCIÓN ACTUALIZADA ---

exports.generateOpenAIResponse = onCall({
    memory: "512MiB",
    timeoutSeconds: 300,
    region: "us-central1",
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
            getUserContextData(userId, 5) // Obtener hasta 5 tareas pendientes
        ]);

        const promptElements = [];

        promptElements.push(SYSTEM_INSTRUCTION);
        promptElements.push("---"); 

        if (userContext) { // Si hay datos de perfil o tareas
            promptElements.push(userContext); // userContext ya tiene sus propios encabezados y formato
            promptElements.push("---"); 
        }

        if (chatHistoryLines.length > 0) {
            promptElements.push("Chat History:");
            promptElements.push(...chatHistoryLines);
            promptElements.push("---");
        }

        promptElements.push(`User: ${userMessage}`);
        promptElements.push(`Assistant:`);

        const prompt = promptElements.join("\n\n");
        
        logger.info("Prompt enviado a Hugging Face:", { prompt });

        const response = await axios.post(
            API_URL,
            {
                inputs: prompt,
                parameters: {
                    max_new_tokens: 350, // Aumentado un poco por si el contexto es largo
                    return_full_text: false,
                    stop: ["\nUser:", " User:"],
                }
            },
            {
                headers: {
                    Authorization: `Bearer ${HUGGINGFACE_API_KEY}`,
                    "Content-Type": "application/json"
                },
                timeout: 240000,
            }
        );

        logger.info("Respuesta RAW de Hugging Face:", response.data);
        let rawGeneratedText = response.data?.[0]?.generated_text;
        let finalBotResponseText = "";

        if (rawGeneratedText) {
            rawGeneratedText = rawGeneratedText.trim();
            
            const potentialEchoPrefix = `User: ${userMessage}\nAssistant:`;
            if (rawGeneratedText.startsWith(potentialEchoPrefix)) {
                logger.info("Eco del prompt detectado, eliminándolo.");
                finalBotResponseText = rawGeneratedText.substring(potentialEchoPrefix.length).trim();
            } else {
                finalBotResponseText = rawGeneratedText;
            }
        }

        const botResponse = finalBotResponseText.trim() || "No se pudo generar una respuesta.";
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
        // ... (Manejo de errores sin cambios) ...
        let errorMessage = "Error desconocido al procesar la solicitud.";
        let errorDetails = {};

        if (axios.isAxiosError(error)) {
            logger.error("Error de Axios en Hugging Face:", {
                message: error.message,
                status: error.response?.status,
                data: error.response?.data,
            });
            errorMessage = `Error al contactar el servicio de IA: ${error.message}`;
            if (error.response?.status === 401) {
                errorMessage = `Error de autenticación con el servicio de IA (${BOT_ERROR_ID}). Verifica la API Key (Secreto).`;
            } else if (error.response?.status === 503) {
                errorMessage = `El servicio de IA (Hugging Face) está temporalmente sobrecargado o no disponible (Error 503). Inténtalo más tarde.`;
            }
             else if (error.response?.status) {
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
            errorMessage = error.message;
            errorDetails = { originalError: error.message };
        }

        const fallbackMsg = `Ho sento, he tingut un problema intern (${BOT_ERROR_ID}).${error.response?.status === 401 ? ' Revisa la configuració del secret.' : (error.response?.status === 503 ? ' El servei de IA sembla estar ocupat.' : '') }`;

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
        throw new HttpsError("internal", fallbackMsg, errorDetails);
    }
});