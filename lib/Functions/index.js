// lib/Functions/index.js

// v2 Imports
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger"); // v2 logger
const v1functions = require("firebase-functions"); // v1 for config fallback
const admin = require("firebase-admin");
const axios = require("axios");("axios")("axios");

admin.initializeApp();
const db = admin.firestore();

// --- Configuración Hugging Face ---
// Primero buscamos en env vars, si no está, fallback a functions.config()
const hfToken =
  process.env.HUGGINGFACE_TOKEN ||
  v1functions.config().huggingface?.token;

const MISTRAL_API_URL =
  "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1";
const BOT_ID = "Mistral_Bot"; // Keep consistent with Flutter app
const BOT_ERROR_ID = "Mistral_Bot_Error"; // Keep consistent with Flutter app
const BOT_EMAIL = "bot@brainibot-mistral.com";

// Recupera los últimos mensajes para contexto
async function getChatHistory(chatId, userId, limit = 10) {
  const snapshot = await db
    .collection("UsersChat")
    .doc(userId)
    .collection("Chats")
    .doc(chatId)
    .collection("Missatges")
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  if (snapshot.empty) return "";

  return snapshot.docs
    .reverse()
    .map(doc => {
      const d = doc.data();
      const author =
        d.idAutor === userId
          ? "Usuari"
          : d.idAutor === BOT_ID
          ? "Bot"
          : "Altre";
      return `${author}: ${d.missatge}`;
    })
    .join("\n");
}

// Función Cloud Function expuesta como onCall (v2 Syntax)
exports.generateOpenAIResponse = onCall({ timeoutSeconds: 120 }, async (request) => {
  logger.info("Arrancando generateOpenAIResponse...");

  // 1) Verificar que tenemos el token de HF
  if (!hfToken) {
    logger.error("Error CRÍTICO: token no configurado");
    throw new HttpsError(
      "internal",
      "El servicio de IA no está configurado correctamente (sin token)."
    );
  }

  // 2) Autenticación
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "L'usuari ha d'estar autenticat."
    );
  }

  const userId = request.auth.uid;
  const userMessage = request.data.message;
  const chatId = request.data.chatId;

  if (!userMessage || !chatId) {
    throw new HttpsError(
      "invalid-argument",
      "Falten 'message' o 'chatId'."
    );
  }

  try {
    // 3) Recuperar contexto
    const chatHistory = await getChatHistory(chatId, userId);

    // 4) Construir el prompt para Mistral
    const systemPrompt = `Eres BrainiBot, un asistente virtual amigable y útil basado en Mistral.
Responde las preguntas del usuario basándote EXCLUSIVAMENTE en el siguiente contexto proporcionado (si lo hay) y el historial de chat.
Si la respuesta no se encuentra en el contexto o historial, di amablemente que no tienes esa información específica. No inventes respuestas.
Sé conciso y directo.`;

    let promptInput = `<s>[INST] ${systemPrompt}\n\n`;
    if (chatHistory) {
      promptInput += `Historial de Chat Reciente:\n${chatHistory}\n\n`;
    }
    promptInput += `[/INST]</s>\n<s>[INST] ${userMessage} [/INST]`;

    logger.info("Prompt formateado para Mistral:", { structuredData: true, prompt: promptInput.substring(0, 500) + '...' });

    // 5) Llamada a la API de Hugging Face
    const payload = {
      inputs: promptInput,
      parameters: {
        max_new_tokens: 200,
        return_full_text: false,
        temperature: 0.7,
        top_p: 0.9,
      },
    };
    const config = {
      headers: {
        Authorization: `Bearer ${hfToken}`,
        "Content-Type": "application/json",
      },
      timeout: 90_000,
    };

    logger.info("Enviando a Hugging Face API...");
    const response = await axios.post(MISTRAL_API_URL, payload, config);
    logger.info("Respuesta recibida de Hugging Face.");

    // 6) Parsear la respuesta
    let botResponse = "No he pogut generar una resposta (format inesperat).";
    const dataResp = response.data;

    if (Array.isArray(dataResp) && dataResp.length > 0 && dataResp[0]?.generated_text) {
      botResponse = dataResp[0].generated_text.trim();
    } else if (typeof dataResp === 'object' && dataResp !== null && dataResp.generated_text) {
      botResponse = dataResp.generated_text.trim();
    } else {
      logger.warn("Formato de respuesta inesperado de HF:", { structuredData: true, response: dataResp });
    }

    botResponse = botResponse.replace(/^<\/s>/, "").trim();
    logger.info("Respuesta del Bot (Mistral):", { structuredData: true, response: botResponse });

    // 7) Guardar en Firestore
    await db
      .collection("UsersChat")
      .doc(userId)
      .collection("Chats")
      .doc(chatId)
      .collection("Missatges")
      .add({
        missatge: botResponse,
        idAutor: BOT_ID,
        emailAutor: BOT_EMAIL,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { success: true, response: botResponse };

  } catch (error) {
    logger.error("Error en generateOpenAIResponse:", error);

    if (axios.isAxiosError(error)) {
      logger.error("Axios Error Details:", {
        message: error.message,
        code: error.code,
        status: error.response?.status,
        data: error.response?.data,
        config: { url: error.config?.url, method: error.config?.method, timeout: error.config?.timeout }
      });
    }

    const fallbackMsg = `Ho sento, he tingut un problema intern (${BOT_ERROR_ID}).`;
    try {
      await db
        .collection("UsersChat")
        .doc(userId)
        .collection("Chats")
        .doc(chatId)
        .collection("Missatges")
        .add({
          missatge: fallbackMsg,
          idAutor: BOT_ERROR_ID,
          emailAutor: BOT_EMAIL,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (dbErr) {
      logger.error("Error guardando mensaje de error en Firestore:", dbErr);
    }

    throw new HttpsError(
      "internal",
      fallbackMsg,
      { originalError: error.message }
    );
  }
});
