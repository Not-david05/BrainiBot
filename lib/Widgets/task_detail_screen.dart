import 'package:flutter/material.dart';

class TaskDetailScreen extends StatefulWidget {
  final String title;
  final String category;
  final String priority;
  final int stars;
  final DateTime dueDate;

  TaskDetailScreen({
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

  void _editField(BuildContext context, String label, TextEditingController controller) {
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
              onPressed: () {}, // Implementar lógica de eliminación
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
                  _buildDetailTile(Icons.title, "Título", _titleController),
                  _buildDetailTile(Icons.category, "Categoría", _categoryController),
                  _buildDetailTile(Icons.flag, "Prioridad", _priorityController),
                  _buildDetailTile(Icons.star, "Estrellas", _starsController),
                  _buildDetailTile(Icons.calendar_today, "Fecha de vencimiento", _dateController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, TextEditingController controller) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(controller.text, style: TextStyle(fontSize: 16)),
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue),
        onPressed: () => _editField(context, label, controller),
      ),
    );
  }
}
