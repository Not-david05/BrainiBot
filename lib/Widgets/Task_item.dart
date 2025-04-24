import 'package:flutter/material.dart';
import 'package:brainibot/Widgets/task_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskItem extends StatelessWidget {
  final String taskId; // ID del documento en Firestore
  final String title;
  final String category;
  final String priority;
  final int stars;
  final DateTime dueDate;
  final bool completed; // Nuevo campo para el estado de la tarea

  const TaskItem({
    Key? key,
    required this.taskId,
    required this.title,
    required this.category,
    required this.priority,
    required this.stars,
    required this.dueDate,
    required this.completed, // Se añade el parámetro
  }) : super(key: key);

  void _navigateToTaskDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          taskId: taskId,
          title: title,
          category: category,
          priority: priority,
          stars: stars,
          dueDate: dueDate,
        ),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(BuildContext context) async {
    String dialogTitle = completed ? "Marcar como en progreso" : "Marcar como completada";
    String dialogContent = completed
        ? "¿Estás seguro de que deseas marcar esta tarea como en progreso?"
        : "¿Estás seguro de que la tarea está completada?";

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirmar"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore
          .collection("TareasUsers")
          .doc(auth.currentUser?.uid)
          .collection("Tareas")
          .doc(taskId)
          .update({"completed": !completed});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.widgets),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Categoría: $category\nPrioridad: $priority"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.yellow),
            Text(stars.toString()),
            IconButton(
              onPressed: () => _toggleTaskCompletion(context),
              icon: Icon(
                completed ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.green,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToTaskDetail(context),
      ),
    );
  }
}
