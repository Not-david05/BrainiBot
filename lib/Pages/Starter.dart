// lib/main.dart
import 'package:flutter/material.dart';
import 'package:brainibot/widgets/task_manager_screen.dart';

class Starter extends StatelessWidget {
  const Starter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskManagerScreen(),
    );
  }
}

void main() {
  runApp(const Starter());
}
