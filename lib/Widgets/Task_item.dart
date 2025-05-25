import 'package:brainibot/themes/app_colors.dart'; // Asegúrate que AppColors está importado si lo necesitas para algo no temático
import 'package:flutter/material.dart';
import 'package:brainibot/Widgets/task_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart'; // Si necesitas formatear fechas más complejas, aunque aquí es simple

class TaskItem extends StatelessWidget {
  final String taskId;
  final String title;
  final String category;
  final String priority;
  final int stars;
  final DateTime dueDate;
  final bool completed;
  final String? description;

  const TaskItem({
    Key? key,
    required this.taskId,
    required this.title,
    required this.category,
    required this.priority,
    required this.stars,
    required this.dueDate,
    required this.completed,
    this.description,
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
          dueDate: dueDate,
          description: description ?? '', // Mantener el fallback
        ),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String dialogTitle = completed ? "Marcar como pendiente" : "Marcar como completada";
    String dialogContent = completed
        ? "¿Estás seguro de que deseas marcar esta tarea como pendiente?"
        : "¿Estás seguro de que deseas marcar esta tarea como completada?";

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        // backgroundColor se toma de theme.dialogTheme.backgroundColor o colorScheme.surface
        // backgroundColor: Colors.blueGrey[800], // Eliminado
        title: Text(dialogTitle, style: theme.dialogTheme.titleTextStyle ?? textTheme.titleLarge),
        content: Text(dialogContent, style: theme.dialogTheme.contentTextStyle ?? textTheme.bodyMedium),
        shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            // El estilo del TextButton se toma de theme.textButtonTheme
            child: const Text("Cancelar"), // El color del texto se toma del tema
          ),
          TextButton(
            // El estilo del TextButton se toma de theme.textButtonTheme
            // Si se quiere un botón más prominente, podría ser un ElevatedButton
            // style: TextButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary), // Ejemplo de estilo personalizado si el del tema no es suficiente
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          if (context.mounted) { // Comprobar si el widget está montado antes de mostrar SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Error: Usuario no autenticado."),
                backgroundColor: colorScheme.error, // Usar color de error del tema
                behavior: SnackBarBehavior.floating, // Opcional: para mejor apariencia
              ),
            );
          }
          return;
        }
        await FirebaseFirestore.instance
            .collection("TareasUsers")
            .doc(currentUser.uid)
            .collection("Tareas")
            .doc(taskId)
            .update({"completed": !completed, "updatedAt": FieldValue.serverTimestamp()});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(completed ? "Tarea marcada como pendiente." : "Tarea marcada como completada."),
              // backgroundColor: Colors.green, // Reemplazar con un color del tema si se desea
              backgroundColor: colorScheme.primary, // Ejemplo: usar color primario para feedback positivo
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al actualizar la tarea: $e"),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // --- INICIO DE SECCIÓN NO MODIFICADA POR SOLICITUD ---
  Color _getPriorityColor(String priority) {
    if (priority.contains('Urgente') || priority.contains('5★')) return Colors.red.shade400;
    if (priority.contains('Alta') || priority.contains('4★')) return Colors.orange.shade400;
    if (priority.contains('Media') || priority.contains('3★')) return Colors.yellow.shade600;
    if (priority.contains('Baja') || priority.contains('2★')) return Colors.blue.shade300;
    if (priority.contains('Opcional') || priority.contains('1★')) return Colors.green.shade300;
    return Colors.grey.shade400;
  }
  // --- FIN DE SECCIÓN NO MODIFICADA POR SOLICITUD ---

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'estudios': return Icons.school;
      case 'diaria': return Icons.calendar_today;
      case 'recados': return Icons.shopping_cart;
      case 'trabajo': return Icons.work;
      case 'personal': return Icons.person;
      default: return Icons.label_important_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String formattedDate = "${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}";
    bool isOverdue = !completed && dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    Color cardBackgroundColor = completed 
        ? (theme.brightness == Brightness.dark ? AppColors.darkCardBg.withOpacity(0.7) : AppColors.lightUserPageCardBg.withOpacity(0.7))
        : (theme.brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.lightUserPageCardBg);
        // O usar theme.cardTheme.color directamente si la opacidad no es necesaria:
        // Color cardBackgroundColor = theme.cardTheme.color ?? colorScheme.surface;
        // if (completed) {
        //   cardBackgroundColor = cardBackgroundColor.withOpacity(0.7);
        // }


    Color borderColor;
    double borderWidth;

    if (completed) {
      borderColor = colorScheme.secondary.withOpacity(0.7); // Verde del tema o un color de "éxito"
      borderWidth = 1.5;
    } else if (isOverdue) {
      borderColor = colorScheme.error; // Rojo del tema
      borderWidth = 2.0;
    } else {
      // --- USO DE _getPriorityColor (NO MODIFICADO) ---
      borderColor = _getPriorityColor(priority).withOpacity(0.7);
      borderWidth = 1.5;
    }

    return Card(
      elevation: completed ? (theme.cardTheme.elevation ?? 2.0) / 2 : (theme.cardTheme.elevation ?? 4.0),
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Podría tomarse de theme.cardTheme.shape si es un RoundedRectangleBorder
        side: BorderSide(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      color: cardBackgroundColor, // Usar el color de fondo de la tarjeta del tema
      child: InkWell(
        onTap: () => _navigateToTaskDetail(context),
        borderRadius: BorderRadius.circular(12.0),
        splashColor: colorScheme.primary.withOpacity(0.1), // Splash temático
        highlightColor: colorScheme.primary.withOpacity(0.05), // Highlight temático
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    // Usar color primario o de acento del tema para el icono activo, y onSurfaceVariant para completado
                    color: completed ? colorScheme.onSurface.withOpacity(0.5) : colorScheme.primary, 
                    size: 28
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 20,
                    decoration: BoxDecoration(
                      // --- USO DE _getPriorityColor (NO MODIFICADO) ---
                      color: completed ? (colorScheme.onSurface.withOpacity(0.3)) : _getPriorityColor(priority),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (textTheme.titleMedium ?? const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)).copyWith(
                        color: completed ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.onSurface,
                        decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Categoría: $category",
                      style: (textTheme.bodySmall ?? const TextStyle(fontSize: 13)).copyWith(
                        color: completed ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today, size: 14, 
                          color: completed ? colorScheme.onSurface.withOpacity(0.6) : (isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant)
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Vence: $formattedDate",
                          style: (textTheme.bodySmall ?? const TextStyle(fontSize: 13)).copyWith(
                            color: completed ? colorScheme.onSurface.withOpacity(0.6) : (isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant),
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (description != null && description!.isNotEmpty && !completed)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          description!,
                          style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6), 
                            fontStyle: FontStyle.italic
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < stars ? Icons.star : Icons.star_border,
                        // --- El color de las estrellas no se ha cambiado mucho para mantener su lógica original ---
                        color: index < stars 
                            ? (completed ? Colors.yellow.shade600.withOpacity(0.6) : Colors.yellow.shade600) 
                            : (colorScheme.onSurface.withOpacity(0.3)), // Color para estrellas vacías del tema
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  InkResponse(
                    onTap: () => _toggleTaskCompletion(context),
                    radius: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        completed ? Icons.check_circle : Icons.radio_button_unchecked_outlined,
                        // Usar color secundario para completado, y onSurfaceVariant para no completado
                        color: completed ? colorScheme.secondary : colorScheme.onSurfaceVariant.withOpacity(0.7), 
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}