import 'package:brainibot/Pages/User%20page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brainibot/auth/login_o_registre.dart';
import 'package:flutter/material.dart';

class PortalAuth extends StatelessWidget {
  const PortalAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context,snapshot){
      
          if(snapshot.hasData){
            return User_page();
          }else{
            return const LoginORegistre();
          }
        },
        ),
    );
  }
}