import 'package:brainibot/chat/missatge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brainibot/auth/servei_auth.dart'; // Import the ServeiAuth class

class ServeiChat {
  final ServeiAuth _serveiAuth = ServeiAuth(); // Use ServeiAuth for authentication
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message (private to the user)
  Future<void> enviarMissatge(String missatge) async {
    try {
      // Get the current user's ID and email from ServeiAuth
      String idUsuariActual = _serveiAuth.getUsuariActual()!.uid;
      String emailUsuariActual = _serveiAuth.getUsuariActual()!.email!;
      Timestamp timestamp = Timestamp.now();

      // Create a new message object
      Missatge nouMissatge = Missatge(
        idAutor: idUsuariActual,
        emailAutor: emailUsuariActual,
        idReceptor: "AI", // Indicate that the message is for the AI
        missatge: missatge,
        timestamp: timestamp,
      );

      // Save the message in the user's private subcollection
      await _firestore
          .collection("UsersChat")
          .doc(idUsuariActual)
          .collection("Missatges")
          .add(nouMissatge.retornaMapaMissatge());

      print("Missatge enviat correctament!");
    } catch (error) {
      print("Error al enviar el missatge: $error");
    }
  }

  // Get messages (private to the user)
  Stream<QuerySnapshot> getMissatges() {
  // Get the current user's ID
  String idUsuariActual = _serveiAuth.getUsuariActual()!.uid;

  // Return a stream of messages from the user's private subcollection
  return _firestore
      .collection("UsersChat")
      .doc(idUsuariActual)
      .collection("Missatges")
      .orderBy("timestamp", descending: false)
      .snapshots();
}
}