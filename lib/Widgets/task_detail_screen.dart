import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/themes/app_colors.dart'; // Importar si se usan colores de marca específicos
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener el paquete intl en pubspec.yaml

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String title;
  final String category;
  final String priority;
  final DateTime dueDate;
  final String description;

  const TaskDetailScreen({ // Añadido const
    Key? key, // Añadido Key
    required this.taskId,
    required this.title,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.description,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _priorityController;
  late TextEditingController _dateController;
  late TextEditingController _descriptionController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _categories = [
    'Estudios', 'Diaria', 'Recados', 'Trabajo', 'Personal', 'Otros'
  ];
  final List<String> _priorities = [
    'Urgente 5★', 'Alta 4★', 'Media 3★', 'Baja 2★', 'Opcional 1★'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _categoryController = TextEditingController(text: widget.category);
    _priorityController = TextEditingController(text: widget.priority);
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(widget.dueDate), // Añadir locale si es necesario
    );
    _descriptionController = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _priorityController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateTask(String field, dynamic newValue) async {
    final theme = Theme.of(context); // Para SnackBar
    try {
      var currentUser = ServeiAuth().getUsuariActual();
      if (currentUser == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Usuario no autenticado."), backgroundColor: theme.colorScheme.error));
        return;
      }

      var userDoc = _firestore.collection("TareasUsers").doc(currentUser.uid);

      // El campo en Firestore para la fecha se llama 'date'
      // y se espera un Timestamp.
      if (field == 'date' && newValue is DateTime) {
        await userDoc.collection("Tareas").doc(widget.taskId).update({
          'date': Timestamp.fromDate(newValue),
        });
      } else {
        await userDoc.collection("Tareas").doc(widget.taskId).update({
          field: newValue,
        });
      }
      if (mounted) {
        // Opcional: Mostrar un SnackBar de éxito brevemente
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${field.capitalize()} actualizado."), duration: Duration(seconds: 1), backgroundColor: theme.colorScheme.primary,));
      }
    } catch (error) {
      print("Error al actualizar la tarea: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: ${error.toString()}"), backgroundColor: theme.colorScheme.error),
        );
      }
    }
  }

  void _editDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onSave,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          // Estilos del AlertDialog tomados del tema
          title: Text(title),
          content: content,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"), // Estilo del TextButton del tema
            ),
            TextButton(
              onPressed: () {
                onSave();
                Navigator.pop(dialogContext);
              },
              child: const Text("Guardar"), // Estilo del TextButton del tema
            ),
          ],
        );
      },
    );
  }

  void _editCategory() {
    String selectedValue = _categoryController.text;
    _editDialog(
      context: context,
      title: "Editar Categoría",
      content: StatefulBuilder( // Necesario para que el Dropdown se actualice dentro del diálogo
        builder: (BuildContext context, StateSetter setStateDialog) {
          return DropdownButton<String>(
            value: _categories.contains(selectedValue) ? selectedValue : null, // Asegurar que el valor esté en la lista
            hint: const Text("Selecciona una categoría"), // Hint si el valor no está en la lista
            isExpanded: true,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setStateDialog(() => selectedValue = newValue);
              }
            },
            items: _categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            // Estilos del Dropdown (texto, color del menú) se toman del tema
            dropdownColor: Theme.of(context).cardTheme.color, // Color de fondo del menú desplegable
          );
        },
      ),
      onSave: () {
        if (mounted) {
          setState(() => _categoryController.text = selectedValue);
        }
        _updateTask('category', selectedValue);
      },
    );
  }

  void _editPriority() {
    String selectedValue = _priorityController.text;
    _editDialog(
      context: context,
      title: "Editar Prioridad",
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) {
          return DropdownButton<String>(
            value: _priorities.contains(selectedValue) ? selectedValue : null,
            hint: const Text("Selecciona una prioridad"),
            isExpanded: true,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setStateDialog(() => selectedValue = newValue);
              }
            },
            items: _priorities.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            dropdownColor: Theme.of(context).cardTheme.color,
          );
        },
      ),
      onSave: () {
        if (mounted) {
          setState(() => _priorityController.text = selectedValue);
        }
        _updateTask('priority', selectedValue);
      },
    );
  }

  void _editDueDate() async {
    DateTime initialDateTime = widget.dueDate;
    try {
      initialDateTime = DateFormat('dd/MM/yyyy HH:mm', 'es_ES').parse(_dateController.text);
    } catch (e) {
      print("Error parseando fecha del controlador, usando fecha original: $e");
    }

    // DatePicker y TimePicker usarán el tema global
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null || !mounted) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (pickedTime == null || !mounted) return;

    DateTime newDateTime = DateTime(
      pickedDate.year, pickedDate.month, pickedDate.day,
      pickedTime.hour, pickedTime.minute,
    );

    if (mounted) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(newDateTime);
      });
    }
    await _updateTask('date', newDateTime); // 'date' es el nombre del campo en Firestore
  }
  
  void _editTitle() {
    final tempTitleController = TextEditingController(text: _titleController.text);
    _editDialog(
      context: context,
      title: "Editar Título",
      content: TextField(
        controller: tempTitleController,
        decoration: const InputDecoration(border: OutlineInputBorder()), // Usará inputDecorationTheme
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
      ),
      onSave: () {
        if (mounted) {
          setState(() => _titleController.text = tempTitleController.text);
        }
        _updateTask('title', _titleController.text);
      },
    );
  }

  void _editDescription() {
    final tempDescriptionController = TextEditingController(text: _descriptionController.text);
    _editDialog(
      context: context,
      title: "Editar Descripción",
      content: TextField(
        controller: tempDescriptionController,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          border: OutlineInputBorder(), // Usará inputDecorationTheme
          hintText: "Añade una descripción detallada...",
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
      ),
      onSave: () {
        if (mounted) {
          setState(() => _descriptionController.text = tempDescriptionController.text);
        }
        _updateTask('description', _descriptionController.text);
      },
    );
  }

  void _deleteTask() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("¿Eliminar tarea?"),
          content: const Text("Esta acción no se puede deshacer."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Cerrar diálogo antes de la operación asíncrona
                try {
                  var currentUser = ServeiAuth().getUsuariActual();
                  if (currentUser == null) {
                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Usuario no autenticado."), backgroundColor: theme.colorScheme.error));
                    return;
                  }

                  await _firestore
                      .collection("TareasUsers")
                      .doc(currentUser.uid)
                      .collection("Tareas")
                      .doc(widget.taskId)
                      .delete();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Tarea eliminada."), backgroundColor: theme.colorScheme.primary,));
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Starter()), // Añadido const
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (error) {
                  print("Error al eliminar: $error");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al eliminar: ${error.toString()}"), backgroundColor: theme.colorScheme.error),
                    );
                  }
                }
              },
              child: Text("Eliminar", style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determinar colores del AppBar según el tema
    final bool isLightTheme = theme.brightness == Brightness.light;
    final appBarBackgroundColor = isLightTheme ? AppColors.lightUserPageAppBarBg : theme.appBarTheme.backgroundColor;
    final appBarForegroundColor = isLightTheme ? AppColors.lightUserPagePrimaryText : theme.appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Color de fondo del tema
      appBar: AppBar(
        toolbarHeight: 100, // Mantener si es diseño específico
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        iconTheme: IconThemeData(color: appBarForegroundColor),
        title: Text(
          "Detalles de la tarea",
          style: theme.appBarTheme.titleTextStyle?.copyWith(color: appBarForegroundColor),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0), // Ajustado padding
            child: IconButton(
              icon: Icon(Icons.delete_forever_outlined, color: colorScheme.error, size: 28), // Icono y color del tema
              tooltip: "Eliminar Tarea",
              onPressed: _deleteTask,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container( // Contenedor de placeholder de imagen
              height: 150,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant, // Color de fondo del tema
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(Icons.task_alt_outlined, size: 80, color: colorScheme.onSurfaceVariant)), // Icono y color del tema
            ),
            const SizedBox(height: 24),
            Card(
              // elevation, shape, color se toman de theme.cardTheme
              child: Column(
                children: [
                  _buildDetailTile(context, Icons.title_rounded, "Título", _titleController, _editTitle),
                  Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor),
                  _buildDetailTile(context, Icons.description_outlined, "Descripción", _descriptionController, _editDescription),
                  Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor),
                  _buildDetailTile(context, Icons.category_outlined, "Categoría", _categoryController, _editCategory),
                  Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor),
                  _buildDetailTile(context, Icons.flag_outlined, "Prioridad", _priorityController, _editPriority),
                  Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor),
                  _buildDetailTile(context, Icons.calendar_month_outlined, "Fecha y hora", _dateController, _editDueDate),
                ],
              ),
            ),
            const SizedBox(height: 20), // Espacio al final
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, // Pasar contexto para el tema
    IconData icon,
    String label,
    TextEditingController controller,
    VoidCallback onEdit,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary), // Usar color primario del tema
      title: Text(label, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)), // Estilo del tema
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          controller.text.isEmpty && label == "Descripción" ? 'Sin descripción' : controller.text,
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface), // Estilo del tema
          maxLines: label == "Descripción" ? 3 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.edit_note_outlined, color: colorScheme.secondary), // Usar color secundario del tema
        tooltip: "Editar $label",
        onPressed: onEdit,
      ),
      onTap: onEdit,
    );
  }
}