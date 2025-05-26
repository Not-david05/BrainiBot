// Updated PortalAuth and FormularioPerfil fixes
// Main fix: PortalAuth now correctly handles Timestamp and String for fechaNacimiento

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brainibot/Pages/User page.dart';
import 'package:brainibot/auth/login_o_registre.dart';
import 'package:brainibot/Pages/FormularioPerfil.dart';

class PortalAuth extends StatelessWidget {
  const PortalAuth({Key? key}) : super(key: key);

  Future<bool> camposObligatoriosCompletos(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Usuaris')
          .doc(uid)
          .collection('Perfil')
          .doc('DatosPersonales')
          .get();
      if (!doc.exists) return false;
      final data = doc.data()!;

      String nombre = data['nombre'] as String? ?? '';
      String apellidos = data['apellidos'] as String? ?? '';
      var fechaRaw = data['fechaNacimiento'];
      String situacion = data['situacionLaboral'] as String? ?? '';

      bool fechaValida = false;
      if (fechaRaw is String && fechaRaw.isNotEmpty) {
        fechaValida = true;
      } else if (fechaRaw is Timestamp) {
        fechaValida = true;
      }

      return nombre.isNotEmpty &&
             apellidos.isNotEmpty &&
             fechaValida &&
             situacion.isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar campos obligatorios: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.hasData) {
            final uid = authSnap.data!.uid;
            return FutureBuilder<bool>(
              future: camposObligatoriosCompletos(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.data == true) {
                  return const DashboardScreen();
                }
                return FormularioPerfil(email: authSnap.data!.email!);
              },
            );
          }
          return const LoginORegistre();
        },
      ),
    );
  }
}
