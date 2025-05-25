// Preferiblemente renombrar el archivo a algo como dashboard_screen.dart
import 'package:brainibot/Pages/Chat%20page.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'package:brainibot/Widgets/custom_app_bar.dart';
import 'package:brainibot/Widgets/custom_bottom_nav_bar.dart';
import 'package:brainibot/Widgets/task_manager_screen.dart';
import 'package:brainibot/themes/app_colors.dart'; // Importa tus AppColors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// Asegúrate de importar esto si no lo has hecho ya en main.dart para localizar el calendario
// import 'package:intl/date_symbol_data_local.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  User? currentUser = FirebaseAuth.instance.currentUser;
  String firstName = "";
  String lastName = "";

  @override
  void initState() {
    super.initState();
    // Si no lo has hecho en main.dart, podrías hacerlo aquí, pero es mejor en main.
    // initializeDateFormatting('es_ES', null);
    _loadUserData();
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
        if (_currentIndex != index && mounted) {
          setState(() { _currentIndex = index; });
        } else if (ModalRoute.of(context)?.settings.name != '/') {
             Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                (Route<dynamic> route) => false,
            );
        }
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  TaskManagerScreen()),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String userInitial = "U";
    if (firstName.isNotEmpty) {
      userInitial = firstName.substring(0, 1).toUpperCase();
    } else if (currentUser?.email?.isNotEmpty == true) {
      userInitial = currentUser!.email!.substring(0, 1).toUpperCase();
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              firstName.isNotEmpty ? firstName : "Usuario",
              style: TextStyle(color: colorScheme.onPrimary),
            ),
            accountEmail: Text(
              currentUser?.email ?? "No email",
              style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.85)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              child: Text(
                userInitial,
                style: TextStyle(fontSize: 40.0, color: colorScheme.primary),
              ),
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: theme.iconTheme.color),
            title: Text('Configuración (Ejemplo)', style: theme.textTheme.bodyLarge),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String avatarText = "";
    if (currentUser?.photoURL == null) {
      if (firstName.isNotEmpty) {
        avatarText = firstName.substring(0, 1).toUpperCase();
      } else if (currentUser?.email?.isNotEmpty == true && currentUser!.email!.isNotEmpty) {
        avatarText = currentUser!.email!.substring(0, 1).toUpperCase();
      } else {
        avatarText = "U";
      }
    }

    return Scaffold(
      backgroundColor: AppColors.brainiBotPink, // Color(0xFFF4EAF8) - Fondo rosa específico
      
      appBar: CustomAppBar(
        titleText: "BrainiBot",
        pageContext: context,
        leadingWidget: Builder( 
          builder: (BuildContext scaffoldContext) {
            return IconButton(
              icon: const Icon(Icons.menu),
              tooltip: "Abrir menú",
              onPressed: () {
                Scaffold.maybeOf(scaffoldContext)?.openDrawer();
              },
            );
          },
        ),
      ),
      drawer: _buildUserPageDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
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
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: currentUser?.photoURL != null
                            ? NetworkImage(currentUser!.photoURL!)
                            : null,
                        child: currentUser?.photoURL == null
                            ? Text(
                                avatarText,
                                style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName.isNotEmpty ? firstName : "Nombre",
                              style: textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis
                            ),
                            Text(
                              lastName.isNotEmpty ? lastName : "Apellidos",
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TableCalendar(
                    locale: 'es_ES',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!mounted) return;
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay; // Asegúrate de actualizar el día enfocado también
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      if (!mounted) return;
                      setState(() { _calendarFormat = format; });
                    },
                    onPageChanged: (focusedDay) {
                       // Actualiza _focusedDay cuando el usuario cambia de página (swipe)
                       // Esto es importante para que el calendario se sienta consistente.
                       if (!mounted) return;
                       setState(() {
                         _focusedDay = focusedDay;
                       });
                    },
                     headerStyle: HeaderStyle(
                      titleCentered: true,
                      titleTextStyle: textTheme.titleMedium ?? const TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
                      formatButtonVisible: true, // Puedes cambiar a false si no quieres el botón
                      formatButtonTextStyle: textTheme.labelMedium ?? const TextStyle(fontSize: 12.0),
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline.withOpacity(0.7)), // Un poco más visible el borde
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      formatButtonShowsNext: false, // Para que el botón no muestre el siguiente formato
                      formatButtonPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      leftChevronIcon: Icon(Icons.chevron_left, size: 24, color: colorScheme.onSurface),
                      rightChevronIcon: Icon(Icons.chevron_right, size: 24, color: colorScheme.onSurface),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      // Usar textTheme para los días de la semana, con fallback
                      weekdayStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant) ?? const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
                      weekendStyle: textTheme.bodySmall?.copyWith(color: colorScheme.primary) ?? const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
                    ),
                    calendarStyle: CalendarStyle(
                      // Estilos para los números de los días
                      defaultTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface) ?? const TextStyle(fontSize: 14.0),
                      weekendTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.primary) ?? const TextStyle(fontSize: 14.0),
                      
                      // Estilos para el día de hoy
                      todayTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondary, fontWeight: FontWeight.bold) ?? const TextStyle(),
                      todayDecoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.8), // Color secundario para 'hoy' con opacidad
                        shape: BoxShape.circle,
                      ),

                      // Estilos para el día seleccionado
                      selectedTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold) ?? const TextStyle(),
                      selectedDecoration: BoxDecoration(
                        color: colorScheme.primary, // Color primario para 'seleccionado'
                        shape: BoxShape.circle,
                      ),
                      
                      // Estilos para los días fuera del mes actual
                      outsideTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)) ?? TextStyle(fontSize: 14.0, color: Colors.grey.shade400),
                      
                      // Estilos para los días deshabilitados
                      disabledTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.38)) ?? TextStyle(fontSize: 14.0, color: Colors.grey.shade300),
                      
                      // Si usas festivos (holidays), también deberías estilizarlos:
                      // holidayTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                      // holidayDecoration: BoxDecoration(
                      //   border: Border.all(color: colorScheme.error, width: 1.5),
                      //   shape: BoxShape.circle,
                      // ),
                      
                      cellMargin: const EdgeInsets.all(4.0), // Ajusta el margen de las celdas si es necesario
                      outsideDaysVisible: true, // Mantenlos visibles para un look estándar
                      // markersAlignment: Alignment.bottomCenter, // Si usas marcadores de eventos
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("BrainiBot", style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    "Empezar o seguir un chat", 
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Último Chat: .... --/--/--",
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () { print("Historial de chats presionado"); },
                        child: const Text("Historial de chats"),
                      ),
                      ElevatedButton(
                        onPressed: () => _onItemTapped(2),
                        child: const Text("Nuevo chat"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text("Tareas", style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    "Crear una nueva tarea o gestionar las ya creadas",
                     style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Próxima Deadline: tarea:... --/--/--",
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => _onItemTapped(1),
                        child: const Text("Gestionar tareas"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>  TaskC()));
                        },
                        child: const Text("Nueva tarea"),
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