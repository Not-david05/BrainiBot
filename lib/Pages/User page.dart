// Preferiblemente renombrar el archivo a algo como dashboard_screen.dart
import 'package:brainibot/Pages/Chat%20page.dart';
import 'package:brainibot/Pages/TaskC.dart';
import 'package:brainibot/User/llista_usuaris.dart';
import 'package:brainibot/User/servei_usuari.dart';
import 'package:brainibot/User/xat_entre_usuaris_page.dart';
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
  String? profileImageUrl; // Para la imagen de perfil en el drawer

  // INSTANCIA DEL NUEVO SERVICIO
  final ServeiUsuari _serveiUsuari = ServeiUsuari();

  @override
  void initState() {
    super.initState();
    // Si no lo has hecho en main.dart, podrías hacerlo aquí, pero es mejor en main.
    // initializeDateFormatting('es_ES', null);
    _loadUserData();
    _serveiUsuari.updateLastSeen(); // Actualizar lastSeen al iniciar el dashboard
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      try {
        // Cargar datos del perfil (nombre, apellidos)
        DocumentSnapshot userProfileDoc = await FirebaseFirestore.instance
            .collection("Usuaris")
            .doc(currentUser!.uid)
            .collection("Perfil")
            .doc("DatosPersonales")
            .get();

        if (userProfileDoc.exists && mounted) {
          Map<String, dynamic>? data = userProfileDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            setState(() {
              firstName = data["nombre"] ?? "";
              lastName = data["apellidos"] ?? "";
            });
          }
        }

        // Cargar URL de imagen de perfil del documento principal de Usuario
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("Usuaris")
            .doc(currentUser!.uid)
            .get();
        
        if (userDoc.exists && mounted) {
           Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
           if (data != null && data.containsKey('profile_image_url')) {
             setState(() {
               profileImageUrl = data['profile_image_url'];
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

  Widget _buildPendingRequestTile(DocumentSnapshot requestDoc, Map<String, dynamic> requestData, ThemeData theme) {
    final String requesterId = requestData['requesterId'];

    return FutureBuilder<Map<String, dynamic>?>(
      future: _serveiUsuari.getDadesUsuari(requesterId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData && userSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: CircleAvatar(backgroundColor: theme.colorScheme.surfaceVariant, radius: 18),
            title: Container(height: 12, color: theme.colorScheme.surfaceVariant.withOpacity(0.5)),
            subtitle: Container(height: 10, width: 80, color: theme.colorScheme.surfaceVariant.withOpacity(0.3)),
          );
        }
        if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
          return ListTile(title: Text('Error al cargar solicitud', style: TextStyle(color: theme.colorScheme.error)));
        }

        final requesterInfo = userSnapshot.data!;
        final requesterName = requesterInfo['nom'] as String? ?? requesterInfo['email'] as String? ?? 'Usuario';
        final requesterImageUrl = requesterInfo['profile_image_url'] as String?;
        String requesterInitial = requesterName.isNotEmpty ? requesterName.substring(0,1).toUpperCase() : "S";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: theme.colorScheme.tertiaryContainer.withOpacity(0.7),
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.onTertiaryContainer.withOpacity(0.1),
              backgroundImage: requesterImageUrl != null ? NetworkImage(requesterImageUrl) : null,
              child: requesterImageUrl == null ? Text(requesterInitial, style: TextStyle(color: theme.colorScheme.onTertiaryContainer)) : null,
            ),
            title: Text(requesterName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onTertiaryContainer)),
            subtitle: Text("Quiere ser tu amigo", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onTertiaryContainer.withOpacity(0.8))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                  tooltip: "Aceptar",
                  onPressed: () async {
                    Navigator.pop(context); // Cierra el drawer
                    final result = await _serveiUsuari.acceptFriendRequest(requesterId);
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(result ?? 'Solicitud aceptada.'), backgroundColor: result == null ? Colors.green : theme.colorScheme.error),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                  tooltip: "Rechazar",
                  onPressed: () async {
                    Navigator.pop(context); // Cierra el drawer
                    final result = await _serveiUsuari.declineFriendRequest(requesterId);
                     if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(result ?? 'Solicitud rechazada.'), backgroundColor: result == null ? Colors.orange : theme.colorScheme.error),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
              firstName.isNotEmpty ? (firstName + (lastName.isNotEmpty ? " $lastName" : "")) : "Usuario",
              style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              currentUser?.email ?? "No email",
              style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.85)),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.onPrimary,
              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
              child: profileImageUrl == null
                  ? Text(
                      userInitial,
                      style: TextStyle(fontSize: 40.0, color: colorScheme.primary),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
          ),
          ListTile(
            leading: Icon(Icons.people_alt_outlined, color: theme.iconTheme.color),
            title: Text('Ver todos los Usuarios', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LlistaUsuarisPage()));
            },
          ),
          const Divider(),
          // Sección de Solicitudes Pendientes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Solicitudes Pendientes",
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _serveiUsuari.getPendingFriendRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
              }
              if (snapshot.hasError) {
                return ListTile(title: Text('Error al cargar solicitudes', style: TextStyle(color: theme.colorScheme.error)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const ListTile(title: Text('No tienes solicitudes pendientes.', style: TextStyle(fontStyle: FontStyle.italic)));
              }
              final requestsDocs = snapshot.data!.docs;
              return Column(
                children: requestsDocs.map((doc) {
                  final requestData = doc.data() as Map<String, dynamic>;
                  return _buildPendingRequestTile(doc, requestData, theme);
                }).toList(),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Mis Amigos",
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          // StreamBuilder para la lista de amigos
          StreamBuilder<QuerySnapshot>(
            stream: _serveiUsuari.getFriendsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Center(child: SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2))));
              }
              if (snapshot.hasError) {
                return ListTile(title: Text('Error al cargar amigos', style: TextStyle(color: theme.colorScheme.error)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const ListTile(title: Text('No tienes amigos aún.', style: TextStyle(fontStyle: FontStyle.italic)));
              }

              final friendsDocs = snapshot.data!.docs;

              return Column(
                children: friendsDocs.map((doc) {
                  final friendshipData = doc.data() as Map<String, dynamic>;
                  final List<dynamic> users = friendshipData['users'];
                  final String friendId = users.firstWhere((id) => id != currentUser!.uid, orElse: () => '');

                  if (friendId.isEmpty) return const SizedBox.shrink(); // No debería pasar

                  // Necesitamos cargar los datos del amigo para mostrar su nombre e imagen
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _serveiUsuari.getDadesUsuari(friendId), // Usamos getDadesUsuari que tiene la URL de la imagen
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: theme.colorScheme.surfaceVariant, radius: 18),
                          title: Container(height: 12, color: theme.colorScheme.surfaceVariant.withOpacity(0.5)), // Placeholder
                        );
                      }
                      if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
                        return ListTile(title: Text('Amigo (Error al cargar)', style: TextStyle(color: theme.colorScheme.error)));
                      }

                      final friendData = userSnapshot.data!;
                      final friendName = friendData['nom'] as String? ?? friendData['email'] as String? ?? 'Amigo';
                      final friendImageUrl = friendData['profile_image_url'] as String?;
                      
                      String friendInitial = "A";
                      if (friendName.isNotEmpty) {
                          friendInitial = friendName.substring(0,1).toUpperCase();
                      }


                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          backgroundImage: friendImageUrl != null ? NetworkImage(friendImageUrl) : null,
                          child: friendImageUrl == null ? Text(friendInitial, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)) : null,
                        ),
                        title: Text(friendName, style: theme.textTheme.bodyMedium),
                        onTap: () async {
                          Navigator.pop(context); // Cierra el drawer
                          try {
                            final chatId = await _serveiUsuari.getOrCreateChatWithUser(friendId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => XatEntreUsuarisPage(
                                  chatId: chatId,
                                  otherUserId: friendId,
                                  chatName: friendName,
                                ),
                              ),
                            );
                          } catch (e,s) { // Añadido s para stacktrace
                             print("Error al iniciar chat desde drawer: $e");
                             print(s);
                             if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar( // Usar this.context si es necesario
                                  SnackBar(content: Text('Error al iniciar chat: ${e.toString()}'), backgroundColor: theme.colorScheme.error)
                                );
                             }
                          }
                        },
                      );
                    },
                  );
                }).toList(),
              );
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
    // Usamos la imagen de perfil cargada en _loadUserData o la del currentUser si existe
    String? displayPhotoUrl = profileImageUrl ?? currentUser?.photoURL;

    if (displayPhotoUrl == null) {
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
      body: SingleChildScrollView( // Envuelve en SingleChildScrollView para evitar overflow si el calendario es grande
          padding: const EdgeInsets.all(16.0),
          child: Card( // Mantiene la tarjeta alrededor del calendario
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Para que la Card se ajuste al contenido
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: displayPhotoUrl != null
                            ? NetworkImage(displayPhotoUrl)
                            : null,
                        child: displayPhotoUrl == null
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
                        _focusedDay = focusedDay; 
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      if (!mounted) return;
                      setState(() { _calendarFormat = format; });
                    },
                    onPageChanged: (focusedDay) {
                       if (!mounted) return;
                       setState(() {
                         _focusedDay = focusedDay;
                       });
                    },
                     headerStyle: HeaderStyle(
                      titleCentered: true,
                      titleTextStyle: textTheme.titleMedium ?? const TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
                      formatButtonVisible: true, 
                      formatButtonTextStyle: textTheme.labelMedium ?? const TextStyle(fontSize: 12.0),
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline.withOpacity(0.7)), 
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      formatButtonShowsNext: false, 
                      formatButtonPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      leftChevronIcon: Icon(Icons.chevron_left, size: 24, color: colorScheme.onSurface),
                      rightChevronIcon: Icon(Icons.chevron_right, size: 24, color: colorScheme.onSurface),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant) ?? const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
                      weekendStyle: textTheme.bodySmall?.copyWith(color: colorScheme.primary) ?? const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface) ?? const TextStyle(fontSize: 14.0),
                      weekendTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.primary) ?? const TextStyle(fontSize: 14.0),
                      todayTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondary, fontWeight: FontWeight.bold) ?? const TextStyle(),
                      todayDecoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.8), 
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold) ?? const TextStyle(),
                      selectedDecoration: BoxDecoration(
                        color: colorScheme.primary, 
                        shape: BoxShape.circle,
                      ),
                      outsideTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)) ?? TextStyle(fontSize: 14.0, color: Colors.grey.shade400),
                      disabledTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.38)) ?? TextStyle(fontSize: 14.0, color: Colors.grey.shade300),
                      cellMargin: const EdgeInsets.all(4.0), 
                      outsideDaysVisible: true, 
                    ),
                  ),
                  // SECCIÓN ELIMINADA: BrainiBot y Tareas
                  // const SizedBox(height: 24),
                  // Text("BrainiBot", style: textTheme.titleLarge),
                  // ... (resto de la sección de BrainiBot) ...
                  // const SizedBox(height: 24),
                  // Text("Tareas", style: textTheme.titleLarge),
                  // ... (resto de la sección de Tareas) ...
                  const SizedBox(height: 16), // Un pequeño espacio al final si es necesario
                ],
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