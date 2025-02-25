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

  void _deleteTask() {
    // Aquí puedes implementar la lógica para eliminar la tarea, 
    // como eliminarla de la base de datos, o de una lista, etc.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Eliminar tarea"),
          content: Text("¿Estás seguro de que deseas eliminar esta tarea?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Aquí puedes agregar el código para realizar la eliminación.
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tarea eliminada')));
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.purple[100],
        title: Text("Detalles de la tarea"),
        actions: [
          // Botón de eliminar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: IconButton(
                icon: Icon(Icons.delete, color: const Color.fromARGB(255, 216, 21, 7),size: 50,),
                onPressed: _deleteTask,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen o icono de la tarea
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(Icons.image, size: 100, color: Colors.grey[600])),
            ),
            SizedBox(height: 20),

            // Tarjeta con los detalles de la tarea
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildDetailTile(Icons.title, "Título", widget.title),
                    _buildDetailTile(Icons.category, "Categoría", widget.category),
                    _buildDetailTile(Icons.flag, "Prioridad", widget.priority),
                    _buildDetailTile(Icons.star, "Estrellas", widget.stars.toString()),
                    _buildDetailTile(Icons.calendar_today, "Fecha de vencimiento",
                        "${widget.dueDate.day}/${widget.dueDate.month}/${widget.dueDate.year}"),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Editar detalles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            _buildEditableField("Título", _titleController),
            _buildEditableField("Categoría", _categoryController),
            _buildEditableField("Prioridad", _priorityController),
            _buildEditableField("Estrellas", _starsController),
            _buildEditableField("Fecha de vencimiento", _dateController),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar detalles en formato ListTile
  Widget _buildDetailTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 16)),
    );
  }

  // Widget para editar detalles de la tarea
  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              _editField(context, label, controller);
            },
          ),
        ],
      ),
    );
  }

  // Función para editar un campo
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
                setState(() {}); // Refrescar pantalla
                Navigator.pop(context);
              },
              child: Text("Guardar", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
