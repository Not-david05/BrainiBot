import 'package:brainibot/auth/servei_auth.dart';
import 'package:flutter/material.dart';
class NotificationSettingsScreen extends StatefulWidget {
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
  TimeOfDay _notificationTime = TimeOfDay(hour: 8, minute: 0);

  final ServeiAuth _serveiAuth = ServeiAuth();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Cargar configuración desde Firestore
  void _loadSettings() async {
    final settings = await _serveiAuth.getNotificationSettings();
    if (settings != null) {
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

        // Convertir la cadena de hora en TimeOfDay
        final timeStr = settings["notificationTime"] ?? "8:0";
        final parts = timeStr.split(":");
        int hour = int.tryParse(parts[0]) ?? 8;
        int minute = int.tryParse(parts[1]) ?? 0;
        _notificationTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  void _pickTime(BuildContext context) async {
    if (!_enableNotifications) return;
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (pickedTime != null && pickedTime != _notificationTime) {
      setState(() {
        _notificationTime = pickedTime;
      });
    }
  }

  // Método para guardar la configuración usando el servicio
  void _saveSettings() async {
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

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Configuración guardada correctamente.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.purple[100],
        title: Text("Configuración de Notificaciones"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchTile(
              _enableNotifications
                  ? "Deshabilitar Notificaciones"
                  : "Habilitar Notificaciones",
              _enableNotifications, 
              (value) {
                setState(() => _enableNotifications = value);
              }
            ),
            AbsorbPointer(
              absorbing: !_enableNotifications,
              child: Opacity(
                opacity: _enableNotifications ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    _buildSwitchTile(
                      "Filtrar notificaciones por importancia",
                      _filterByImportance, 
                      (value) {
                        setState(() => _filterByImportance = value);
                      }
                    ),
                    SizedBox(height: 20),
                    if (_filterByImportance)
                      _buildSliderWithInput(
                        "Filtrar notificaciones por estrellas",
                        _minStarLevel,
                        1,
                        5, 
                        (value) {
                          setState(() => _minStarLevel = value.toInt());
                        }
                      ),
                    SizedBox(height: 20),
                    _buildSwitchTile(
                      "Notificaciones activas todos los días antes de la deadline",
                      _notifyEveryDayBeforeDeadline, 
                      (value) {
                        setState(() => _notifyEveryDayBeforeDeadline = value);
                      }
                    ),
                    SizedBox(height: 20),
                    if (!_notifyEveryDayBeforeDeadline)
                      _buildSliderWithInput(
                        "Repeticiones de notificación",
                        _notificationRepetitions,
                        1,
                        30, 
                        (value) {
                          setState(() => _notificationRepetitions = value.toInt());
                        }
                      ),
                    SizedBox(height: 20),
                    _buildSliderWithInput(
                      "Días antes de la fecha límite para notificar",
                      _daysBeforeDeadline,
                      1,
                      30, 
                      (value) {
                        setState(() => _daysBeforeDeadline = value.toInt());
                      }
                    ),
                    SizedBox(height: 20),
                    _buildSwitchTile(
                      "Habilitar cronómetro para tareas de 5 estrellas",
                      _enableCountdownForFiveStars, 
                      (value) {
                        setState(() => _enableCountdownForFiveStars = value);
                      }
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.access_time, color: Colors.purple),
                      title: Text("Hora de notificación",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${_notificationTime.format(context)}",
                          style: TextStyle(fontSize: 16)),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _pickTime(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: Text("Guardar Configuración"),
                style: ElevatedButton.styleFrom(overlayColor: Colors.purple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.purple,
    );
  }

  Widget _buildSliderWithInput(
      String title, int value, int min, int max, Function(double) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: "$value",
                onChanged: onChanged,
                activeColor: Colors.purple,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 50,
          child: TextField(
            decoration: InputDecoration(border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            controller: TextEditingController(text: "$value"),
            onSubmitted: (newValue) {
              int? newIntValue = int.tryParse(newValue);
              if (newIntValue != null) {
                newIntValue = newIntValue.clamp(min, max);
                setState(() {
                  onChanged(newIntValue!.toDouble());
                });
              }
            },
          ),
        ),
      ],
    );
  }
}
