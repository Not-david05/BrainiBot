import 'package:brainibot/Pages/User%20page.dart';
import 'package:brainibot/auth/login_o_registre.dart';
import 'package:brainibot/Pages/FormularioPerfil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PortalAuth extends StatelessWidget {
  const PortalAuth({super.key});

  // Verificar si los campos obligatorios están completos
  Future<bool> camposObligatoriosCompletos(String uid) async {
    try {
      // Accedemos a la subcolección "Perfil" para obtener los datos personales
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Usuaris')  // Colección de usuarios
          .doc(uid)  // Documento del usuario
          .collection("Perfil")  // Subcolección "Perfil"
          .doc("DatosPersonales")  // Documento donde están los datos del perfil
          .get();

      // Verifica si el documento existe y contiene los campos obligatorios
      if (userDoc.exists) {
        String? nombre = userDoc['nombre'];
        String? apellidos = userDoc['apellidos'];
        String? fechaNacimiento = userDoc['fechaNacimiento'];
        String? genero = userDoc['genero'];
        String? situacionLaboral = userDoc['situacionLaboral'];

        // Si algún campo obligatorio está vacío, devuelve false
        return nombre != null && nombre.isNotEmpty &&
               apellidos != null && apellidos.isNotEmpty &&
               fechaNacimiento != null && fechaNacimiento.isNotEmpty &&
               genero != null && genero.isNotEmpty &&
               situacionLaboral != null && situacionLaboral.isNotEmpty;
      }
      return false;  // Si el documento no existe o no tiene los campos necesarios
    } catch (e) {
      print('Error al verificar los campos obligatorios: $e');
      return false;  // Si ocurre un error, consideramos que los campos no están completos
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            String uid = snapshot.data!.uid;  // Obtener el UID del usuario autenticado
            return FutureBuilder<bool>(
              future: camposObligatoriosCompletos(uid),  // Verificar si los campos obligatorios están completos
              builder: (context, camposSnapshot) {
                if (camposSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (camposSnapshot.data == true) {
                  return DashboardScreen();  // El perfil está completo, redirige a la página principal
                } else {
                  return FormularioPerfil(
                    email: snapshot.data!.email!,
                    
                  );  // Redirige al formulario de perfil si faltan campos obligatorios
                }
              },
            );
          } else {
            return const LoginORegistre();  // Usuario no autenticado, redirige a login
          }
        },
      ),
    );
  }
}
