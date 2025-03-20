import 'package:brainibot/Pages/User%20page.dart';
import 'package:brainibot/auth/login_o_registre.dart';
import 'package:brainibot/Pages/FormularioPerfil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PortalAuth extends StatelessWidget {
  const PortalAuth({super.key});

  Future<bool> perfilCompleto(String uid) async {
    // Verificar en Firestore si el perfil está completo
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    
    return userDoc.exists && userDoc['perfilCompleto'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            String uid = snapshot.data!.uid;
            return FutureBuilder<bool>(
              future: perfilCompleto(uid),
              builder: (context, perfilSnapshot) {
                if (perfilSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (perfilSnapshot.data == true) {
                  return User_page();
                } else {
                  return FormularioPerfil(
                    email: snapshot.data!.email!,
                    password: "", // No es necesario aquí, ya está registrado
                  );
                }
              },
            );
          } else {
            return const LoginORegistre();
          }
        },
      ),
    );
  }
}
