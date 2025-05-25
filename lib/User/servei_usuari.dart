// lib/serveis/servei_usuari.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Para TimeOfDay

class ServeiUsuari {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getUsuariActual() {
    return _auth.currentUser;
  }

  // --- GESTIÓN DE PERFIL Y USUARIOS ---

  Future<void> updateLastSeen() async {
    final currentUser = getUsuariActual();
    if (currentUser != null) {
      try {
        await _firestore.collection('Usuaris').doc(currentUser.uid).set({
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error actualizando lastSeen: $e");
      }
    }
  }

  Stream<QuerySnapshot> getLlistaUsuarisStream() {
    // Excluir al usuario actual de la lista
    String? currentUserId = getUsuariActual()?.uid;
    if (currentUserId == null) return Stream.empty(); // No hay usuario logueado

    return _firestore
        .collection('Usuaris')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId) // Excluir al usuario actual
        .orderBy(FieldPath.documentId) // Necesario para combinar con isNotEqualTo
        .snapshots();
  }

  Future<Map<String, dynamic>?> getDadesUsuari(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Usuaris').doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error obteniendo datos de usuario $userId: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPerfilUsuari(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Usuaris')
          .doc(userId)
          .collection('Perfil')
          .doc('DatosPersonales')
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error obteniendo perfil de usuario $userId: $e");
      return null;
    }
  }

  // --- GESTIÓN DE AMISTADES ---

  // Helper para generar ID de documento de amistad consistente
  String _getFriendshipDocId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<String?> sendFriendRequest(String receiverId) async {
    final currentUser = getUsuariActual();
    if (currentUser == null) return "Usuario no autenticado.";
    if (currentUser.uid == receiverId) return "No puedes agregarte a ti mismo.";

    final friendshipId = _getFriendshipDocId(currentUser.uid, receiverId);

    try {
      // Verificar si ya existe una solicitud o amistad
      DocumentSnapshot friendshipDoc =
          await _firestore.collection('Amistats').doc(friendshipId).get();
      if (friendshipDoc.exists) {
        final data = friendshipDoc.data() as Map<String, dynamic>;
        if (data['status'] == 'accepted') return "Ya sois amigos.";
        if (data['status'] == 'pending' && data['requesterId'] == currentUser.uid) return "Solicitud ya enviada.";
        if (data['status'] == 'pending' && data['requesterId'] == receiverId) return "Tienes una solicitud pendiente de este usuario.";
      }
      
      await _firestore.collection('Amistats').doc(friendshipId).set({
        'users': [currentUser.uid, receiverId],
        'requesterId': currentUser.uid,
        'receiverId': receiverId,
        'status': 'pending', // pending, accepted, declined, blocked
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null; // Éxito
    } catch (e) {
      print("Error enviando solicitud de amistad: $e");
      return "Error al enviar solicitud.";
    }
  }

  Future<String?> acceptFriendRequest(String requesterId) async {
    final currentUser = getUsuariActual();
    if (currentUser == null) return "Usuario no autenticado.";

    final friendshipId = _getFriendshipDocId(currentUser.uid, requesterId);
    try {
      await _firestore.collection('Amistats').doc(friendshipId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      print("Error aceptando solicitud de amistad: $e");
      return "Error al aceptar solicitud.";
    }
  }

  Future<String?> declineFriendRequest(String otherUserId) async {
    final currentUser = getUsuariActual();
    if (currentUser == null) return "Usuario no autenticado.";

    final friendshipId = _getFriendshipDocId(currentUser.uid, otherUserId);
    try {
      // Podríamos eliminar el documento o marcarlo como 'declined'
      // Eliminar es más simple si no se necesita historial de declinaciones.
      await _firestore.collection('Amistats').doc(friendshipId).delete();
      return null;
    } catch (e) {
      print("Error rechazando solicitud de amistad: $e");
      return "Error al rechazar solicitud.";
    }
  }
  
  Future<String?> removeFriend(String friendId) async {
    final currentUser = getUsuariActual();
    if (currentUser == null) return "Usuario no autenticado.";

    final friendshipId = _getFriendshipDocId(currentUser.uid, friendId);
    try {
      await _firestore.collection('Amistats').doc(friendshipId).delete();
      // Opcional: Eliminar el chat asociado
      // final chatId = _getChatDocId(currentUser.uid, friendId);
      // await _firestore.collection('XatsEntreUsuaris').doc(chatId).delete(); // Más complejo por subcolección de mensajes
      return null;
    } catch (e) {
      print("Error eliminando amigo: $e");
      return "Error al eliminar amigo.";
    }
  }

  Stream<DocumentSnapshot> getFriendshipStatusStream(String otherUserId) {
    final currentUser = getUsuariActual();
    if (currentUser == null) return Stream.empty();
    final friendshipId = _getFriendshipDocId(currentUser.uid, otherUserId);
    return _firestore.collection('Amistats').doc(friendshipId).snapshots();
  }

  Stream<QuerySnapshot> getFriendsStream() {
    final currentUser = getUsuariActual();
    if (currentUser == null) return Stream.empty();
    return _firestore
        .collection('Amistats')
        .where('users', arrayContains: currentUser.uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  Stream<QuerySnapshot> getPendingFriendRequestsStream() {
     final currentUser = getUsuariActual();
    if (currentUser == null) return Stream.empty();
    return _firestore
        .collection('Amistats')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }


  // --- GESTIÓN DE CHATS 1-A-1 ---

  // Helper para ID de chat
  String _getChatDocId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<String> getOrCreateChatWithUser(String otherUserId) async {
    final currentUser = getUsuariActual();
    if (currentUser == null) throw Exception("Usuario no autenticado");

    final chatId = _getChatDocId(currentUser.uid, otherUserId);
    final chatDocRef = _firestore.collection('XatsEntreUsuaris').doc(chatId);

    final doc = await chatDocRef.get();
    if (!doc.exists) {
      // Obtener nombres de usuario para el chat (opcional, pero útil para la lista de chats)
      final currentUserData = await getDadesUsuari(currentUser.uid);
      final otherUserData = await getDadesUsuari(otherUserId);
      
      await chatDocRef.set({
        'participants': [currentUser.uid, otherUserId],
        'participantNames': { // Podría ser útil para mostrar nombres en la lista de chats
          currentUser.uid: currentUserData?['nom'] ?? currentUserData?['email'] ?? 'Usuario 1',
          otherUserId: otherUserData?['nom'] ?? otherUserData?['email'] ?? 'Usuario 2',
        },
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  Stream<QuerySnapshot> getXatsStream() {
    final currentUser = getUsuariActual();
    if (currentUser == null) return Stream.empty();
    return _firestore
        .collection('XatsEntreUsuaris')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMissatgesXatStream(String chatId) {
    return _firestore
        .collection('XatsEntreUsuaris')
        .doc(chatId)
        .collection('Missatges')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<String?> enviarMissatgeXat(String chatId, String messageText, String receiverId) async {
    final currentUser = getUsuariActual();
    if (currentUser == null) return "Usuario no autenticado.";
    if (messageText.trim().isEmpty) return "El mensaje no puede estar vacío.";

    try {
      await _firestore
          .collection('XatsEntreUsuaris')
          .doc(chatId)
          .collection('Missatges')
          .add({
        'idAutor': currentUser.uid,
        'missatge': messageText.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        // 'readBy': [currentUser.uid] // Opcional para marcas de leído
      });

      // Actualizar lastMessage en el documento principal del chat
      await _firestore.collection('XatsEntreUsuaris').doc(chatId).update({
        'lastMessage': messageText.trim(),
        'lastMessageSenderId': currentUser.uid,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      return null; // Éxito
    } catch (e) {
      print("Error enviando mensaje de chat: $e");
      return "Error al enviar mensaje.";
    }
  }
}