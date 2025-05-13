import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para currentUser y errores
import 'package:brainibot/auth/servei_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Importa cloud_functions

class ServeiChat {
  // Instancias de Firebase
  final ServeiAuth _serveiAuth = ServeiAuth(); // Usas tu servicio de Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Añade instancia de Cloud Functions
  // ¡¡IMPORTANTE!! Asegúrate que 'europe-west1' es tu región correcta.
  // Búscalo en tu consola de Firebase -> Functions -> Dashboard (Panel)
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  // --- IDs DEL BOT (Deben coincidir con index.js) ---
  static const String _botErrorId = "Mistral_Bot_Error"; // Actualizado
  static const String _botEmail = "bot@brainibot-mistral.com"; // Actualizado
  // --------------------------------------------------

  /// Obtiene el usuario actual de forma segura
  User? _getCurrentUser() {
    return _serveiAuth.getUsuariActual();
  }

  /// Crea un nuevo chat. (Sin cambios necesarios aquí)
  Future<String> createChat(String? chatName) async {
    // ... (código existente sin cambios) ...
     final currentUser = _getCurrentUser();
    if (currentUser == null) {
      throw Exception("Usuario no autenticado.");
    }
    String idUsuariActual = currentUser.uid;

    CollectionReference chatsCollection = _firestore
        .collection("UsersChat")
        .doc(idUsuariActual)
        .collection("Chats");

    QuerySnapshot querySnapshot = await chatsCollection.get();
    int chatCount = querySnapshot.docs.length;
    String defaultChatName = "chat ${chatCount + 1}";
    String finalChatName = (chatName?.trim().isEmpty ?? true) ? defaultChatName : chatName!.trim();

    DocumentReference chatDocRef = await chatsCollection.add({
      "name": finalChatName,
      "createdAt": Timestamp.now(),
      "creatorId": idUsuariActual,
    });
    return chatDocRef.id;
  }

  /// Envía un mensaje del usuario y llama a la Cloud Function (generateOpenAIResponse).
  Future<void> enviarMissatge(String chatId, String missatge) async {
    final currentUser = _getCurrentUser();
    if (currentUser == null) {
      print("Error: Usuario no autenticado al intentar enviar mensaje.");
      return;
    }

    final String idUsuariActual = currentUser.uid;
    final String emailUsuariActual = currentUser.email ?? "no-email";
    final Timestamp timestamp = Timestamp.now();

    // 1. Guarda el mensaje del USUARIO
    Map<String, dynamic> nouMissatgeUsuari = {
      "idAutor": idUsuariActual,
      "emailAutor": emailUsuariActual,
      "missatge": missatge,
      "timestamp": timestamp,
    };

    try {
      await _firestore
          .collection("UsersChat")
          .doc(idUsuariActual)
          .collection("Chats")
          .doc(chatId)
          .collection("Missatges")
          .add(nouMissatgeUsuari);

      print("Missatge de l'usuari enviat a Firestore.");

      // 2. Llama a la Cloud Function (el nombre exportado sigue siendo el mismo)
      print("Llamando a la Cloud Function 'generateOpenAIResponse' (que ahora usa Mistral/HF)...");
      // El nombre 'generateOpenAIResponse' es el que exporta la función JS, no necesita cambiar aquí.
      final HttpsCallable callable = _functions.httpsCallable('generateOpenAIResponse');
      final result = await callable.call<Map<String, dynamic>>(
        <String, dynamic>{
          'chatId': chatId,
          'message': missatge,
        },
      );

      print('Cloud Function executada amb èxit: ${result.data}');

    } on FirebaseFunctionsException catch (e) {
      // Error específico de Cloud Functions
      print('Error al llamar a Cloud Function (${e.code}): ${e.message}');
      print('Detalls: ${e.details}');
      // Usa el mensaje de error devuelto por la función si está disponible
      String errorMessage = e.message ?? "No he pogut contactar amb l'assistent.";
      // Guarda un mensaje de error en el chat usando los IDs actualizados
      await _guardarMensajeErrorBot(chatId, idUsuariActual, errorMessage); // Pasa el mensaje de error de la excepción

    } catch (error) {
      // Otros errores (Firestore, etc.)
      print("Error general en enviarMissatge o processar resposta: $error");
      await _guardarMensajeErrorBot(chatId, idUsuariActual, "S'ha produït un error inesperat.");
    }
  }

  /// Función auxiliar PRIVADA para guardar un mensaje de error del bot en Firestore
  Future<void> _guardarMensajeErrorBot(String chatId, String idUsuariActual, String errorMsg) async {
     final Timestamp timestamp = Timestamp.now();
     // --- Usa los IDs y Email actualizados ---
     final botErrorMsg = {
          'missatge': errorMsg,
          'idAutor': _botErrorId, // ID de error de Mistral/HF
          'emailAutor': _botEmail, // Email asociado
          'timestamp': timestamp,
      };
      // ------------------------------------
      try {
           await _firestore
            .collection("UsersChat")
            .doc(idUsuariActual)
            .collection("Chats")
            .doc(chatId)
            .collection("Missatges")
            .add(botErrorMsg);
           print("Mensaje de error del bot guardado en Firestore.");
      } catch(e) {
          print("FATAL: No s'ha pogut guardar el missatge d'error del bot en Firestore: $e");
      }
  }

  /// Retorna un stream con los mensajes del chat indicado. (Sin cambios necesarios aquí)
  Stream<QuerySnapshot> getMissatges(String chatId) {
    // ... (código existente sin cambios) ...
     final currentUser = _getCurrentUser();
     if (currentUser == null) {
       print("Advertencia: Intentando obtener mensajes sin usuario autenticado.");
       return Stream.empty();
     }
     String idUsuariActual = currentUser.uid;

    return _firestore
        .collection("UsersChat")
        .doc(idUsuariActual)
        .collection("Chats")
        .doc(chatId)
        .collection("Missatges")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  /// Retorna un stream con la lista de chats del usuario. (Sin cambios necesarios aquí)
  Stream<QuerySnapshot> getChats() {
    // ... (código existente sin cambios) ...
     final currentUser = _getCurrentUser();
     if (currentUser == null) {
       print("Advertencia: Intentando obtener chats sin usuario autenticado.");
       return Stream.empty();
     }
    String idUsuariActual = currentUser.uid;

    return _firestore
        .collection("UsersChat")
        .doc(idUsuariActual)
        .collection("Chats")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// Elimina un chat y todos sus mensajes. (Sin cambios necesarios aquí)
  Future<void> deleteChat(String chatId) async {
    // ... (código existente sin cambios) ...
     final currentUser = _getCurrentUser();
     if (currentUser == null) {
       print("Error: Usuario no autenticado al intentar eliminar chat.");
       return;
     }
     String idUsuariActual = currentUser.uid;

    try {
      DocumentReference chatDoc = _firestore
          .collection("UsersChat")
          .doc(idUsuariActual)
          .collection("Chats")
          .doc(chatId);

      WriteBatch batch = _firestore.batch();

      QuerySnapshot messagesSnapshot = await chatDoc.collection("Missatges").get();
      for (DocumentSnapshot doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(chatDoc);

      await batch.commit();
      print("Chat y sus mensajes eliminados correctamente.");

    } catch (e) {
      print("Error al eliminar el chat: $e");
    }
  }
}