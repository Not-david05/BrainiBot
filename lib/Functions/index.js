const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios"); // Importa axios para hacer llamadas HTTP

admin.initializeApp();
const db = admin.firestore();

// --- Configuración Hugging Face ---
let hfToken;
const MISTRAL_API_URL = "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1"; // URL del modelo Mistral en HF
const BOT_ID = "Mistral_Bot"; // Nuevo ID para el bot
const BOT_ERROR_ID = "Mistral_Bot_Error"; // ID para errores
const BOT_EMAIL = "bot@brainibot-mistral.com"; // Email para el bot

try {
    hfToken = functions.config().huggingface?.token;
    if (!hfToken) {
        console.error("Error CRÍTICO: El Token de API de Hugging Face NO está configurado. Ejecuta: firebase functions:config:set huggingface.token=\"hf_TU_TOKEN_AQUI\"");
    } else {
        console.log("Token de Hugging Face cargado.");
    }
} catch (error) {
     console.error("Error al obtener la configuración de Firebase Functions:", error);
     // hfToken seguirá sin definir, la función fallará si se intenta usar
}

// --- Recuperación de Contexto (Sin cambios, pero usa BOT_ID) ---
async function getChatHistory(chatId, userId, limit = 10) {
    const messagesRef = db.collection("UsersChat").doc(userId).collection("Chats").doc(chatId).collection("Missatges");
    const snapshot = await messagesRef.orderBy("timestamp", "desc").limit(limit).get();

    if (snapshot.empty) {
        return "";
    }

    // Formatea los mensajes: Usa BOT_ID para identificar respuestas anteriores del bot
    return snapshot.docs.reverse()
        .map(doc => {
            const data = doc.data();
            const author = data.idAutor === userId ? "Usuari" : (data.idAutor === BOT_ID ? "Bot" : "Altre"); // Identifica al bot por su nuevo ID
            return `${author}: ${data.missatge}`;
        })
        .join("\n");
}

