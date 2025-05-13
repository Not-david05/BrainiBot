import 'package:flutter/material.dart';
import 'package:brainibot/auth/servei_auth.dart';

class FormularioPerfil extends StatefulWidget {
  final String email;

  const FormularioPerfil({super.key, required this.email});

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

  // Variables de estilo
  final Color _backgroundColor = const Color(0xFFF7ECFA);
  final Color _appBarColor = const Color(0xFFCF93D8);
  final Color _cardColor = Colors.white;
  final Color _accentColor = const Color.fromARGB(255, 197, 143, 233);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> completarRegistro() async {
    print(tecNombre);
    print(tecApellidos);
    if (tecNombre.text.isEmpty ||
        tecApellidos.text.isEmpty ||
        situacionLaboralSeleccionada == null ||
        _selectedDate == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content:
              const Text("Por favor, completa todos los campos obligatorios."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    String? resultat= await ServeiAuth().updateUserProfile(
      nombre: tecNombre.text,
      apellidos: tecApellidos.text,
      fechaNacimiento:
          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
      genero: generoSeleccionado ?? "",
      situacionLaboral: situacionLaboralSeleccionada!,
    );
    print("Funcionando");
    print(resultat);
    Navigator.pushReplacementNamed(context, '/home');
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required Widget fieldWidget,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          label,
          style:
              TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
        ),
        subtitle: fieldWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("Completa tu perfil"),
        centerTitle: true,
        backgroundColor: _appBarColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileField(
              icon: Icons.person,
              label: "Nombre",
              fieldWidget: TextField(
                controller: tecNombre,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Escribe aquí...",
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
            _buildProfileField(
              icon: Icons.person_outline,
              label: "Apellidos",
              fieldWidget: TextField(
                controller: tecApellidos,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Escribe aquí...",
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
            // Fecha de nacimiento con selector de calendario
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Selecciona tu fecha de nacimiento"
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            // Género como desplegable
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(Icons.wc, color: Colors.grey[700]),
                title: Text(
                  "Género (Opcional)",
                  style: TextStyle(
                      color: Colors.grey[800], fontWeight: FontWeight.w600),
                ),
                subtitle: DropdownButtonFormField<String>(
                  value: generoSeleccionado,
                  onChanged: (value) =>
                      setState(() => generoSeleccionado = value),
                  items: _generos.map((String genero) {
                    return DropdownMenuItem(
                      value: genero,
                      child: Text(genero),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            // Situación laboral como desplegable
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(Icons.work, color: Colors.grey[700]),
                title: Text(
                  "Situación Laboral",
                  style: TextStyle(
                      color: Colors.grey[800], fontWeight: FontWeight.w600),
                ),
                subtitle: DropdownButtonFormField<String>(
                  value: situacionLaboralSeleccionada,
                  onChanged: (value) =>
                      setState(() => situacionLaboralSeleccionada = value),
                  items: _situacionesLaborales.map((String situation) {
                    return DropdownMenuItem(
                      value: situation,
                      child: Text(situation),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:() async {completarRegistro();} ,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Finalizar Registro",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
