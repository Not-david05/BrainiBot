import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/themes/app_colors.dart'; // Importar AppColors si se usan colores de marca específicos
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key}); // Añadido super.key

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _enableNotifications = true;
  bool _filterByImportance = false;
  int _minStarLevel = 3;
  int _notificationRepetitions = 1;
  int _daysBeforeDeadline = 1;
  bool _enableCountdownForFiveStars = false;
  bool _notifyEveryDayBeforeDeadline = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);

  final ServeiAuth _serveiAuth = ServeiAuth();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final settings = await _serveiAuth.getNotificationSettings();
    if (settings != null && mounted) {
      setState(() {
        _enableNotifications =
            settings["enableNotifications"] ?? _enableNotifications;
        _filterByImportance =
            settings["filterByImportance"] ?? _filterByImportance;
        _minStarLevel = settings["minStarLevel"] ?? _minStarLevel;
        _notificationRepetitions =
            settings["notificationRepetitions"] ?? _notificationRepetitions;
        _daysBeforeDeadline =
            settings["daysBeforeDeadline"] ?? _daysBeforeDeadline;
        _enableCountdownForFiveStars = settings["enableCountdownForFiveStars"] ??
            _enableCountdownForFiveStars;
        _notifyEveryDayBeforeDeadline =
            settings["notifyEveryDayBeforeDeadline"] ??
                _notifyEveryDayBeforeDeadline;

        final timeStr = settings["notificationTime"] ?? "08:00"; // Asegurar formato HH:mm
        final parts = timeStr.split(":");
        if (parts.length == 2) {
          int hour = int.tryParse(parts[0]) ?? 8;
          int minute = int.tryParse(parts[1]) ?? 0;
          _notificationTime = TimeOfDay(hour: hour, minute: minute);
        } else {
          _notificationTime = const TimeOfDay(hour: 8, minute: 0); // Fallback
        }
      });
    }
  }

  void _pickTime(BuildContext context) async {
    if (!_enableNotifications) return;
    // El TimePicker usará los colores del tema global.
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (pickedTime != null && pickedTime != _notificationTime && mounted) {
      setState(() {
        _notificationTime = pickedTime;
      });
    }
  }

  void _saveSettings() async {
    final theme = Theme.of(context); // Para colores de SnackBar
    String? result = await _serveiAuth.saveNotificationSettings(
      enableNotifications: _enableNotifications,
      filterByImportance: _filterByImportance,
      minStarLevel: _minStarLevel,
      notificationRepetitions: _notificationRepetitions,
      daysBeforeDeadline: _daysBeforeDeadline,
      enableCountdownForFiveStars: _enableCountdownForFiveStars,
      notifyEveryDayBeforeDeadline: _notifyEveryDayBeforeDeadline,
      notificationTime: _notificationTime,
    );

    if (mounted) {
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Configuración guardada correctamente."),
            backgroundColor: theme.colorScheme.primary, // Ejemplo de color de éxito
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: theme.colorScheme.error, // Color de error
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determinar colores del AppBar según el tema
    // Asumiendo que AppColors.lightUserPageAppBarBg (rosa) es para tema claro
    final bool isLightTheme = theme.brightness == Brightness.light;
    final appBarBackgroundColor = isLightTheme ? AppColors.lightUserPageAppBarBg : theme.appBarTheme.backgroundColor;
    final appBarForegroundColor = isLightTheme ? AppColors.lightUserPagePrimaryText /* o un color específico para texto sobre rosa */ : theme.appBarTheme.foregroundColor;


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Color de fondo del tema
      appBar: AppBar(
        toolbarHeight: 100, // Mantener si es un diseño específico
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor, // Para el icono de back
        iconTheme: IconThemeData(color: appBarForegroundColor), // Específico para el icono
        title: Text(
          "Configuración de Notificaciones",
          style: theme.appBarTheme.titleTextStyle?.copyWith(color: appBarForegroundColor),
        ),
        // leading: IconButton( // El AppBar por defecto ya incluye el botón de back si puede hacer pop
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchTile(
              context, // Pasar contexto para el tema
              _enableNotifications
                  ? "Notificaciones Habilitadas" // Título más descriptivo
                  : "Notificaciones Deshabilitadas",
              _enableNotifications,
              (value) {
                if (mounted) setState(() => _enableNotifications = value);
              },
            ),
            AbsorbPointer(
              absorbing: !_enableNotifications,
              child: Opacity(
                opacity: _enableNotifications ? 1.0 : 0.5, // Opacidad para indicar deshabilitado
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSwitchTile(
                      context,
                      "Filtrar por importancia (estrellas)",
                      _filterByImportance,
                      (value) {
                        if (mounted) setState(() => _filterByImportance = value);
                      },
                    ),
                    
                    if (_filterByImportance)
                      Padding( // Añadir padding para separar visualmente
                        padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
                        child: _buildSliderWithInput(
                          context,
                          "Nivel mínimo de estrellas",
                          _minStarLevel,
                          1,
                          5,
                          (value) {
                            if (mounted) setState(() => _minStarLevel = value.toInt());
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildSwitchTile(
                      context,
                      "Notificar cada día antes de la fecha límite",
                      _notifyEveryDayBeforeDeadline,
                      (value) {
                        if (mounted) setState(() => _notifyEveryDayBeforeDeadline = value);
                      },
                    ),
                    
                    if (!_notifyEveryDayBeforeDeadline)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
                        child: _buildSliderWithInput(
                          context,
                          "Número de notificaciones por tarea",
                          _notificationRepetitions,
                          1,
                          5, // Límite práctico para repeticiones
                          (value) {
                            if (mounted) setState(() => _notificationRepetitions = value.toInt());
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                     Padding(
                        padding: const EdgeInsets.only(top: 0.0, left: 16.0, right: 16.0), // Ajuste para que no se vea tan indentado si es el único
                        child: _buildSliderWithInput(
                          context,
                          "Notificar X días antes de la fecha límite",
                          _daysBeforeDeadline,
                          1,
                          30, // Un mes como máximo
                          (value) {
                            if (mounted) setState(() => _daysBeforeDeadline = value.toInt());
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildSwitchTile(
                      context,
                      "Cuenta regresiva para tareas de 5 estrellas",
                      _enableCountdownForFiveStars,
                      (value) {
                        if (mounted) setState(() => _enableCountdownForFiveStars = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    Card( // Envolver en Card para consistencia visual
                      // El estilo de la Card se toma del tema
                      child: ListTile(
                        leading: Icon(Icons.access_time_outlined, color: colorScheme.primary),
                        title: Text("Hora de notificación principal",
                            style: textTheme.titleMedium), // Usar estilo del tema
                        subtitle: Text(_notificationTime.format(context),
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                        trailing: IconButton(
                          icon: Icon(Icons.edit_outlined, color: colorScheme.secondary), // Usar color secundario del tema
                          tooltip: "Cambiar hora",
                          onPressed: () => _pickTime(context),
                        ),
                        onTap: () => _pickTime(context), // Hacer todo el ListTile tapeable
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                onPressed: _saveSettings,
                label: const Text("Guardar Configuración"),
                // El estilo se toma de theme.elevatedButtonTheme
              ),
            ),
            const SizedBox(height: 20), // Espacio al final
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(title, style: theme.textTheme.titleMedium), // Usar estilo del tema
      value: value,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary, // Color del switch activo del tema
      // inactiveThumbColor y inactiveTrackColor también se pueden tomar del tema si se definen en SwitchThemeData
    );
  }

  Widget _buildSliderWithInput(
      BuildContext context, String title, int value, int min, int max, Function(double) onChanged) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column( // Envolver en Column para mejor estructura
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal, color: theme.colorScheme.onSurfaceVariant)), // Título un poco más sutil
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min == 0) ? null : (max-min), // Evitar división por cero si max == min
                label: value.toString(),
                onChanged: onChanged,
                activeColor: theme.sliderTheme.activeTrackColor ?? theme.colorScheme.primary,
                inactiveColor: theme.sliderTheme.inactiveTrackColor ?? theme.colorScheme.primary.withOpacity(0.3),
                thumbColor: theme.sliderTheme.thumbColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 60, // Ancho ajustado
              height: 40, // Altura para alinear mejor
              child: TextField(
                decoration: InputDecoration( // Usará el inputDecorationTheme global
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Ajustar padding
                  isDense: true,
                  // border: OutlineInputBorder(), // Ya definido en el tema
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                controller: TextEditingController(text: value.toString()),
                // style: textTheme.bodyLarge, // Estilo del texto dentro del TextField
                onSubmitted: (newValue) {
                  int? newIntValue = int.tryParse(newValue);
                  if (newIntValue != null) {
                    newIntValue = newIntValue.clamp(min, max); // Asegurar que esté en el rango
                    onChanged(newIntValue.toDouble()); // Llamar al onChanged del slider
                  } else {
                    // Si no es un número válido, revertir al valor actual del slider
                    // Esto requiere que el TextEditingController se actualice cuando el slider cambia,
                    // o manejar el estado de forma más compleja.
                    // Por simplicidad, si el input no es válido, no hacemos nada o podrías
                    // recargar el controller con el `value` actual.
                     final currentController = TextEditingController(text: value.toString());
                     currentController.selection = TextSelection.fromPosition(TextPosition(offset: currentController.text.length));
                     // No es ideal actualizar directamente el controller así, una mejor solución
                     // sería usar un `key` o un controller que se actualice con el slider.
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}