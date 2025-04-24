import 'package:brainibot/Firebase/firebase_options.dart';
import 'package:brainibot/Pages/Log%20in.dart';
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/auth/portal_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importa la librería para la inicialización de locales

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Inicializa la configuración regional para español
  await initializeDateFormatting('es', null);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('>>> Firestore projectId = ${FirebaseStorage.instance.app.options.projectId}');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PortalAuth(),
    );
  }
}
