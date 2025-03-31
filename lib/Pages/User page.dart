import 'package:brainibot/Pages/Chat%20page.dart';
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'package:brainibot/Pages/editar_dades.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();

  User? currentUser = FirebaseAuth.instance.currentUser;
  String firstName = "";
  String lastName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("Usuaris")
          .doc(currentUser!.uid)
          .collection("Perfil")
          .doc("DatosPersonales")
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            firstName = data["nombre"] ?? "";
            lastName = data["apellidos"] ?? "";
            _nombreController.text = firstName;
            _apellidosController.text = lastName;
          });
        }
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }

  void _editarPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarDades()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EAF8),
      appBar: AppBar(
        title: const Text("BrainiBot"),
        backgroundColor: Colors.purple.shade200,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _signOut(context);
              } else if (value == 'editar') {
                _editarPerfil(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'editar',
                child: Text('Editar perfil'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
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
                      radius: 24,
                      backgroundColor: Colors.purple.shade100,
                      backgroundImage: currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
                      child: currentUser?.photoURL == null
                          ? Text(
                              firstName.isNotEmpty
                                  ? firstName.substring(0, 1).toUpperCase()
                                  : (currentUser?.email?.substring(0, 1).toUpperCase() ?? ""),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(firstName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(lastName, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                const Text("BrainiBot", style: TextStyle(fontWeight: FontWeight.bold)),
                const Text("Empezar o seguir un chat"),
                const SizedBox(height: 4),
                Text(
                  "Último Chat: .... --/--/--",
                  style: TextStyle(color: Colors.purple.shade200),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text("Historial de chats"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 62, 136, 206)),
                      child: const Text("Nuevo chat", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Tareas", style: TextStyle(fontWeight: FontWeight.bold)),
                const Text("Crear una nueva tarea o gestionar las ya creadas"),
                const SizedBox(height: 4),
                Text(
                  "Próxima Deadline: tarea:... --/--/--",
                  style: TextStyle(color: Colors.purple.shade200),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Starter()),
                        );
                      },
                      child: const Text("Gestionar tareas"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TaskC()),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 62, 136, 206)),
                      child: const Text("Nueva tarea", style: TextStyle(color: Colors.white)),
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
