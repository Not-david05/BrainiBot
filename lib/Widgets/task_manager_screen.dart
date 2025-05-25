import 'package:brainibot/Pages/Chat%20page.dart';
import 'package:brainibot/Pages/Notifications%20settings.dart';
import 'package:brainibot/Pages/User%20page.dart'; // Asegúrate que es DashboardScreen si lo renombraste
import 'package:brainibot/Widgets/custom_bottom_nav_bar.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Necesario para DateFormat.MMMM('es_ES')
import 'task_item.dart'; // Asumiendo que task_item.dart está en el mismo directorio o ruta correcta
import 'package:brainibot/widgets/custom_app_bar.dart'; // Contiene CustomTaskManagerHeader

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key}); // Añadido super.key

  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<bool> _isSelected = [true, false, false]; // Por defecto, "En progreso" seleccionado
  final int _currentIndexInBottomNav = 1; // TaskManager es el índice 1

  @override
  void initState() {
    super.initState();
    // La inicialización de date_symbol_data_local es mejor hacerla una vez en main.dart
    // pero si es específica para esta pantalla, puede quedarse aquí.
    // Si ya está en main.dart, puedes quitarla de aquí.
    initializeDateFormatting('es_ES', null); 
  }

  void _onTogglePressed(int index) {
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _isSelected.length; i++) {
        _isSelected[i] = i == index;
      }
    });
  }

  Future<void> _showNextDeadline() async {
    if (!mounted) return; // Comprobar si está montado al inicio
    final theme = Theme.of(context); // Para el estilo del AlertDialog

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    String? userId = _auth.currentUser?.uid;

    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Usuario no autenticado."), backgroundColor: theme.colorScheme.error));
      return;
    }

    QuerySnapshot qs;
    try {
      qs = await _firestore
          .collection("TareasUsers")
          .doc(userId)
          .collection("Tareas")
          .where("completed", isEqualTo: false)
          // .orderBy("date") // Es bueno ordenar por fecha para obtener la más próxima fácilmente si hay muchas
          .get();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al cargar tareas: ${e.toString()}"), backgroundColor: theme.colorScheme.error));
      return;
    }
    
    if (!mounted) return;

    final fechas = qs.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey("date") && data["date"] is Timestamp) {
            return (data["date"] as Timestamp).toDate();
          }
          return null; // Retornar null si el campo no existe o no es Timestamp
        })
        .whereType<DateTime>() // Filtra los nulos
        .where((d) {
          final dSolo = DateTime(d.year, d.month, d.day);
          return dSolo.isAtSameMomentAs(today) || dSolo.isAfter(today);
        })
        .toList();

    String dialogTitle, content;
    if (fechas.isEmpty) {
      dialogTitle = "Sin Próximas Deadlines";
      content = "No tienes tareas pendientes para los próximos días.";
    } else {
      fechas.sort((a, b) => a.compareTo(b)); // Ordenar para asegurar que la primera es la más próxima
      final proxima = fechas.first;
      final diff = proxima.difference(now);
      final dias = diff.inDays;
      final horas = diff.inHours.remainder(24);
      final minutos = diff.inMinutes.remainder(60);
      
      List<String> restanteParts = [];
      if (dias > 0) restanteParts.add("$dias día${dias > 1 ? 's' : ''}");
      if (horas > 0) restanteParts.add("$horas hora${horas > 1 ? 's' : ''}");
      // Mostrar minutos solo si los días y horas son 0, o si la diferencia es menor a un día.
      if (dias == 0 && horas == 0 && minutos > 0) restanteParts.add("$minutos min");
      else if (dias == 0 && horas > 0 && minutos > 0) restanteParts.add("$minutos min"); // También si hay horas
      else if (restanteParts.isEmpty && minutos > 0) restanteParts.add("$minutos min"); // Si solo quedan minutos
      else if (restanteParts.isEmpty && minutos <= 0) restanteParts.add("ahora mismo o ya pasó");


      String restante = restanteParts.isNotEmpty ? restanteParts.join(", ") : "menos de un minuto";

      dialogTitle = "Próxima Deadline";
      content = "La tarea más cercana vence en $restante.";
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          // Estilo del AlertDialog se toma del tema
          title: Text(dialogTitle, style: theme.dialogTheme.titleTextStyle),
          content: Text(content, style: theme.dialogTheme.contentTextStyle),
          shape: theme.dialogTheme.shape, // Forma del diálogo del tema
          backgroundColor: theme.dialogTheme.backgroundColor, // Color de fondo del tema
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("OK"), // Estilo del TextButton del tema
            )
          ],
        ),
      );
    }
  }

  void _onBottomNavItemTapped(int index) {
    if (_currentIndexInBottomNav == index && index == 1) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())); // DashboardScreen en lugar de User_page
        break;
      case 1:
        final currentRoute = ModalRoute.of(context)?.settings.name;
        // Puedes definir rutas nombradas para evitar esta comparación de strings
        if (currentRoute != '/task_manager_screen') { // Asumiendo una ruta nombrada
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TaskManagerScreen()));
        }
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String currentMonth = DateFormat.MMMM('es_ES').format(DateTime.now());
    currentMonth = currentMonth[0].toUpperCase() + currentMonth.substring(1); // Capitalizar
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    String? userId = _auth.currentUser?.uid;


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Color de fondo del tema
      body: Column(
        children: [
          CustomTaskManagerHeader( // Asumimos que este widget ya está tematizado
            titleText: "Gestor de tareas",
            pageContext: context, 
            onBackButtonPressed: () {
              _onBottomNavItemTapped(0); 
            },
            onNotificationsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()), // Añadido const
              );
            }, 
            onNextDeadlinePressed: _showNextDeadline,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: userId == null 
                    ? Stream.empty() // No intentar hacer stream si no hay usuario
                    : _firestore
                        .collection("TareasUsers")
                        .doc(userId)
                        .collection("Tareas")
                        .orderBy("date", descending: false) // Ordenar por fecha
                        .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (userId == null) {
                     return Center(child: Text("Inicia sesión para ver tus tareas.", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  }

                  final allTasks = snapshot.data?.docs ?? [];
                  
                  final inProgressTasksCount = allTasks.where((task) {
                     final data = task.data() as Map<String, dynamic>?;
                     if (data == null || data["date"] == null || !(data["date"] is Timestamp) || data["completed"] == null) return false;
                    DateTime taskDate = (data["date"] as Timestamp).toDate();
                    DateTime taskDayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
                    return data["completed"] == false && !taskDayOnly.isBefore(today);
                  }).length; 

                  String countMessage = inProgressTasksCount == 0
                      ? "¡No hay tareas en progreso!"
                      : "$inProgressTasksCount tarea${inProgressTasksCount > 1 ? 's' : ''} en progreso.";

                  List<DocumentSnapshot> filteredTasks = [];
                  if (_isSelected[0]) { // En progreso
                    filteredTasks = allTasks.where((task) {
                      final data = task.data() as Map<String, dynamic>?;
                      if (data == null || data["date"] == null || !(data["date"] is Timestamp) || data["completed"] == null) return false;
                      DateTime taskDate = (data["date"] as Timestamp).toDate();
                      DateTime taskDayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
                      return data["completed"] == false && !taskDayOnly.isBefore(today);
                    }).toList();
                  } else if (_isSelected[1]) { // Completadas
                    filteredTasks = allTasks.where((task) {
                       final data = task.data() as Map<String, dynamic>?;
                       if (data == null || data["completed"] == null) return false;
                      return data["completed"] == true;
                    }).toList();
                  } else if (_isSelected[2]) { // Atrasadas
                    filteredTasks = allTasks.where((task) {
                      final data = task.data() as Map<String, dynamic>?;
                      if (data == null || data["date"] == null || !(data["date"] is Timestamp) || data["completed"] == null) return false;
                      DateTime taskDate = (data["date"] as Timestamp).toDate();
                      DateTime taskDayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
                      return data["completed"] == false && taskDayOnly.isBefore(today);
                    }).toList();
                  }

                  filteredTasks.sort((a, b) {
                    final dateAData = (a.data() as Map<String, dynamic>?)?['date'];
                    final dateBData = (b.data() as Map<String, dynamic>?)?['date'];
                    if (dateAData is Timestamp && dateBData is Timestamp) {
                      return dateAData.toDate().compareTo(dateBData.toDate());
                    }
                    return 0;
                  });


                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Tareas de $currentMonth", style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface)),
                          Flexible(child: Text(countMessage, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.end,)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center( 
                        child: ToggleButtons(
                          borderRadius: BorderRadius.circular(theme.toggleButtonsTheme.borderRadius?.resolve(Directionality.of(context))?.topLeft.x ?? 8.0), // Tomar del tema o default
                          isSelected: _isSelected,
                          selectedColor: theme.toggleButtonsTheme.selectedColor ?? colorScheme.onPrimary,
                          color: theme.toggleButtonsTheme.color ?? colorScheme.onSurfaceVariant,
                          fillColor: theme.toggleButtonsTheme.fillColor ?? colorScheme.primary,
                          borderColor: theme.toggleButtonsTheme.borderColor ?? colorScheme.outline.withOpacity(0.5),
                          selectedBorderColor: theme.toggleButtonsTheme.selectedBorderColor ?? colorScheme.primary,
                          textStyle: theme.toggleButtonsTheme.textStyle ?? textTheme.labelLarge,
                          constraints: theme.toggleButtonsTheme.constraints ?? const BoxConstraints(minHeight: 36.0, minWidth: 48.0), // Ajustar minWidth
                          children: const [
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("En progreso")), // Reducido padding
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Completadas")),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Atrasadas")),
                          ],
                          onPressed: (int index) => _onTogglePressed(index),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (filteredTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, // Centrar contenido
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 60, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text("No hay tareas en esta categoría.", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true, 
                          physics: const NeverScrollableScrollPhysics(), 
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final taskDoc = filteredTasks[index];
                            final taskData = taskDoc.data() as Map<String, dynamic>? ?? {};
                            
                            DateTime taskDate = DateTime.now(); // Default
                            if (taskData["date"] is Timestamp) {
                              taskDate = (taskData["date"] as Timestamp).toDate();
                            }

                            return TaskItem( // Asumimos que TaskItem está tematizado
                              taskId: taskDoc.id,
                              title: taskData["title"] ?? "Sin título",
                              category: taskData["category"] ?? "General",
                              priority: taskData["priority"] ?? "Media 3★",
                              stars: _getPriorityStars(taskData["priority"] ?? "Media 3★"),
                              dueDate: taskDate,
                              completed: taskData["completed"] as bool? ?? false,
                              description: taskData["description"] as String?,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended( 
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskC()), 
          ).then((value) { 
             if (mounted && value == true) { 
                setState(() {});
             }
          });
        },
        label: const Text('Nueva Tarea'),
        icon: const Icon(Icons.add_task_rounded),
        // backgroundColor y foregroundColor se toman de theme.floatingActionButtonTheme
        tooltip: 'Crear Nueva Tarea',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomNavBar( // Asumimos que está tematizado
        currentIndex: _currentIndexInBottomNav,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }

  int _getPriorityStars(String priority) {
    String prioLower = priority.toLowerCase();
    if (prioLower.contains("urgente") || prioLower.contains("5★")) return 5;
    if (prioLower.contains("alta") || prioLower.contains("4★")) return 4;
    if (prioLower.contains("media") || prioLower.contains("3★")) return 3;
    if (prioLower.contains("baja") || prioLower.contains("2★")) return 2;
    if (prioLower.contains("opcional") || prioLower.contains("1★")) return 1;
    return 3; // Default
  }
}