import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomNavTheme = theme.bottomNavigationBarTheme;

    // Los colores y estilos se tomarán del BottomNavigationBarThemeData del tema global.
    // final Color selectedColor = Colors.purple.shade600; // Eliminado
    // final Color unselectedColor = Colors.grey.shade700; // Eliminado
    // final Color backgroundColor = Colors.white; // Eliminado

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      
      // Estas propiedades ahora se tomarán del tema si están definidas allí.
      // Si no están en el tema, los valores aquí actuarán como fallback o defaults.
      backgroundColor: bottomNavTheme.backgroundColor, // Tomado del tema
      selectedItemColor: bottomNavTheme.selectedItemColor, // Tomado del tema
      unselectedItemColor: bottomNavTheme.unselectedItemColor, // Tomado del tema
      
      // Puedes mantener estos si quieres un control específico que no esté en el tema,
      // o si el tema no los define, pero es mejor definirlos en el tema.
      selectedFontSize: bottomNavTheme.selectedLabelStyle?.fontSize ?? 12.5,
      unselectedFontSize: bottomNavTheme.unselectedLabelStyle?.fontSize ?? 12.0,
      type: bottomNavTheme.type ?? BottomNavigationBarType.fixed,
      elevation: bottomNavTheme.elevation ?? 8.0,
      iconSize: bottomNavTheme.selectedIconTheme?.size ?? 26.0, // O un valor fijo si el tema no lo especifica para iconos seleccionados/no seleccionados de forma diferente.

      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(
            // El icono cambia según el estado, el color lo maneja el BottomNavigationBar
            currentIndex == 0 ? Icons.calendar_today : Icons.calendar_today_outlined,
            // color: currentIndex == 0 ? selectedColor : unselectedColor, // Eliminado, el color lo maneja BottomNavigationBar
          ),
          label: 'Calendario',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 1 ? Icons.checklist_rtl : Icons.checklist_rtl_outlined,
            // color: currentIndex == 1 ? selectedColor : unselectedColor, // Eliminado
          ),
          label: 'Tareas',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 2 ? Icons.smart_toy : Icons.smart_toy_outlined,
            // color: currentIndex == 2 ? selectedColor : unselectedColor, // Eliminado
          ),
          label: 'BrainiBot',
        ),
      ],
    );
  }
}