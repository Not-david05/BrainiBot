const { onCall, HttpsError } = require("firebase-functions/v2/https");
// No necesitas 'defineString' si usas la opción 'secrets' y accedes vía process.env
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

// Recuperar historial (sin cambios)
async function getChatHistory(chatId, userId, limit = 10) {
    const snapshot = await db
      .collection("UsersChat").doc(userId)
      .collection("Chats").doc(chatId)
      .collection("Missatges")
      .orderBy("timestamp", "desc")
      .limit(limit)
      .get();

    if (snapshot.empty) return [];

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

exports.generateOpenAIResponse = onCall({
    memory: "512MiB",
    timeoutSeconds: 120,
    region: "us-central1",
    secrets: ["HUGGINGFACE_TOKEN"], // Aquí declaras el secreto que tu función necesita
}, async (request) => {
    // --- LEER LA API KEY DESDE process.env (inyectada por la opción 'secrets') ---
    // El secreto "HUGGINGFACE_TOKEN" estará disponible como process.env.HUGGINGFACE_TOKEN
    const HUGGINGFACE_API_KEY = process.env.HUGGINGFACE_TOKEN;

    if (!HUGGINGFACE_API_KEY) {
        logger.error("El secreto HUGGINGFACE_TOKEN no está disponible en process.env. Verifica la configuración de secretos de la función.");
        // Es poco probable que esto suceda si 'secrets' está bien configurado y el secreto existe,
        // pero es una buena comprobación.
        throw new HttpsError("internal", "Error de configuración: La clave API para el servicio de IA no está disponible.");
    }
    // --- FIN DE LECTURA DE API KEY ---

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
        const history = await getChatHistory(chatId, userId);
        const promptLines = [...history];
        promptLines.push(`User: ${userMessage}`);
        promptLines.push(`Assistant:`);
        const prompt = promptLines.join("\n");
        logger.info("Prompt enviado a Hugging Face:", { prompt });

        const response = await axios.post(
            API_URL,
            {
                inputs: prompt,
                parameters: {
                    max_new_tokens: 250,
                    return_full_text: false,
                }
            },
            {
                headers: {
                    Authorization: `Bearer ${HUGGINGFACE_API_KEY}`,
                    "Content-Type": "application/json"
                },
                timeout: 30000,
            }
        );

        logger.info("Respuesta de Hugging Face:", response.data);
        const botResponseText = response.data?.[0]?.generated_text?.trim();
        const botResponse = botResponseText || "No se pudo generar una respuesta.";

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
            errorMessage = error.message;
            errorDetails = { originalError: error.message };
        }

        const fallbackMsg = `Ho sento, he tingut un problema intern (${BOT_ERROR_ID}).${error.response?.status === 401 ? ' Revisa la configuració del secret.' : '' }`;

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