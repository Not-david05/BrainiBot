import 'package:brainibot/Firebase/firebase_options.dart';
import 'package:brainibot/Pages/Log%20in.dart';
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/auth/portal_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
 // Archivo generado automáticamente
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PortalAuth(),
    );
  }
}

