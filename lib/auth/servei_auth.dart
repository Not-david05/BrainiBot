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
        // Si el usuario no existe, se crea en Firestore
        await _firestore.collection("Usuaris").doc(credencialUsuari.user!.uid).set({
          "uid": credencialUsuari.user!.uid,
          "email": email,
        }).then((_) {
          print('Usuario registrado en Firestore correctamente');
        }).catchError((e) {
          print('Error al registrar el usuario en Firestore: $e');
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
        }).then((_) {
          print('Perfil creado correctamente en Firestore');
        }).catchError((e) {
          print('Error al crear el perfil: $e');
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

  // Actualizar el perfil del usuario
  Future<String?> updateUserProfile({
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
      print(currentUser.uid);
      // Actualizar datos en Firestore
      await _firestore.collection("Usuaris").doc(currentUser.uid).collection("Perfil").doc("DatosPersonales").set({
        "email": currentUser.email,
        "nombre": nombre,
        "apellidos": apellidos,
        "fechaNacimiento": fechaNacimiento,
        "genero": genero,
        "situacionLaboral": situacionLaboral,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).then((_) {
        print('Perfil actualizado correctamente en Firestore');
      }).catchError((e) {
        print('Error al actualizar el perfil: $e');
      });

      return ("Okay");
    } catch (e, stackTrace) {
      print("Error: $e");
      print("Stacktrace: $stackTrace");
      // Consider returning an error message or rethrowing if appropriate
      return "Error al actualizar el perfil.";
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
        // Podrías retornar un mapa con valores por defecto si no existe configuración
        // o simplemente null como lo haces ahora.
        return null;
      }
    } catch (e) {
      print("Error al cargar la configuración de notificaciones: $e");
      return null;
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

      String formattedTime = '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';

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
      }).then((_) {
        print('Configuración de notificaciones guardada correctamente');
      }).catchError((e) {
        print('Error al guardar la configuración de notificaciones: $e');
         return "Error al guardar la configuración de notificaciones."; // Retornar error
      });

      return null;
    } catch (e) {
      print("Error al guardar la configuración de notificaciones: $e");
      return "Error al guardar la configuración de notificaciones.";
    }
  }

  // Guardar tarea asociada al usuario actual dentro de TareasUsers
  Future<String?> saveTask({
    required String title,
    required String category,
    required String priority,
    required DateTime date,
    TimeOfDay? time,
    String? description, // <--- NUEVO PARÁMETRO
  }) async {
    try {
      User? currentUser = getUsuariActual();

      if (currentUser == null) {
        return "No hay usuario autenticado.";
      }

      String? timeString;
      if (time != null) {
        // Asegurar formato HH:MM
        timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }

      await _firestore
          .collection("TareasUsers")
          .doc(currentUser.uid)
          .collection("Tareas")
          .add({
        "title": title,
        "category": category,
        "priority": priority,
        "date": date, // Firestore guardará esto como un Timestamp
        "time": timeString ?? "",
        "completed": false,
        "description": description ?? "", // <--- NUEVO CAMPO
        "createdAt": FieldValue.serverTimestamp(),
      }).then((_) {
        print('Tarea guardada correctamente');
      }).catchError((e) {
        print('Error al guardar tarea: $e');
        // Es buena práctica propagar el error o manejarlo aquí
        // throw e; // o retornar un mensaje de error específico
        // return "Error interno al guardar tarea."; // Ya está cubierto por el catch general
      });

      return null; // Indica éxito
    } catch (e) {
      print("Error al guardar la tarea: $e");
      return "Error al guardar la tarea.";
    }
  }
}