import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brainibot/auth/servei_auth.dart';

class ServeiChat {
  final ServeiAuth _serveiAuth = ServeiAuth();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crea un nuevo chat. Si [chatName] es nulo o vacío, se asigna el nombre "chat X"
  Future<String> createChat(String? chatName) async {
    String idUsuariActual = _serveiAuth.getUsuariActual()!.uid;
    CollectionReference chatsCollection = _firestore
        .collection("UsersChat")
        .doc(idUsuariActual)
        .collection("Chats");

    // Contar los chats existentes para asignar el nombre por defecto
    QuerySnapshot querySnapshot = await chatsCollection.get();
    int chatCount = querySnapshot.docs.length;
    String defaultChatName = "chat ${chatCount + 1}";
    String finalChatName =
        (chatName == null || chatName.trim().isEmpty) ? defaultChatName : chatName.trim();

    DocumentReference chatDocRef = await chatsCollection.add({
      "name": finalChatName,
      "createdAt": Timestamp.now(),
    });
    return chatDocRef.id;
  }

  /// Envía un mensaje a un chat específico.
  Future<void> enviarMissatge(String chatId, String missatge) async {
    try {
      String idUsuariActual = _serveiAuth.getUsuariActual()!.uid;
      String emailUsuariActual = _serveiAuth.getUsuariActual()!.email!;
      Timestamp timestamp = Timestamp.now();

      Map<String, dynamic> nouMissatge = {
        "idAutor": idUsuariActual,
        "emailAutor": emailUsuariActual,
        "missatge": missatge,
        "timestamp": timestamp,
      };

      await _firestore
          .collection("UsersChat")
          .doc(idUsuariActual)
          .collection("Chats")
          .doc(chatId)
          .collection("Missatges")
          .add(nouMissatge);

      print("Missatge enviat correctament!");
    } catch (error) {
      print("Error al enviar el missatge: $error");
    }
  }

  /// Retorna un stream con los mensajes del chat indicado.
  Stream<QuerySnapshot> getMissatges(String chatId) {
    String idUsuariActual = _serveiAuth.getUsuariActual()!.uid;
    return _firestore
        .collection("UsersChat")
        .doc(idUsuariActual)
        .collection("Chats")
        .doc(chatId)
        .collection("Missatges")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  /// Retorna un stream con la lista de chats del usuario.
  Stream<QuerySnapshot> getChats() {
    String idUsuariActual = _serveiAuth.getUsuariActual()!.uid;
    return _firestore
        .collection("UsersChat")
        .doc(idUsuariActual)
        .collection("Chats")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }
}
