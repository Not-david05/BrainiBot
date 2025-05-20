import 'package:brainibot/Pages/Chat%20page.dart';
import 'package:brainibot/Pages/Notifications%20settings.dart';
import 'package:brainibot/Pages/User%20page.dart';
import 'package:brainibot/Widgets/custom_bottom_nav_bar.dart';

import 'package:brainibot/Pages/TaskC.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'task_item.dart';

// IMPORTA TU CUSTOM TASK MANAGER HEADER
import 'package:brainibot/widgets/custom_app_bar.dart'; // Contiene CustomTaskManagerHeader

class TaskManagerScreen extends StatefulWidget {
  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<bool> _isSelected = [true, false, false];
  final int _currentIndexInBottomNav = 1;

  @override
  void initState() {
    super.initState();
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

  void _onBottomNavItemTapped(int index) {
    if (_currentIndexInBottomNav == index && index == 1) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => User_page()));
        break;
      case 1:
         // Ya estamos aquí, no recargar a menos que se venga de otra ruta nombrada diferente
        if (ModalRoute.of(context)?.settings.name != '/task_manager') {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TaskManagerScreen()));
        }
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatPage()));
        break;
    }
  }

  // LAS FUNCIONES _performSignOut Y _performEditProfile AHORA ESTÁN EN CustomTaskManagerHeader
  // Y SERÁN LLAMADAS DESDE ALLÍ.

  @override
  Widget build(BuildContext context) {
    String currentMonth = DateFormat.MMMM('es_ES').format(DateTime.now());
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: Column(
        children: [
          CustomTaskManagerHeader(
            titleText: "Gestor de tareas",
            pageContext: context, // Contexto de TaskManagerScreen
            onBackButtonPressed: () {
              _onBottomNavItemTapped(0); // Navega a UserPage (Calendario)
            },
            onNotificationsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
              );
            },
            onNextDeadlinePressed: () {
              // Lógica para "Next Deadline"
              print("Next Deadline presionado");
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection("TareasUsers")
                    .doc(_auth.currentUser?.uid)
                    .collection("Tareas")
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (_auth.currentUser == null) {
                     return Center(child: Text("Usuario no autenticado."));
                  }

                  final allTasks = snapshot.data?.docs ?? [];
                  final tasksForCurrentMonth = allTasks.where((task) {
                    if (task["date"] == null) return false;
                    DateTime taskDate = (task["date"] as Timestamp).toDate();
                    return taskDate.month == now.month && taskDate.year == now.year;
                  }).toList();

                  final inProgressTasksCount = tasksForCurrentMonth.where((task) {
                     if (task["date"] == null || task["completed"] == null) return false;
                    DateTime taskDate = (task["date"] as Timestamp).toDate();
                    DateTime taskDayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
                    return task["completed"] == false && !taskDayOnly.isBefore(today);
                  }).toList();

                  String countMessage = inProgressTasksCount.isEmpty
                      ? "¡Has terminado todas las tareas de este mes!"
                      : "Hay ${inProgressTasksCount.length} tareas en progreso este mes.";

                  List<DocumentSnapshot> filteredTasks = [];
                  if (_isSelected[0]) { // En progreso
                    filteredTasks = tasksForCurrentMonth.where((task) {
                      if (task["date"] == null || task["completed"] == null) return false;
                      DateTime taskDate = (task["date"] as Timestamp).toDate();
                      DateTime taskDayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
                      return task["completed"] == false && !taskDayOnly.isBefore(today);
                    }).toList();
                  } else if (_isSelected[1]) { // Completadas
                    filteredTasks = tasksForCurrentMonth.where((task) {
                       if (task["completed"] == null) return false;
                      return task["completed"] == true;
                    }).toList();
                  } else if (_isSelected[2]) { // Atrasadas
                    filteredTasks = tasksForCurrentMonth.where((task) {
                      if (task["date"] == null || task["completed"] == null) return false;
                      DateTime taskDate = (task["date"] as Timestamp).toDate();
                      DateTime taskDayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
                      return task["completed"] == false && taskDayOnly.isBefore(today);
                    }).toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tareas de $currentMonth", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Flexible(child: Text(countMessage, style: TextStyle(color: Colors.grey[700], fontSize: 12), textAlign: TextAlign.end,)),
                        ],
                      ),
                      SizedBox(height: 12),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        isSelected: _isSelected,
                        selectedColor: Colors.white,
                        color: Colors.purple[700],
                        fillColor: Colors.purple[600],
                        borderColor: Colors.purple[300],
                        selectedBorderColor: Colors.purple[700],
                        children: [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("En progreso")),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Completadas")),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Atrasadas")),
                        ],
                        onPressed: (int index) => _onTogglePressed(index),
                      ),
                      SizedBox(height: 20),
                      if (filteredTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[400]),
                                SizedBox(height: 10),
                                Text("No hay tareas disponibles", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            DateTime taskDate = (task["date"] as Timestamp).toDate();
                            return TaskItem(
                              taskId: task.id,
                              title: task["title"] ?? "Sin título",
                              category: task["category"] ?? "Sin categoría",
                              priority: task["priority"] ?? "Media",
                              stars: _getPriorityStars(task["priority"] ?? "Media"),
                              dueDate: taskDate,
                              completed: task["completed"] as bool? ?? false,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskC()),
          ).then((_) {
             if (mounted) setState(() {});
          });
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.purple,
        tooltip: 'Nueva Tarea',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndexInBottomNav,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }

  int _getPriorityStars(String priority) {
    switch (priority.toLowerCase()) {
      case "urgente 5★": case "urgente": return 5;
      case "alta 4★": case "alta": return 4;
      case "media 3★": case "media": return 3;
      case "baja 2★": case "baja": return 2;
      case "opcional 1★": case "opcional": return 1;
      default: return 3;
    }
  }
}