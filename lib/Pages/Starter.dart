// lib/main.dart // ESTO ES INCORRECTO, Starter no debería ser main.dart
import 'package:flutter/material.dart';
import 'package:brainibot/widgets/task_manager_screen.dart';

class Starter extends StatelessWidget {
  const Starter({super.key});

  @override
  Widget build(BuildContext context) {
    // ESTE MaterialApp está causando el problema
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskManagerScreen(),
    );
  }
}

// ESTA FUNCIÓN main() TAMBIÉN ES PROBLEMÁTICA AQUÍ
void main() {
  runApp(const Starter());
}