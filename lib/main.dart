
import 'package:brainibot/Firebase/firebase_options.dart';
import 'package:brainibot/Pages/Log in.dart';
import 'package:brainibot/auth/portal_auth.dart';
import 'package:brainibot/state/theme_provider.dart';         // ← tu provider
import 'package:brainibot/themes/app_themes.dart';            // ← tus temas
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';                     // ← provider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Para depurar:
    print('>>> Firestore projectId = ${FirebaseFirestore.instance.app.options.projectId}');

    // Obtenemos el estado del tema
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BrainiBot',
      theme: AppThemes.lightThemeUserPage,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProv.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const PortalAuth(),  // tu entry point
    );
  }
}
