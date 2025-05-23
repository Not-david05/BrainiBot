import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/Widgets/Time_builder.dart';
import 'package:brainibot/auth/servei_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class TaskC extends StatefulWidget {
  @override
  _TaskCState createState() => _TaskCState();
}

class _TaskCState extends State<TaskC> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;
  String? _selectedPriority;
  String? _customCategory;
  String? _taskTitle;

  final List<String> _categories = [
    'Estudios', 'Diaria', 'Recados', 'Trabajo', 'Personal', 'Otros'
  ];

  final List<String> _priorities = [
    'Urgente 5★', 'Alta 4★', 'Media 3★', 'Baja 2★', 'Opcional 1★'
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _carouselImages = [
    'lib/images/brainibot.png',
    'lib/images/790.jpeg',
    'lib/images/1234.jpg'
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 6), (Timer timer) {
      if (_currentPage < _carouselImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_taskTitle != null && _selectedDate != null && _selectedCategory != null && _selectedPriority != null) {
      String? result = await ServeiAuth().saveTask(
        title: _taskTitle!,
        category: _selectedCategory!,
        priority: _selectedPriority!,
        date: _selectedDate!,
        time: _selectedTime,
      );

      if (result == null) {
        // Si no hay error, navega a la página de inicio
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Starter()),
        );
      } else {
        // Si hubo un error, muestra un mensaje
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    } else {
      // Si falta información
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Por favor complete todos los campos.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text("Crear Tarea", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Starter()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _carouselImages.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _carouselImages[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            _buildTextField("Título de la tarea", Icons.title, (value) {
              _taskTitle = value;
            }),
            SizedBox(height: 10),
            _buildDropdown("Categoría", _categories, _selectedCategory, (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
                if (newValue != 'Otros') _customCategory = null;
              });
            }),
            if (_selectedCategory == 'Otros') _buildTextField("Especifica la categoría", Icons.category, (value) {
              _customCategory = value;
            }),
            SizedBox(height: 10),
            _buildDropdown("Prioridad", _priorities, _selectedPriority, (String? newValue) {
              setState(() {
                _selectedPriority = newValue;
              });
            }),
            SizedBox(height: 20),
            _buildDateSelector(context),
            SizedBox(height: 20),
            _buildTimeSelector(context),
            SizedBox(height: 20),
            TimeBuilder(context),
            SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String) onChanged) {
    return TextField(
      style: TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
        filled: true,
        fillColor: Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedItem, ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        filled: true,
        fillColor: Colors.blueGrey[800],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.blueGrey[800],
          value: selectedItem,
          hint: Text('Selecciona una opción', style: TextStyle(color: Colors.white70)),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: TextStyle(color: Colors.white),
          onChanged: onChanged,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Fecha de la tarea",
          labelStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          filled: true,
          fillColor: Colors.blueGrey[800],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? 'Selecciona una fecha'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Icon(Icons.calendar_today, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    return InkWell(
      onTap: () => _selectTime(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Hora de la tarea (opcional)",
          labelStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          filled: true,
          fillColor: Colors.blueGrey[800],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime == null
                  ? 'Selecciona una hora'
                  : _selectedTime!.format(context),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Icon(Icons.access_time, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saveTask, // Llamamos a la función que guarda la tarea
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      child: Text("Crear tarea", style: TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}
