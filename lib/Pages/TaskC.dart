import 'dart:async';
import 'package:brainibot/Pages/Starter.dart';
// import 'package:brainibot/Widgets/Time_builder.dart'; // Comentado si no se usa o se ajusta después
import 'package:brainibot/auth/servei_auth.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Se usa para FirebaseAuth.instance.currentUser
import 'package:flutter/material.dart';

class TaskC extends StatefulWidget {
  const TaskC({super.key}); // Añadido super.key

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
  String? _taskDescription;

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
    if (_carouselImages.isNotEmpty) { // Iniciar el timer solo si hay imágenes
      _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
        if (!mounted) {
          timer.cancel(); // Cancelar el timer si el widget ya no está montado
          return;
        }
        if (_carouselImages.isNotEmpty) {
          if (_currentPage < _carouselImages.length - 1) {
            _currentPage++;
          } else {
            _currentPage = 0;
          }
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
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
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Permitir seleccionar fechas recientes pasadas
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      // El builder que forzaba el tema oscuro se elimina.
      // El DatePicker tomará el estilo del Theme.of(context) global.
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      // El builder que forzaba el tema oscuro se elimina.
      // El TimePicker tomará el estilo del Theme.of(context) global.
    );
    if (picked != null && picked != _selectedTime && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    final theme = Theme.of(context); // Para colores de SnackBar y Dialog

    if (_taskTitle == null || _taskTitle!.trim().isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Por favor, ingrese un título para la tarea."), backgroundColor: theme.colorScheme.error));
      return;
    }
    if (_selectedCategory == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Por favor, seleccione una categoría."), backgroundColor: theme.colorScheme.error));
      return;
    }
    if (_selectedCategory == 'Otros' && (_customCategory == null || _customCategory!.trim().isEmpty)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Por favor, especifique la categoría 'Otros'."), backgroundColor: theme.colorScheme.error));
      return;
    }
    if (_selectedPriority == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Por favor, seleccione una prioridad."), backgroundColor: theme.colorScheme.error));
      return;
    }
    if (_selectedDate == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Por favor, seleccione una fecha."), backgroundColor: theme.colorScheme.error));
      return;
    }

    if(mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true, 
        builder: (BuildContext dialogContext) { // Usar un contexto diferente para el diálogo
          return Dialog(
            backgroundColor: Colors.transparent, // Fondo transparente para el diálogo en sí
            elevation: 0,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(dialogContext).colorScheme.primary), // Usar color primario del tema
              ),
            ),
          );
        },
      );
    }
  
    String categoryToSave = _selectedCategory == 'Otros' ? _customCategory! : _selectedCategory!;

    String? result = await ServeiAuth().saveTask(
      title: _taskTitle!,
      category: categoryToSave,
      priority: _selectedPriority!,
      date: _selectedDate!,
      time: _selectedTime,
      description: _taskDescription,
    );

    if (mounted) {
       // Cerrar el diálogo de carga (es importante hacerlo después del await)
      Navigator.of(context, rootNavigator: true).pop();

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Tarea guardada con éxito."),
            backgroundColor: theme.colorScheme.primary, // Usar color primario para éxito
          )
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
             Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Starter()), // Asumiendo que Starter es una pantalla y no una función
              (Route<dynamic> route) => false,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: theme.colorScheme.error, // Usar color de error
          )
        );
      }
    }
  }

  Widget _buildDescriptionField(BuildContext context) {
    final theme = Theme.of(context);
    // El InputDecoration usará el inputDecorationTheme global
    return TextField(
      style: TextStyle(color: theme.colorScheme.onSurface), // Color de texto del tema
      maxLines: 4,
      onChanged: (value) => _taskDescription = value,
      decoration: const InputDecoration( // La mayoría de las propiedades se tomarán del tema
        labelText: "Descripción (opcional)",
        // labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), // Tomado del tema
        alignLabelWithHint: true,
        hintText: "Añade detalles adicionales sobre tu tarea...",
        // hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)), // Tomado del tema
        // filled y fillColor también son parte del tema
      ),
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Color de fondo del tema
      appBar: AppBar(
        // title, backgroundColor, elevation, iconTheme se toman de theme.appBarTheme
        title: const Text("Crear Tarea"),
        // backgroundColor: Colors.transparent, // Se puede omitir si el tema ya lo define
        // elevation: 0, // Se puede omitir si el tema ya lo define
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // El color se toma de appBarTheme.iconTheme
          onPressed: () {
            // Considerar si Starter es la pantalla a la que realmente se quiere volver.
            // Si TaskC se abrió sobre otra pantalla (ej. TaskManagerScreen), usar Navigator.pop(context)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Fallback si no hay nada que "popear"
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Starter()),
              );
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_carouselImages.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _carouselImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12), // Podría ser un valor del tema
                        child: Image.asset(
                          _carouselImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant, // Color de fondo del tema para error
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Icon(Icons.image_not_supported_outlined, color: colorScheme.onSurfaceVariant, size: 50)),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_carouselImages.isNotEmpty) const SizedBox(height: 24), // Espacio después del carrusel

            _buildTextField(context, "Título de la tarea *", Icons.title_outlined, (value) {
              _taskTitle = value;
            }),
            const SizedBox(height: 16),
            _buildDropdown(context, "Categoría *", Icons.category_outlined, _categories, _selectedCategory, (String? newValue) {
              if (mounted) {
                setState(() {
                  _selectedCategory = newValue;
                  if (newValue != 'Otros') _customCategory = null;
                });
              }
            }),
            if (_selectedCategory == 'Otros')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildTextField(context, "Especifica la categoría *", Icons.edit_note_outlined, (value) {
                  _customCategory = value;
                }),
              ),
            const SizedBox(height: 16),
            _buildDropdown(context, "Prioridad *", Icons.star_outline_rounded, _priorities, _selectedPriority, (String? newValue) {
              if (mounted) {
                setState(() {
                  _selectedPriority = newValue;
                });
              }
            }),
            const SizedBox(height: 20),
            _buildDateSelector(context),
            const SizedBox(height: 20),
            _buildTimeSelector(context),
            const SizedBox(height: 20),
            _buildDescriptionField(context),
            const SizedBox(height: 20),
            // if (FirebaseAuth.instance.currentUser != null)
            //   TimeBuilder(context), // Comentado, asegurarse de su propósito y si necesita refactorización de tema
            const SizedBox(height: 30),
            _buildSubmitButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, IconData icon, Function(String) onChanged) {
    final theme = Theme.of(context);
    // InputDecoration usará el inputDecorationTheme global
    return TextField(
      style: TextStyle(color: theme.colorScheme.onSurface), // Color de texto del tema
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        // labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), // Tomado del tema
        prefixIcon: Icon(icon, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.onSurfaceVariant), // Color del icono del tema
        // border, enabledBorder, focusedBorder, filled, fillColor se toman del tema
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildDropdown(BuildContext context, String label, IconData icon, List<String> items, String? selectedItem, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // InputDecoration usará el inputDecorationTheme global
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        // labelStyle: TextStyle(color: colorScheme.onSurfaceVariant), // Tomado del tema
        prefixIcon: Icon(icon, color: theme.inputDecorationTheme.prefixIconColor ?? colorScheme.onSurfaceVariant),
        // border, enabledBorder, focusedBorder, filled, fillColor se toman del tema
        contentPadding: theme.inputDecorationTheme.contentPadding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: theme.popupMenuTheme.color ?? colorScheme.surface, // Color del menú desplegable del tema
          value: selectedItem,
          isExpanded: true,
          hint: Text('Selecciona una opción', style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
          icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.onSurfaceVariant), // Icono del tema
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface), // Estilo de texto del tema
          onChanged: onChanged,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        // InputDecoration usará el inputDecorationTheme global
        decoration: InputDecoration(
          labelText: "Fecha de la tarea *",
          // labelStyle: TextStyle(color: colorScheme.onSurfaceVariant), // Tomado del tema
          // border, enabledBorder, filled, fillColor se toman del tema
          contentPadding: theme.inputDecorationTheme.contentPadding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? 'Selecciona una fecha'
                  : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
              style: textTheme.titleMedium?.copyWith(
                color: _selectedDate == null ? colorScheme.onSurfaceVariant.withOpacity(0.7) : colorScheme.onSurface,
              ),
            ),
            Icon(Icons.calendar_today_outlined, color: colorScheme.primary), // Usar color primario
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return InkWell(
      onTap: () => _selectTime(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Hora de la tarea (opcional)",
          contentPadding: theme.inputDecorationTheme.contentPadding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime == null
                  ? 'Selecciona una hora'
                  : _selectedTime!.format(context),
              style: textTheme.titleMedium?.copyWith(
                color: _selectedTime == null ? colorScheme.onSurfaceVariant.withOpacity(0.7) : colorScheme.onSurface,
              ),
            ),
            Icon(Icons.access_time_outlined, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    // El ElevatedButton usará el elevatedButtonTheme global
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_task_rounded),
      onPressed: _saveTask,
      label: const Text("Crear tarea"),
      // style: ElevatedButton.styleFrom(
      //   backgroundColor: colorScheme.primary, // Tomado del tema
      //   foregroundColor: colorScheme.onPrimary, // Tomado del tema
      //   padding: EdgeInsets.symmetric(vertical: 16),
      //   textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), // Tomado del tema
      //   minimumSize: Size(double.infinity, 50),
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Tomado del tema
      // ),
    );
  }
}