import 'package:brainibot/Pages/Starter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String title;
  final String category;
  final String priority;
  final int stars;
  final DateTime dueDate;

  TaskDetailScreen({
    required this.taskId,
    required this.title,
    required this.category,
    required this.priority,
    required this.stars,
    required this.dueDate,
  });

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _priorityController;
  late TextEditingController _starsController;
  late TextEditingController _dateController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _categoryController = TextEditingController(text: widget.category);
    _priorityController = TextEditingController(text: widget.priority);
    _starsController = TextEditingController(text: widget.stars.toString());
    _dateController = TextEditingController(
      text: "${widget.dueDate.day}/${widget.dueDate.month}/${widget.dueDate.year}",
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _priorityController.dispose();
    _starsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

 Future<void> _updateTask(String field, String newValue) async {
  try {
    // Fetch the document from the "Tareas" collection
    var doc = await _firestore.collection('Tareas').doc(widget.taskId).get();
    
    if (doc.exists) {
      print("Document exists, updating field: $field to $newValue");
      await _firestore.collection('Tareas').doc(widget.taskId).update({field: newValue});
      print("Task updated successfully!");
    } else {
      print("Document with ID ${widget.taskId} does not exist in 'Tareas' collection.");
    }
  } catch (error) {
    print("Error fetching or updating document: $error");
  }
}


  void _editField(BuildContext context, String label, TextEditingController controller, String field) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar $label"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
            TextButton(
              onPressed: () {
                _updateTask(field, controller.text);
                setState(() {});
                Navigator.pop(context);
              },
              child: Text("Guardar", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("¿Estás seguro de que deseas eliminar esta tarea?"),
        content: Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
            },
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Borra la tarea de Firestore
                await _firestore.collection('Tareas').doc(widget.taskId).delete();
                
                // Salir de la pantalla de detalles de la tarea (volvemos atrás)
                Navigator.pop(context); // Cierra el diálogo
                Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Starter(),
                          ),
                        );// Vuelve atrás a la lista de tareas
                print("Tarea eliminada exitosamente!");
              } catch (error) {
                print("Error al eliminar la tarea: $error");
              }
            },
            child: Text("Sí, eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.purple[100],
        title: Text("Detalles de la tarea"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: _deleteTask,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(Icons.image, size: 100, color: Colors.grey[600])),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  _buildDetailTile(Icons.title, "Título", _titleController, "title"),
                  _buildDetailTile(Icons.category, "Categoría", _categoryController, "category"),
                  _buildDetailTile(Icons.flag, "Prioridad", _priorityController, "priority"),
                  _buildDetailTile(Icons.star, "Estrellas", _starsController, "stars"),
                  _buildDetailTile(Icons.calendar_today, "Fecha de vencimiento", _dateController, "dueDate"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, TextEditingController controller, String field) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(controller.text, style: TextStyle(fontSize: 16)),
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue),
        onPressed: () => _editField(context, label, controller, field),
      ),
    );
  }
}
