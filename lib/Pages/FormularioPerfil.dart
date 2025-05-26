import 'package:flutter/material.dart';
import 'package:brainibot/auth/servei_auth.dart'; // Asegúrate que la ruta sea correcta

class FormularioPerfil extends StatefulWidget {
  final String email;

  const FormularioPerfil({Key? key, required this.email}) : super(key: key);

  @override
  State<FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<FormularioPerfil> {
  final TextEditingController tecNombre = TextEditingController();
  final TextEditingController tecApellidos = TextEditingController();

  DateTime? _selectedDate;
  String? generoSeleccionado;
  String? situacionLaboralSeleccionada;

  final List<String> _generos = [
    "Masculino",
    "Femenino",
    "Otro",
    "Prefiero no decirlo"
  ];

  final List<String> _situacionesLaborales = [
    "Empleado",
    "Desempleado",
    "Estudiante",
    "Freelance",
    "Otro"
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
      builder: (context, child) {
        // Puedes aplicar un tema específico al DatePicker si lo deseas
        // Por ejemplo, para que coincida con el tema de tu app:
        return Theme(
          data: Theme.of(context).copyWith(
            // Ejemplo de personalización de colores del DatePicker
            // colorScheme: Theme.of(context).colorScheme.copyWith(
            //   primary: Theme.of(context).colorScheme.primary, // Color del encabezado y día seleccionado
            //   onPrimary: Colors.white, // Color del texto sobre el primario
            //   surface: Colors.white, // Color de fondo del DatePicker
            //   onSurface: Colors.black, // Color del texto general
            // ),
            // textButtonTheme: TextButtonThemeData(
            //   style: TextButton.styleFrom(
            //     foregroundColor: Theme.of(context).colorScheme.primary, // Color de los botones OK/CANCEL
            //   ),
            // ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> completarRegistro() async {
    final String nombre = tecNombre.text.trim();
    final String apellidos = tecApellidos.text.trim();

    if (nombre.isEmpty ||
        apellidos.isEmpty ||
        situacionLaboralSeleccionada == null ||
        _selectedDate == null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text(
                "Por favor, completa todos los campos obligatorios marcados con *."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
      return;
    }

    String? resultat = await ServeiAuth().updateUserProfile(
      nombre: nombre,
      apellidos: apellidos,
      fechaNacimiento:
          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
      genero: generoSeleccionado ?? "", // Envía vacío si no se selecciona
      situacionLaboral: situacionLaboralSeleccionada!,
    );

    print("Resultado de updateUserProfile: $resultat");

    if (resultat == "Okay") { // Asumiendo "Okay" como éxito
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error al actualizar"),
            content: Text(resultat ?? "Ocurrió un error inesperado. Inténtalo de nuevo."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    }
  }

  Widget _buildProfileFieldCard({
    required IconData icon,
    required String label,
    required Widget fieldWidget,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.only(left:16.0, right: 16.0, top: 8.0, bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  isOptional ? "$label (Opcional)" : "$label *",
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30.0), // Alinea el campo con el texto del label
              child: fieldWidget,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Usaremos los colores del tema de la aplicación.
    // Si quieres usar los colores específicos que tenías:
    // final Color _backgroundColor = const Color(0xFFF7ECFA);
    // final Color _appBarColor = const Color(0xFFCF93D8);
    // final Color _accentColor = const Color.fromARGB(255, 197, 143, 233);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Color de fondo del tema
      appBar: AppBar(
        title: const Text("Completa tu perfil"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary, // Color primario del tema
        foregroundColor: theme.colorScheme.onPrimary, // Color del texto/iconos en AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileFieldCard(
              icon: Icons.person,
              label: "Nombre",
              fieldWidget: TextField(
                controller: tecNombre,
                decoration: const InputDecoration(
                  hintText: "Escribe tu nombre",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0)
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            _buildProfileFieldCard(
              icon: Icons.person_outline,
              label: "Apellidos",
              fieldWidget: TextField(
                controller: tecApellidos,
                decoration: const InputDecoration(
                  hintText: "Escribe tus apellidos",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0)
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            _buildProfileFieldCard(
              icon: Icons.calendar_today,
              label: "Fecha de Nacimiento",
              fieldWidget: InkWell(
                onTap: () => _selectDate(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Selecciona fecha"
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _selectedDate == null ? theme.hintColor : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
            ),
            _buildProfileFieldCard(
              icon: Icons.wc,
              label: "Género",
              isOptional: true,
              fieldWidget: DropdownButtonFormField<String>(
                value: generoSeleccionado,
                hint: Text("Selecciona género", style: TextStyle(color: theme.hintColor)),
                items: _generos.map((String genero) {
                  return DropdownMenuItem(
                    value: genero,
                    child: Text(genero),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => generoSeleccionado = value),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4.0) // Ajuste vertical
                ),
                style: theme.textTheme.bodyLarge,
                isExpanded: true,
              ),
            ),
            _buildProfileFieldCard(
              icon: Icons.work,
              label: "Situación Laboral",
              fieldWidget: DropdownButtonFormField<String>(
                value: situacionLaboralSeleccionada,
                hint: Text("Selecciona situación laboral", style: TextStyle(color: theme.hintColor)),
                items: _situacionesLaborales.map((String situation) {
                  return DropdownMenuItem(
                    value: situation,
                    child: Text(situation),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => situacionLaboralSeleccionada = value),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4.0) // Ajuste vertical
                ),
                style: theme.textTheme.bodyLarge,
                isExpanded: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: completarRegistro,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, // Color de acento/secundario del tema
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Finalizar Registro"),
            ),
          ],
        ),
      ),
    );
  }
}