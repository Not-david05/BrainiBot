import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  final String title;
  final String category;
  final String priority;
  final int stars;

  TaskItem({required this.title, required this.category, required this.priority, required this.stars});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar eliminación"),
          content: Text("¿Deseas eliminar esta tarea?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
