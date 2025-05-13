import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brainibot/auth/servei_auth.dart';

class ServeiAdmin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ServeiAuth _serveiAuth = ServeiAuth();

  /// Crea un nuevo usuario admin. 
  /// Si [adminName] es nulo o está vacío, se asigna el nombre "admin X" de forma predeterminada.
  Future<String> createAdmin(String? adminName) async {
    // Obtenemos el usuario actual, en caso de querer asociar el admin con el usuario autenticado.
    String currentUserId = _serveiAuth.getUsuariActual()!.uid;
    CollectionReference adminCollection = _firestore.collection("Admins");

    // Contar los admins existentes para asignar el nombre por defecto
    QuerySnapshot querySnapshot = await adminCollection.get();
    int adminCount = querySnapshot.docs.length;
    String defaultAdminName = "admin ${adminCount + 1}";
    String finalAdminName = (adminName == null || adminName.trim().isEmpty)
        ? defaultAdminName
        : adminName.trim();

    // Creamos el documento en la colección "Admins"
    DocumentReference adminDocRef = await adminCollection.add({
      "name": finalAdminName,
      "createdAt": Timestamp.now(),
      "role": "admin",
      // Puedes incluir más campos según tus necesidades (por ejemplo, email, permisos, etc.)
    });
    return adminDocRef.id;
  }

  /// Retorna un stream con la lista de usuarios admin.
  Stream<QuerySnapshot> getAdmins() {
    return _firestore
        .collection("Admins")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }

  /// Elimina un usuario admin de forma permanente.
  Future<void> deleteAdmin(String adminId) async {
    try {
      await _firestore.collection("Admins").doc(adminId).delete();
      print("Usuario admin eliminado correctamente.");
    } catch (e) {
      print("Error al eliminar el usuario admin: $e");
    }
  }

  /// Verifica si el usuario actual tiene privilegios de admin.
  Future<bool> isAdmin() async {
    String currentUserId = _serveiAuth.getUsuariActual()!.uid;
    DocumentSnapshot adminDoc =
        await _firestore.collection("Admins").doc(currentUserId).get();
    return adminDoc.exists;
  }
}
