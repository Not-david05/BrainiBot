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
    // Colores basados en tu imagen y especificaciones
    final Color selectedColor = Colors.purple.shade600; // Morado para el ítem seleccionado
    final Color unselectedColor = Colors.grey.shade700; // Gris para ítems no seleccionados
    final Color backgroundColor = Colors.white; // Fondo blanco para la barra

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedFontSize: 12.5, // Tamaño de fuente para etiqueta seleccionada
      unselectedFontSize: 12, // Tamaño de fuente para etiqueta no seleccionada
      type: BottomNavigationBarType.fixed, // Mantiene el comportamiento consistente
      elevation: 8.0, // Sombra para la barra
      iconSize: 26.0, // Tamaño de los iconos
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 0 ? Icons.calendar_today : Icons.calendar_today_outlined,
            color: currentIndex == 0 ? selectedColor : unselectedColor,
          ),
          label: 'Calendario',
        ),
        BottomNavigationBarItem(
          // Icono similar al de "Tareas" en la imagen (lista con checks)
          icon: Icon(
            currentIndex == 1 ? Icons.checklist_rtl : Icons.checklist_rtl_outlined,
            color: currentIndex == 1 ? selectedColor : unselectedColor,
          ),
          label: 'Tareas',
        ),
        BottomNavigationBarItem(
          // Icono de robot para BrainiBot
          icon: Icon(
            currentIndex == 2 ? Icons.smart_toy : Icons.smart_toy_outlined,
            color: currentIndex == 2 ? selectedColor : unselectedColor,
          ),
          label: 'BrainiBot',
        ),
      ],
    );
  }
}