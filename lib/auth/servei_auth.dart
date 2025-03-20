import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServeiAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el usuario actualmente autenticado
  User? getUsuariActual() {
    return _auth.currentUser;
  }

  // Hacer logout
  Future<void> ferLogout() async {
    return await _auth.signOut();
  }

  // Hacer login
  Future<String?> loginAmbEmaiIPassword(String email, String password) async {
    try {
      UserCredential credencialUsuari =
          await _auth.signInWithEmailAndPassword(email: email, password: password);

      final QuerySnapshot querySnapshot = await _firestore
          .collection("Usuaris")
          .where("Email", isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _firestore.collection("Usuaris").doc(credencialUsuari.user!.uid).set({
          "uid": credencialUsuari.user!.uid,
          "email": email,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return "Error: ${e.message}";
    }
  }

  // Hacer registro
  Future<String?> resgitreAmbEmaiIPassword(String email, String password) async {
    try {
      UserCredential credencialUsuari = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credencialUsuari.user != null) {
        await _firestore.collection("Usuaris").doc(credencialUsuari.user!.uid).set({
          "uid": credencialUsuari.user!.uid,
          "email": email,
          "nom": "",
        });

        // Crear subcolección "Perfil" con datos iniciales
        await _firestore
            .collection("Usuaris")
            .doc(credencialUsuari.user!.uid)
            .collection("Perfil")
            .doc("DatosPersonales")
            .set({
          "nombre": "",
          "apellidos": "",
          "fechaNacimiento": "",
          "genero": "",
          "situacionLaboral": "",
        });
      } else {
        return "Error: No se pudo obtener el usuario después del registro.";
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "email-already-in-use":
          return "Ya existe un usuario con este correo electrónico.";
        case "invalid-email":
          return "Correo electrónico inválido.";
        case "operation-not-allowed":
          return "La operación no está permitida.";
        case "weak-password":
          return "La contraseña debe ser más robusta.";
        default:
          return "Error: ${e.message}";
      }
    } catch (e) {
      return "Error inesperado: $e";
    }
  }

  // Guardar tarea asociada al usuario actual dentro de TareasUsers
  Future<String?> saveTask({
    required String title,
    required String category,
    required String priority,
    required DateTime date,
    TimeOfDay? time,
  }) async {
    try {
      User? currentUser = getUsuariActual();

      if (currentUser == null) {
        return "No hay usuario autenticado.";
      }

      String? timeString;
      if (time != null) {
        timeString = '${time.hour}:${time.minute}';
      }

      await _firestore
          .collection("TareasUsers")
          .doc(currentUser.uid)
          .collection("Tareas")
          .add({
        "title": title,
        "category": category,
        "priority": priority,
        "date": date,
        "time": timeString ?? "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      print("Error al guardar tarea: $e");
      return "Error al guardar la tarea.";
    }
  }

  // Guardar configuración de notificaciones
  Future<String?> saveNotificationSettings({
    required bool enableNotifications,
    required bool filterByImportance,
    required int minStarLevel,
    required int notificationRepetitions,
    required int daysBeforeDeadline,
    required bool enableCountdownForFiveStars,
    required bool notifyEveryDayBeforeDeadline,
    required TimeOfDay notificationTime,
  }) async {
    try {
      User? currentUser = getUsuariActual();
      if (currentUser == null) {
        return "No hay usuario autenticado.";
      }

      String formattedTime = '${notificationTime.hour}:${notificationTime.minute}';

      await _firestore
          .collection("TareasUsers")
          .doc(currentUser.uid)
          .collection("Notificaciones")
          .doc("Configuracion")
          .set({
        "enableNotifications": enableNotifications,
        "filterByImportance": filterByImportance,
        "minStarLevel": minStarLevel,
        "notificationRepetitions": notificationRepetitions,
        "daysBeforeDeadline": daysBeforeDeadline,
        "enableCountdownForFiveStars": enableCountdownForFiveStars,
        "notifyEveryDayBeforeDeadline": notifyEveryDayBeforeDeadline,
        "notificationTime": formattedTime,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      print("Error al guardar la configuración de notificaciones: $e");
      return "Error al guardar la configuración de notificaciones.";
    }
  }

  // Obtener configuración de notificaciones
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      User? currentUser = getUsuariActual();
      if (currentUser == null) {
        return null;
      }
      DocumentSnapshot snapshot = await _firestore
          .collection("TareasUsers")
          .doc(currentUser.uid)
          .collection("Notificaciones")
          .doc("Configuracion")
          .get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print("Error al cargar la configuración de notificaciones: $e");
      return null;
    }
  }
  Future<String?> updateUserProfile({
    required String email,
    required String nombre,
    required String apellidos,
    required String fechaNacimiento,
    required String genero,
    required String situacionLaboral,
  }) async {
    try {
      User? currentUser = getUsuariActual();
      if (currentUser == null) {
        return "No hay usuario autenticado.";
      }

      await _firestore.collection("Usuaris").doc(currentUser.uid).collection("Perfil").doc("DatosPersonales").set({
        "nombre": nombre,
        "apellidos": apellidos,
        "fechaNacimiento": fechaNacimiento,
        "genero": genero,
        "situacionLaboral": situacionLaboral,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      print("Error al actualizar el perfil del usuario: $e");
      return "Error al actualizar el perfil del usuario.";
    }
  }

}