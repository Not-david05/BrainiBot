import 'package:brainibot/Pages/Chat%20page.dart';
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';


class User_page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EAF8),
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text("D"),
                      backgroundColor: Colors.purple.shade100,
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("David", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Valentin Medina", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  height: 400,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text("BrainiBot", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Empezar o seguir un chat"),
                SizedBox(height: 4),
                Text("Último Chat: .... --/--/--", style: TextStyle(color: Colors.purple.shade200)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: Text("Historial de chats"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Chat_page(),
                            ),
                          );
                      },
                     style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 62, 136, 206)),
                      child: Text("Nuevo chat",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text("Tareas", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Crear una nueva tarea o gestionar las ya creadas"),
                SizedBox(height: 4),
                Text("Próxima Deadline: tarea:... --/--/--", style: TextStyle(color: Colors.purple.shade200)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Starter(),
                            ),
                          );
                      },
                      child: Text("Gestionar tareas"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskC(),
                            ),
                          );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 62, 136, 206)),
                      child: Text("Nueva tarea",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
