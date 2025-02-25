import 'package:flutter/material.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'task_item.dart';

class TaskManagerScreen extends StatelessWidget {
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
                      onPressed: () {},
                    ),
                    Spacer(),
                    Icon(Icons.more_vert),
                  ],
                ),
                SizedBox(height: 20),
                Text("Gestor de tareas", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Subtitle", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
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
                TaskItem(title: "Tarea 1", category: "Estudios", priority: "Alta", stars: 5),
                TaskItem(title: "Tarea 2", category: "Diaria", priority: "Baja", stars: 2),
                TaskItem(title: "Tarea 3", category: "Recados", priority: "Media-Alta", stars: 4),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("View 231 Tareas"),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
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
}