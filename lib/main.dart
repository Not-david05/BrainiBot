import 'package:brainibot/Firebase/firebase_options.dart';
import 'package:brainibot/Pages/Log in.dart';
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/auth/portal_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es', null);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ahora sí comprobamos Firestore, no Storage
    print('>>> Firestore projectId = ${FirebaseFirestore.instance.app.options.projectId}');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PortalAuth(),
    );
  }
}