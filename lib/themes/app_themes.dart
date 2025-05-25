// lib/themes/app_themes.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  // --- TEMA OSCURO (para TaskC) ---
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.darkScaffoldBg,
    primaryColor: AppColors.darkAccent,
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkAccent,
      secondary: AppColors.darkAccent,
      surface: AppColors.darkCardBg,
      onPrimary: AppColors.darkScaffoldBg,
      onSecondary: AppColors.darkScaffoldBg,
      onSurface: AppColors.darkPrimaryText,
      background: AppColors.darkScaffoldBg,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkAppBarBg,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkPrimaryText),
      titleTextStyle: TextStyle(
        color: AppColors.darkPrimaryText,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCardBg,
      labelStyle: TextStyle(color: AppColors.darkSecondaryText),
      hintStyle: TextStyle(color: AppColors.darkSecondaryText.withOpacity(0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.darkSecondaryText.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.darkSecondaryText.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.darkAccent, width: 2),
      ),
      prefixIconColor: AppColors.darkSecondaryText,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: AppColors.darkScaffoldBg,
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.darkAccent),
    ),
    iconTheme: IconThemeData(color: AppColors.darkIcon),
    cardTheme: CardThemeData(
      color: AppColors.darkCardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkPrimaryText),
      bodyMedium: TextStyle(color: AppColors.darkPrimaryText),
      titleLarge: TextStyle(color: AppColors.darkPrimaryText, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: AppColors.darkPrimaryText),
      labelLarge: TextStyle(color: AppColors.darkAccent),
      displayLarge: TextStyle(color: AppColors.darkPrimaryText),
    ).apply(
      bodyColor: AppColors.darkPrimaryText,
      displayColor: AppColors.darkPrimaryText,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.darkCardBg,
      textStyle: TextStyle(color: AppColors.darkPrimaryText),
    ),
    dividerColor: AppColors.darkDivider,
    // ¡Eliminados dropdownTheme y DropdownThemeData!
  );

  // --- TEMA CLARO con ACENTO VERDE (para UserPage) ---
  static final ThemeData lightThemeUserPage = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.lightUserPageScaffoldBg,
    primaryColor: AppColors.lightUserPagePrimary,
    colorScheme: ColorScheme.light(
      primary: AppColors.lightUserPagePrimary,
      secondary: AppColors.lightUserPageSecondary,
      surface: AppColors.lightUserPageCardBg,
      onPrimary: AppColors.lightUserPageButtonText,
      onSecondary: Colors.black,
      onSurface: AppColors.lightUserPagePrimaryText,
      background: AppColors.lightUserPageScaffoldBg,
      error: Colors.red.shade700,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightUserPagePrimary,
      foregroundColor: AppColors.lightUserPageButtonText,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.lightUserPageButtonText),
      titleTextStyle: TextStyle(
        color: AppColors.lightUserPageButtonText,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightUserPageCardBg,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightUserPagePrimary,
        foregroundColor: AppColors.lightUserPageButtonText,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightUserPagePrimary,
        side: BorderSide(color: AppColors.lightUserPagePrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    iconTheme: IconThemeData(color: AppColors.lightUserPageIcon),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightUserPagePrimaryText, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.lightUserPagePrimaryText, fontSize: 14),
      titleLarge: TextStyle(color: AppColors.lightUserPagePrimaryText, fontWeight: FontWeight.bold, fontSize: 22),
      titleMedium: TextStyle(color: AppColors.lightUserPagePrimaryText, fontWeight: FontWeight.bold, fontSize: 18),
      labelLarge: TextStyle(color: AppColors.lightUserPageButtonText),
      labelMedium: TextStyle(color: AppColors.lightUserPageSecondaryText, fontSize: 12),
    ).apply(
      bodyColor: AppColors.lightUserPagePrimaryText,
      displayColor: AppColors.lightUserPagePrimaryText,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.lightUserPageCardBg,
      textStyle: TextStyle(color: AppColors.lightUserPagePrimaryText),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppColors.lightUserPagePrimary,
      unselectedItemColor: AppColors.lightUserPageSecondaryText,
      backgroundColor: AppColors.lightUserPageCardBg,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: AppColors.lightUserPageScaffoldBg,
    ),
    // ¡Eliminados dropdownTheme!
  );
}
