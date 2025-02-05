import 'package:brainibot/Pages/Starter.dart';
import 'package:flutter/material.dart';

class TaskC extends StatefulWidget {
  @override
  _TaskCState createState() => _TaskCState();
}

class _TaskCState extends State<TaskC> {
  DateTime? _selectedDate;
  String? _selectedCategory;
  String? _selectedPriority;
  String? _customCategory;

  final List<String> _categories = [
    'Estudios',
    'Diaria',
    'Recados',
    'Trabajo',
    'Personal',
    'Otros'
  ];

  final List<String> _priorities = [
    'Urgente',
    'Alta',
    'Media',
    'Baja',
    'Opcional'
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Tarea"),
        backgroundColor: Colors.purple[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Starter(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Título de la tarea",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Categoría",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: Text('Selecciona una categoría'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        if (newValue != 'Otros') {
                          _customCategory = null;
                        }
                      });
                    },
                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_selectedCategory == 'Otros')
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Especifica la categoría",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customCategory = value;
                      });
                    },
                  ),
                ),
              SizedBox(height: 10),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Prioridad",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPriority,
                    hint: Text('Selecciona la prioridad'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPriority = newValue;
                      });
                    },
                    items: _priorities.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Fecha de la tarea",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Selecciona una fecha'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.purple),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_selectedCategory == null || _selectedPriority == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Por favor, selecciona categoría y prioridad')),
                    );
                  } else {
                    print('Tarea guardada:');
                    print('Categoría: ${_selectedCategory == "Otros" ? _customCategory : _selectedCategory}');
                    print('Prioridad: $_selectedPriority');
                    print('Fecha: $_selectedDate');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 51, 119, 209),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text("Crear tarea", style: TextStyle(fontSize: 16,color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
