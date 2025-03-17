import 'package:brainibot/Pages/Notifications%20settings.dart';
import 'package:brainibot/Pages/User%20page.dart';
import 'package:flutter/material.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'task_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskManagerScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () =>Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => User_page(),
                          ),
                        )// Vuelve,
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
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tareas de {Mes}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Hay {Número} este mes incompletas", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                SizedBox(height: 10),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(10),
                  isSelected: [true, false],
                  children: [Text("Completadas"), Text("En progreso")],
                  onPressed: (index) {},
                ),
                SizedBox(height: 20),
                StreamBuilder(
                  stream: _firestore
                  .collection("TareasUsers")
                  .doc(_auth.currentUser?.uid)
                  .collection("Tareas") // Acceder a la subcolección de tareas del usuario actual
                  .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No hay tareas disponibles"));
                    }

                    final tasks = snapshot.data!.docs;
                    return Column(
                      children: tasks.map((task) {
                        return TaskItem(
                          taskId: task.id, // Aquí usamos el ID del documento en Firestore
                          title: task["title"],
                          category: task["category"],
                          priority: task["priority"],
                          stars: _getPriorityStars(task["priority"]),
                          dueDate: (task["date"] as Timestamp).toDate(),
                        );
                      }).toList().cast<Widget>(), // Convertimos a lista de Widgets
                    );
                  },
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("View {numero} Tareas"),
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
