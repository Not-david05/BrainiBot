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
      UserCredential credencialUsuari = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // Verificar si el usuario ya está registrado en Firestore
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

      // Verificar si el usuario no es nulo
      if (credencialUsuari.user != null) {
        print("Usuario creado con éxito: ${credencialUsuari.user!.uid}");
        await _firestore.collection("Usuaris").doc(credencialUsuari.user!.uid).set({
          "uid": credencialUsuari.user!.uid,
          "email": email,
          "nom": "",
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

  // Guardar tarea asociada al usuario actual
  Future<String?> saveTask({
    required String title,
    required String category,
    required String priority,
    required DateTime date,
    TimeOfDay? time,
  }) async {
    try {
      // Obtenemos el usuario actual
      User? currentUser = getUsuariActual();

      if (currentUser == null) {
        return "No hay usuario autenticado.";
      }

      // Convertir la hora en formato de 24 horas si se ha seleccionado una
      String? timeString;
      if (time != null) {
        timeString = '${time.hour}:${time.minute}';
      }

      // Crear la tarea en Firestore
      await _firestore.collection("Tareas").add({
        "uid": currentUser.uid,  // Asociamos la tarea al UID del usuario
        "title": title,
        "category": category,
        "priority": priority,
        "date": date,
        "time": timeString ?? "",  // La hora es opcional
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null;  // Si la tarea se guarda correctamente, retornamos null
    } catch (e) {
      print("Error al guardar tarea: $e");
      return "Error al guardar la tarea.";
    }
  }
}
