import 'package:brainibot/Pages/Notifications%20settings.dart';
import 'package:brainibot/Pages/User%20page.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'task_item.dart';

class TaskManagerScreen extends StatefulWidget {
  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Toggle con tres opciones: 0: En progreso, 1: Completadas, 2: Atrasadas
  List<bool> _isSelected = [true, false, false];

  // Función para seleccionar el toggle
  void _onTogglePressed(int index) {
    setState(() {
      for (int i = 0; i < _isSelected.length; i++) {
        _isSelected[i] = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el mes actual formateado (en español)
    String currentMonth = DateFormat.MMMM('es').format(DateTime.now());
    DateTime now = DateTime.now();
    
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendario"),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: "Tareas"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "BrainiBot"),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => User_page(),
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.more_vert),
                  ],
                ),
                SizedBox(height: 20),
                Text("Gestor de tareas", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationSettingsScreen(),
                          ),
                        );
                      },
                      child: Text("Gestionar notificaciones"),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text("Next DeadLine in"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Eliminamos cualquier botón extra y utilizamos solo el toggle para filtrar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("TareasUsers")
                  .doc(_auth.currentUser?.uid)
                  .collection("Tareas")
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                // Filtrar tareas del mes actual
                final allTasks = snapshot.data?.docs ?? [];
                final tasksForCurrentMonth = allTasks.where((task) {
                  DateTime taskDate = (task["date"] as Timestamp).toDate();
                  return taskDate.month == now.month && taskDate.year == now.year;
                }).toList();

                // Para el conteo general de tareas incompletas (en progreso sin tareas atrasadas)
                final inProgressTasks = tasksForCurrentMonth.where((task) {
                  DateTime taskDate = (task["date"] as Timestamp).toDate();
                  return task["completed"] == false && !taskDate.isBefore(now);
                }).toList();

                String countMessage = inProgressTasks.isEmpty
                    ? "¡Has terminado todas las tareas de este mes!"
                    : "Hay ${inProgressTasks.length} este mes incompletas";

                // Filtrar tareas según el toggle seleccionado:
                List<dynamic> filteredTasks = [];
                if (_isSelected[0]) {
                  // En progreso: tareas no completadas y con fecha >= hoy
                  filteredTasks = tasksForCurrentMonth.where((task) {
                    DateTime taskDate = (task["date"] as Timestamp).toDate();
                    return task["completed"] == false && !taskDate.isBefore(now);
                  }).toList();
                } else if (_isSelected[1]) {
                  // Completadas: tareas marcadas como completadas
                  filteredTasks = tasksForCurrentMonth.where((task) {
                    return task["completed"] == true;
                  }).toList();
                } else if (_isSelected[2]) {
                  // Atrasadas: tareas no completadas y con fecha < hoy
                  filteredTasks = tasksForCurrentMonth.where((task) {
                    DateTime taskDate = (task["date"] as Timestamp).toDate();
                    return task["completed"] == false && taskDate.isBefore(now);
                  }).toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tareas de $currentMonth", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(countMessage, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    SizedBox(height: 10),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(10),
                      isSelected: _isSelected,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("En progreso"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Completadas"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Atrasadas"),
                        ),
                      ],
                      onPressed: (int index) => _onTogglePressed(index),
                    ),
                    SizedBox(height: 20),
                    filteredTasks.isEmpty
                        ? Center(child: Text("No hay tareas disponibles"))
                        : Column(
                            children: filteredTasks.map((task) {
                              DateTime taskDate = (task["date"] as Timestamp).toDate();
                              return TaskItem(
                                taskId: task.id,
                                title: task["title"],
                                category: task["category"],
                                priority: task["priority"],
                                stars: _getPriorityStars(task["priority"]),
                                dueDate: taskDate,
                                completed: task["completed"] as bool,
                              );
                            }).toList().cast<Widget>(),
                          ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskC(),
                ),
              );
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  int _getPriorityStars(String priority) {
    switch (priority) {
      case "Urgente 5★":
        return 5;
      case "Alta 4★":
        return 4;
      case "Media 3★":
        return 3;
      case "Baja 2★":
        return 2;
      case "Opcional 1★":
        return 1;
      default:
        return 0;
    }
  }
}