// --- Función Principal (Modificada para Hugging Face) ---
// Mantenemos el nombre exportado para no romper la llamada desde Flutter,
// pero la lógica interna ahora usa Hugging Face/Mistral.
exports.generateOpenAIResponse = functions.region('europe-west1').runWith({ timeoutSeconds: 120 }).https.onCall(async (data, context) => { // Añadir región y timeout
    // Verifica que el token de HF esté disponible
    if (!hfToken) {
         console.error("El Token de Hugging Face no está disponible. Verifica la configuración.");
         // Podríamos intentar guardar un mensaje de error aquí si la función fallara antes del try/catch principal
         throw new functions.https.HttpsError("internal", "El servicio de IA no está configurado correctamente (sin token).");
    }

    // Verifica autenticación
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "L'usuari ha d'estar autenticat.");
    }

    const userId = context.auth.uid;
    const userMessage = data.message;
    const chatId = data.chatId;

    if (!userMessage || !chatId) {
        throw new functions.https.HttpsError("invalid-argument", "Falten 'message' o 'chatId'.");
    }

    try {
        // 1. Recuperar Contexto
        const chatHistory = await getChatHistory(chatId, userId);

        // 2. Construir el Prompt para Mistral Instruct
        const systemPrompt = `Eres BrainiBot, un asistente virtual amigable y útil basado en Mistral.
        Responde las preguntas del usuario basándote EXCLUSIVAMENTE en el siguiente contexto proporcionado (si lo hay) y el historial de chat.
        Si la respuesta no se encuentra en el contexto o historial, di amablemente que no tienes esa información específica. No inventes respuestas.
        Sé conciso y directo.`;

        let promptInput = `<s>[INST] ${systemPrompt}\n\n`;
        if (chatHistory) {
            promptInput += `Historial de Chat Reciente:\n${chatHistory}\n\n`;
        }
        promptInput += `[/INST]</s>\n`;
        promptInput += `<s>[INST] ${userMessage} [/INST]`;

        console.log("Prompt formateado para Mistral:", promptInput);

        // 3. Llamar a la API de Inferencia de Hugging Face
        const payload = {
            inputs: promptInput,
            parameters: {
                max_new_tokens: 200,
                return_full_text: false,
                temperature: 0.7,
                top_p: 0.9,
            }
        };
        const config = {
            headers: {
                'Authorization': `Bearer ${hfToken}`,
                'Content-Type': 'application/json'
            },
            timeout: 1000 * 90 // 90 segundos
        };

        console.log("Enviando a Hugging Face API...");
        const response = await axios.post(MISTRAL_API_URL, payload, config);
        console.log("Respuesta recibida de Hugging Face.");

        // 4. Extraer la respuesta del Bot
        let botResponse = "No he pogut generar una resposta (format inesperat).";
        if (response.data && Array.isArray(response.data) && response.data.length > 0 && response.data[0].generated_text) {
             botResponse = response.data[0].generated_text.trim();
             // --- CORRECCIÓN AQUÍ ---
             // Escapar la barra inclinada dentro del regex
             botResponse = botResponse.replace(/^<\/s>/, '').trim(); // Limpiar posible tag </s> sobrante
             // -----------------------
        } else {
             console.warn("Formato de respuesta inesperado de HF:", JSON.stringify(response.data));
        }

        console.log("Respuesta del Bot (Mistral):", botResponse);

        // 5. Guardar la respuesta del Bot en Firestore
        const botMessageData = {
            missatge: botResponse,
            idAutor: BOT_ID, // Usa el nuevo ID del bot
            emailAutor: BOT_EMAIL, // Usa el nuevo email
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        };

        const messagesRef = db.collection("UsersChat").doc(userId).collection("Chats").doc(chatId).collection("Missatges");
        await messagesRef.add(botMessageData);

        console.log(`Respuesta de ${BOT_ID} guardada en chat ${chatId} para usuario ${userId}`);
        return { success: true, response: botResponse };

    } catch (error) {
        console.error(`Error en ${BOT_ID} Response Function:`, error);

        let errorMessageForChat = `Ho sento, he tingut un problema intern (${BOT_ID}).`;
        let httpsErrorCode = "internal";

        if (axios.isAxiosError(error)) {
            console.error('Error de Axios:', error.message);
            if (error.response) {
                console.error('Datos de error:', error.response.data);
                console.error('Estado de error:', error.response.status);
                errorMessageForChat = `Ho sento, hi ha hagut un problema amb el servei d'IA (${error.response.status}).`;
                if (error.response.status === 401) {
                    errorMessageForChat += " Problema de autenticació amb Hugging Face.";
                    httpsErrorCode = "unauthenticated";
                } else if (error.response.status === 429) {
                     errorMessageForChat += " S'ha superat el límit de sol·licituds.";
                     httpsErrorCode = "resource-exhausted";
                } else if (error.response.status >= 500) {
                     errorMessageForChat += " El servei d'IA té problemes interns.";
                }
                 const hfError = error.response.data?.error;
                 if (hfError) {
                     errorMessageForChat += ` Detall: ${hfError}`;
                 }
            } else if (error.request) {
                console.error('No se recibió respuesta:', error.request);
                errorMessageForChat = "Ho sento, no he rebut resposta del servei d'IA.";
                httpsErrorCode = "unavailable";
            } else {
                console.error('Error al configurar la solicitud:', error.message);
                 errorMessageForChat = `Ho sento, hi ha hagut un error en preparar la sol·licitud (${BOT_ID}).`;
            }
        } else {
            console.error('Error no relacionado con Axios:', error);
        }

        // Intentar guardar un mensaje de error en el chat
        try {
             const errorMessageData = {
                missatge: errorMessageForChat,
                idAutor: BOT_ERROR_ID, // Usa el nuevo ID de error
                emailAutor: BOT_EMAIL, // Usa el nuevo email
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            };
             const messagesRef = db.collection("UsersChat").doc(userId).collection("Chats").doc(chatId).collection("Missatges");
             await messagesRef.add(errorMessageData);
        } catch (dbError) {
            console.error("Error al guardar el mensaje de error en Firestore:", dbError);
        }

        // Lanzar el error para que el cliente sepa que algo falló
        throw new functions.https.HttpsError(httpsErrorCode, errorMessageForChat, error.message);
    }
});