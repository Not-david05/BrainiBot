// lib/themes/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // --- Colores para el Tema Oscuro (TaskC) ---
  static const Color darkScaffoldBg = Color(0xFF0A192F); // Azul muy oscuro, casi negro
  static const Color darkAppBarBg = Color(0xFF0A192F); // Mismo que el scaffold o transparente
  static const Color darkCardBg = Color(0xFF172A46); // Azul oscuro para tarjetas y campos
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.grey; // Para labels, hints
  static const Color darkAccent = Colors.cyanAccent; // Acento principal
  static const Color darkIcon = Colors.cyanAccent;
  static const Color darkDivider = Colors.blueGrey;

  // --- Colores para el Tema Claro (UserPage con acento verde) ---
  static const Color lightUserPageScaffoldBg = Color(0xFFE8F5E9); // Verde muy claro para el fondo
  static const Color lightUserPageAppBarBg = Color(0xFFF4EAF8); // ROSA para CustomAppBar (se mantiene)
  static const Color lightUserPagePrimary = Colors.green; // Acento verde principal
  static const Color lightUserPagePrimaryVariant = Color(0xFF388E3C); // Verde más oscuro
  static const Color lightUserPageSecondary = Color(0xFF66BB6A); // Verde secundario
  static const Color lightUserPageCardBg = Colors.white;
  static const Color lightUserPagePrimaryText = Colors.black87;
  static const Color lightUserPageSecondaryText = Colors.black54;
  static const Color lightUserPageIcon = Colors.black54; // Iconos en AppBar
  static const Color lightUserPageButtonText = Colors.white; // Texto en botones con fondo de color

  // --- Colores comunes o para otros temas ---
  static const Color brainiBotPink = Color(0xFFF4EAF8); // El rosa de CustomAppBar
  static const Color brainiBotPurple = Colors.purple; // Púrpura general si se necesitara
}