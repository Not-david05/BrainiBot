import 'package:brainibot/Pages/Chat%20page.dart';
import 'package:brainibot/Pages/Starter.dart'; // Para navegar a Gestor de Tareas (si es diferente a TaskManagerScreen)
import 'package:brainibot/Pages/TaskC.dart'; // Para el botón "Nueva Tarea" si se mantiene
import 'package:brainibot/Pages/editar_dades.dart';
import 'package:brainibot/Widgets/custom_bottom_nav_bar.dart';
import 'package:brainibot/Widgets/task_manager_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// IMPORTA TU CUSTOM APP BAR
import 'package:brainibot/Widgets/custom_app_bar.dart'; // Asumiendo que CustomAppBar está en 'widgets'

// Si User_page es la raíz de tu app, este MaterialApp está bien.
class User_page extends StatelessWidget { // Nombre de clase User_page
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
      routes: {
        '/task_manager': (context) => TaskManagerScreen(),
        '/chat': (context) => ChatPage(),
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

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

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("Usuaris")
            .doc(currentUser!.uid)
            .collection("Perfil")
            .doc("DatosPersonales")
            .get();

        if (userDoc.exists && mounted) {
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
      } catch (e) {
        print("Error cargando datos de usuario: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error cargando datos del perfil: $e")));
        }
      }
    }
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index && index == 0) return;

    switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/') {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()), // Asumiendo que DashboardScreen es la home de User_page
                (Route<dynamic> route) => false,
            );
        } else {
            if (mounted) setState(() { _currentIndex = index; });
        }
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskManagerScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatPage()),
        );
        break;
    }
  }

  Widget _buildUserPageDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(firstName.isNotEmpty ? firstName : "Usuario"),
            accountEmail: Text(currentUser?.email ?? "No email"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.purple.shade300,
              child: Text(
                firstName.isNotEmpty
                    ? firstName.substring(0, 1).toUpperCase()
                    : (currentUser?.email?.isNotEmpty == true ? currentUser!.email!.substring(0, 1).toUpperCase() : "U"),
                style: TextStyle(fontSize: 40.0, color: Colors.white),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configuración (Ejemplo)'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EAF8),
      appBar: CustomAppBar(
        titleText: "BrainiBot",
        pageContext: context,
        // **** CORRECCIÓN AQUÍ: Cambiar leadingType a leadingWidget ****
        leadingWidget: Builder( // Usar Builder para obtener el contexto correcto para Scaffold.of
          builder: (BuildContext scaffoldContext) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              tooltip: "Abrir menú",
              onPressed: () {
                // Usar el scaffoldContext del Builder para encontrar el Scaffold de esta página
                final scaffold = Scaffold.maybeOf(scaffoldContext);
                if (scaffold != null && scaffold.hasDrawer) {
                  scaffold.openDrawer();
                } else {
                   print("Drawer no encontrado por el Builder del leadingWidget en UserPage.");
                }
              },
            );
          },
        ),
        // **** FIN DE LA CORRECCIÓN ****
      ),
      drawer: _buildUserPageDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
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
                                    : (currentUser?.email?.isNotEmpty == true ? currentUser!.email!.substring(0, 1).toUpperCase() : ""),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black54),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(firstName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                            Text(lastName, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!mounted) return;
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      if (!mounted) return;
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                     headerStyle: HeaderStyle(
                      titleTextStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                      formatButtonTextStyle: TextStyle(fontSize: 12.0),
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      formatButtonPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      leftChevronIcon: Icon(Icons.chevron_left, size: 24),
                      rightChevronIcon: Icon(Icons.chevron_right, size: 24),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 13.0, color: Colors.black87),
                      weekendStyle: TextStyle(fontSize: 13.0, color: Colors.purple.shade300),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(fontSize: 14.0),
                      weekendTextStyle: TextStyle(fontSize: 14.0, color: Colors.purple.shade400),
                      todayTextStyle: TextStyle(fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold),
                      selectedTextStyle: TextStyle(fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold),
                      todayDecoration: BoxDecoration(
                        color: Colors.purple.shade200,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.purple.shade400,
                        shape: BoxShape.circle,
                      ),
                      cellMargin: EdgeInsets.all(3.0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("BrainiBot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text("Empezar o seguir un chat", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    "Último Chat: .... --/--/--",
                    style: TextStyle(color: Colors.purple.shade300, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () { print("Historial de chats presionado"); },
                        child: const Text("Historial de chats"),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
                      ),
                      ElevatedButton(
                        onPressed: () => _onItemTapped(2),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                        child: const Text("Nuevo chat", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Tareas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text("Crear una nueva tarea o gestionar las ya creadas", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    "Próxima Deadline: tarea:... --/--/--",
                    style: TextStyle(color: Colors.purple.shade300, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => _onItemTapped(1),
                        child: const Text("Gestionar tareas"),
                         style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TaskC()));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                        child: const Text("Nueva tarea", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}