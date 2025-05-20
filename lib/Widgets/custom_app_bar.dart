import 'package:brainibot/Pages/editar_dades.dart'; // Asegúrate que esta ruta es correcta
import 'package:brainibot/auth/servei_auth.dart';   // Asegúrate que esta ruta es correcta
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final BuildContext pageContext;
  final Widget? leadingWidget;    // <--- PARÁMETRO DEFINIDO AQUÍ

  // **** CONSTRUCTOR CORREGIDO ****
  CustomAppBar({
    Key? key,
    required this.titleText,
    required this.pageContext,
    this.leadingWidget, // Ahora el parámetro está definido en el constructor
  }) : super(key: key);
  // **** FIN DEL CONSTRUCTOR CORREGIDO ****

  Future<void> _performSignOut(BuildContext contextForDialogsOrNav) async {
    try {
      await ServeiAuth().ferLogout();
      print("Sesión cerrada");
    } catch (e) {
      print("Error al cerrar sesión: $e");
      if (ScaffoldMessenger.of(contextForDialogsOrNav).mounted) {
        ScaffoldMessenger.of(contextForDialogsOrNav).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión: $e")),
        );
      }
    }
  }

  void _performEditProfile(BuildContext contextForDialogsOrNav) {
    Navigator.push(
      contextForDialogsOrNav,
      MaterialPageRoute(builder: (context) => EditarDades()),
    ).then((_) {
      // Lógica post-edición
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFFF4EAF8),
      elevation: 0,
      titleSpacing: leadingWidget == null ? NavigationToolbar.kMiddleSpacing : 0,
      automaticallyImplyLeading: leadingWidget == null,
      leading: leadingWidget, // Se usa el parámetro
      title: Text(
        titleText,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.black),
          tooltip: "Opciones",
          onSelected: (value) {
            if (value == 'logout') {
              _performSignOut(pageContext);
            } else if (value == 'editar') {
              _performEditProfile(pageContext);
            }
          },
          itemBuilder: (BuildContext popupContext) => <PopupMenuEntry<String>>[
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
        SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// --- CustomTaskManagerHeader (sin cambios aquí) ---
class CustomTaskManagerHeader extends StatelessWidget {
  final String titleText;
  final BuildContext pageContext;
  final VoidCallback onBackButtonPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onNextDeadlinePressed;

  CustomTaskManagerHeader({
    Key? key,
    required this.titleText,
    required this.pageContext,
    required this.onBackButtonPressed,
    required this.onNotificationsPressed,
    required this.onNextDeadlinePressed,
  }) : super(key: key);

  Future<void> _performSignOut(BuildContext contextForDialog) async {
    try {
      await ServeiAuth().ferLogout();
      print("Sesión cerrada");
    } catch (e) {
      print("Error al cerrar sesión: $e");
       if (ScaffoldMessenger.of(contextForDialog).mounted) {
        ScaffoldMessenger.of(contextForDialog).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión: $e")),
        );
      }
    }
  }

  void _performEditProfile(BuildContext contextForDialog) {
    Navigator.push(
      contextForDialog,
      MaterialPageRoute(builder: (context) => EditarDades()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(pageContext).padding.top + 10,
          bottom: 20,
          left: 20,
          right: 20),
      decoration: BoxDecoration(
        color: Colors.purple[100],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: onBackButtonPressed,
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.black54),
                onSelected: (value) {
                  if (value == 'logout') {
                    _performSignOut(pageContext);
                  } else if (value == 'editar') {
                    _performEditProfile(pageContext);
                  }
                },
                itemBuilder: (BuildContext popupContext) => <PopupMenuEntry<String>>[
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
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              titleText,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onNotificationsPressed,
                  child: Text("Notificaciones", style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple[700],
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNextDeadlinePressed,
                  child: Text("Next Deadline", style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple[700],
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}