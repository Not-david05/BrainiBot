import 'package:brainibot/Pages/editar_dades.dart';
import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/themes/app_colors.dart'; // Importar si se usa algún color de marca específico
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brainibot/state/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final BuildContext pageContext; // Contexto de la página para navegación/ScaffoldMessenger
  final Widget? leadingWidget;

  const CustomAppBar({
    Key? key,
    required this.titleText,
    required this.pageContext, // Este contexto es para acciones, no para el tema del AppBar
    this.leadingWidget,
  }) : super(key: key);

  Future<void> _performSignOut(BuildContext ctx) async {
    final theme = Theme.of(ctx); // Usar el contexto local para el tema de SnackBar
    try {
      await ServeiAuth().ferLogout();
      // Podrías añadir navegación a la pantalla de login aquí si es necesario
    } catch (e) {
      if (ScaffoldMessenger.of(ctx).mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text("Error al cerrar sesión: $e"),
            backgroundColor: theme.colorScheme.error, // Usar color de error del tema
          ),
        );
      }
    }
  }

  void _performEditProfile(BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const EditarDades())); // Añadido const
  }

  @override
  Widget build(BuildContext context) { // Este 'context' es el del propio CustomAppBar y tiene el tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarTheme = theme.appBarTheme;
    final iconThemeColor = appBarTheme.iconTheme?.color ?? theme.iconTheme.color; // Color de icono del AppBar o global

    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDark;

    return AppBar(
      backgroundColor: appBarTheme.backgroundColor, // Ya toma del tema
      elevation: appBarTheme.elevation ?? 0,      // Ya toma del tema
      titleSpacing: leadingWidget == null ? NavigationToolbar.kMiddleSpacing : 0,
      automaticallyImplyLeading: leadingWidget == null,
      leading: leadingWidget, // El color del leadingWidget (si es un Icon) debería ser manejado por el tema del AppBar
      title: Text(
        titleText,
        style: appBarTheme.titleTextStyle, // Ya toma del tema
        overflow: TextOverflow.ellipsis,
      ),
      actionsIconTheme: appBarTheme.actionsIconTheme, // Usar el tema para los iconos de acción
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon( // El color se toma del actionsIconTheme o iconThemeColor
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              // color: iconThemeColor, // No es necesario si actionsIconTheme está bien configurado
            ),
            Switch(
              value: isDark,
              onChanged: (val) => themeProv.toggleTheme(val),
              // activeColor, thumbColor, etc., se toman de theme.switchTheme o colorScheme
              // activeColor: colorScheme.primary, // Ejemplo si se quiere forzar
            ),
          ],
        ),
        PopupMenuButton<String>(
          // icon: Icon(Icons.more_vert_outlined, color: iconThemeColor), // El color se toma del actionsIconTheme
          tooltip: "Opciones",
          onSelected: (value) {
            // Usar pageContext (el contexto de la PÁGINA) para acciones que afectan a la página (navegación, SnackBar)
            if (value == 'editar') {
              _performEditProfile(pageContext);
            } else if (value == 'logout') {
              _performSignOut(pageContext);
            }
          },
          // El estilo de los items (color de fondo, texto) se toma de theme.popupMenuTheme
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar perfil')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Estándar
}


class CustomTaskManagerHeader extends StatelessWidget {
  final String titleText;
  final BuildContext pageContext; // Contexto de la página para navegación/ScaffoldMessenger
  final VoidCallback onBackButtonPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onNextDeadlinePressed;

  const CustomTaskManagerHeader({ // Añadido const
    Key? key,
    required this.titleText,
    required this.pageContext, // Este contexto es para acciones
    required this.onBackButtonPressed,
    required this.onNotificationsPressed,
    required this.onNextDeadlinePressed,
  }) : super(key: key);
  
  Future<void> _performSignOut(BuildContext contextForDialog) async {
    final theme = Theme.of(contextForDialog);
    try {
      await ServeiAuth().ferLogout();
      print("Sesión cerrada");
    } catch (e) {
      print("Error al cerrar sesión: $e");
       if (ScaffoldMessenger.of(contextForDialog).mounted) {
        ScaffoldMessenger.of(contextForDialog).showSnackBar(
          SnackBar(
            content: Text("Error al cerrar sesión: $e"),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  void _performEditProfile(BuildContext contextForDialog) {
    Navigator.push(
      contextForDialog,
      MaterialPageRoute(builder: (context) => const EditarDades()), // Añadido const
    );
  }

  @override
  Widget build(BuildContext context) { // Este 'context' es el del CustomTaskManagerHeader y tiene el tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determinar el color de fondo del header. Podría ser primaryContainer o surfaceVariant.
    // Para el tema claro, AppColors.brainiBotPink (el púrpura claro original) podría ser una opción si se quiere mantener.
    // Si usamos el tema, primaryContainer suele ser una buena opción.
    final bool isLightTheme = theme.brightness == Brightness.light;
    final headerBackgroundColor = isLightTheme ? AppColors.brainiBotPink /* O AppColors.lightUserPageAppBarBg */ : colorScheme.surfaceVariant;
    final headerForegroundColor = isLightTheme ? Colors.black87 : colorScheme.onSurfaceVariant; // Color para texto e iconos sobre el fondo del header
    final buttonForegroundColor = isLightTheme ? colorScheme.primary : colorScheme.onPrimary; // Para el texto de los botones
    final buttonBackgroundColor = isLightTheme ? Colors.white : colorScheme.primaryContainer; // Para el fondo de los botones

    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(pageContext).padding.top + 10, // pageContext para el padding superior
          bottom: 20,
          left: 20,
          right: 20),
      decoration: BoxDecoration(
        color: headerBackgroundColor, // Usar color del tema
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.3), // Usar shadowColor del tema
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
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
                icon: Icon(Icons.arrow_back_ios_new, color: headerForegroundColor), // Usar color del tema
                onPressed: onBackButtonPressed,
                tooltip: "Atrás",
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_outlined, color: headerForegroundColor), // Usar color del tema
                tooltip: "Opciones",
                onSelected: (value) {
                  // Usar pageContext para acciones que afectan a la página
                  if (value == 'logout') {
                    _performSignOut(pageContext);
                  } else if (value == 'editar') {
                    _performEditProfile(pageContext);
                  }
                },
                // El estilo de los items se toma de theme.popupMenuTheme
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
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4.0), // Mantener si es un ajuste de diseño específico
            child: Text(
              titleText,
              style: textTheme.headlineMedium?.copyWith( // Usar estilo de texto del tema
                  fontWeight: FontWeight.bold,
                  color: headerForegroundColor),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  onPressed: onNotificationsPressed,
                  label: const Text("Notificaciones", style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom( // Este estilo es muy específico, podría ir al tema o mantenerse aquí si es único
                    backgroundColor: buttonBackgroundColor,
                    foregroundColor: buttonForegroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    // elevation: ... // El tema ya tiene elevation
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  onPressed: onNextDeadlinePressed,
                  label: const Text("Next Deadline", style: TextStyle(fontSize: 13)),
                   style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBackgroundColor,
                    foregroundColor: buttonForegroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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