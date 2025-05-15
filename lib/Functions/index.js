const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

// Configuración del modelo Hugging Face
const MODEL_NAME = "mistralai/Mistral-7B-Instruct-v0.3";
const API_URL = `https://api-inference.huggingface.co/models/${MODEL_NAME}`;

const BOT_ID = "HF_Mistral_Bot";
const BOT_ERROR_ID = "HF_Mistral_Error";
const BOT_EMAIL = "bot@brainibot-mistral.com";

// INSTRUCCIÓN DEL SISTEMA
// Esta instrucción se añade al principio del prompt para guiar al modelo.
const SYSTEM_INSTRUCTION = "You are a helpful AI assistant. Your primary goal is to directly answer the last user message. Do not generate any 'User:' or 'Human:' turns yourself after your response. Provide only the assistant's response to the user's question, without repeating the user's question before your answer.";

async function getChatHistory(chatId, userId, limit = 10) {
    const snapshot = await db
      .collection("UsersChat").doc(userId)
      .collection("Chats").doc(chatId)
      .collection("Missatges")
      .orderBy("timestamp", "desc")
      .limit(limit)
      .get();

    if (snapshot.empty) {
        return []; // Si no hay historial, devolvemos un array vacío. La instrucción del sistema se añadirá por separado.
    }

    return snapshot.docs.reverse().map(doc => {
        const data = doc.data();
        const role = data.idAutor === userId ? "user" :
                     data.idAutor === BOT_ID    ? "assistant" : null;
        if (!role) return null; // Ignorar mensajes que no sean del usuario o del BOT_ID principal
        if (role === 'user') {
            return `User: ${data.missatge}`;
        }
        return `Assistant: ${data.missatge}`;
    }).filter(Boolean);
}

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
        const chatHistoryLines = await getChatHistory(chatId, userId);

        const promptElements = [];

        // 1. Añadir la INSTRUCCIÓN DEL SISTEMA al principio.
        promptElements.push(SYSTEM_INSTRUCTION);

        // 2. Añadir el historial de chat si existe.
        if (chatHistoryLines.length > 0) {
            promptElements.push(...chatHistoryLines);
        }

        // 3. Añadir el mensaje actual del usuario.
        promptElements.push(`User: ${userMessage}`);

        // 4. Indicar que es el turno del asistente.
        promptElements.push(`Assistant:`);

        // Unir todos los elementos con un salto de línea.
        // Es importante que el formato sea consistente con lo que el modelo espera.
        const prompt = promptElements.join("\n");
        
        logger.info("Prompt enviado a Hugging Face:", { prompt });

        const response = await axios.post(
            API_URL,
            {
                inputs: prompt,
                parameters: {
                    max_new_tokens: 250,
                    return_full_text: false,
                    stop: ["\nUser:", " User:", "\nHuman:", " Human:"], // Secuencias de parada
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

        logger.info("Respuesta RAW de Hugging Face:", response.data); // Es útil loguear la respuesta raw para depurar
        let rawGeneratedText = response.data?.[0]?.generated_text;
        let finalBotResponseText = "";

        if (rawGeneratedText) {
            rawGeneratedText = rawGeneratedText.trim();
            
            // Lógica para eliminar el eco del mensaje del usuario si el modelo lo repite
            // Esto es útil si la instrucción del sistema y las secuencias de parada no lo evitan completamente.
            const potentialEchoPrefix = `User: ${userMessage}\nAssistant:`;
            if (rawGeneratedText.startsWith(potentialEchoPrefix)) {
                logger.info("Eco del prompt detectado, eliminándolo.");
                finalBotResponseText = rawGeneratedText.substring(potentialEchoPrefix.length).trim();
            } else {
                finalBotResponseText = rawGeneratedText;
            }
        }

        // Si después de quitar el eco, la respuesta está vacía (porque las secuencias de parada actuaron
        // justo al principio de un eco, o el modelo no generó nada más), usar un mensaje por defecto.
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