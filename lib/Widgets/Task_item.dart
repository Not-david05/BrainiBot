import 'package:flutter/material.dart';
import 'package:brainibot/Widgets/task_detail_screen.dart';

class TaskItem extends StatelessWidget {
  final String taskId; // Asegúrate de incluir esto
  final String title;
  final String category;
  final String priority;
  final int stars;
  final DateTime dueDate;

  TaskItem({
    required this.taskId, // Ahora pasamos el taskId
    required this.title,
    required this.category,
    required this.priority,
    required this.stars,
    required this.dueDate,
  });

  void _navigateToTaskDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          taskId: taskId, // Pasa el taskId correctamente
          title: title,
          category: category,
          priority: priority,
          stars: stars,
          dueDate: dueDate,
        ),
      ),
    );
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
          ],
        ),
        onTap: () => _navigateToTaskDetail(context),
      ),
    );
  }
}
