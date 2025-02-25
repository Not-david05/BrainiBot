import 'package:flutter/material.dart';

class TimeBuilder extends StatefulWidget {
  final BuildContext context;

  TimeBuilder(this.context);

  @override
  _TimeBuilderState createState() => _TimeBuilderState();
}

class _TimeBuilderState extends State<TimeBuilder> {
  TimeOfDay? _selectedTime;

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: widget.context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Hora de la tarea",
          labelStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
          filled: true,
          fillColor: Colors.blueGrey[800],
        ),
        child: Text(
          _selectedTime == null
              ? 'Selecciona una hora'
              : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
