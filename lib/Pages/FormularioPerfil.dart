import 'package:flutter/material.dart';
import 'package:brainibot/auth/servei_auth.dart';

class FormularioPerfil extends StatefulWidget {
  final String email;
  final String password;

  const FormularioPerfil({super.key, required this.email, required this.password});

  @override
  State<FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<FormularioPerfil> {
  final TextEditingController tecNombre = TextEditingController();
  final TextEditingController tecApellidos = TextEditingController();
  final TextEditingController tecFechaNacimiento = TextEditingController();
  String? generoSeleccionado;
  final TextEditingController tecSituacionLaboral = TextEditingController();

  Future<void> completarRegistro() async {
    if (tecNombre.text.isEmpty || tecApellidos.text.isEmpty || tecSituacionLaboral.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Por favor, completa todos los campos obligatorios."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    String? error = await ServeiAuth().resgitreAmbEmaiIPassword(widget.email, widget.password);
    if (error != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(error),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    await ServeiAuth().updateUserProfile(
      email: widget.email,
      nombre: tecNombre.text,
      apellidos: tecApellidos.text,
      fechaNacimiento: tecFechaNacimiento.text,
      genero: generoSeleccionado ?? "",
      situacionLaboral: tecSituacionLaboral.text,
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completa tu perfil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: tecNombre, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: tecApellidos, decoration: const InputDecoration(labelText: "Apellidos")),
            TextField(controller: tecFechaNacimiento, decoration: const InputDecoration(labelText: "Fecha de Nacimiento (Opcional)")),
            DropdownButtonFormField<String>(
              value: generoSeleccionado,
              onChanged: (value) => setState(() => generoSeleccionado = value),
              items: ["Masculino", "Femenino", "Otro", "Prefiero no decirlo"].map((String genero) {
                return DropdownMenuItem(value: genero, child: Text(genero));
              }).toList(),
              decoration: const InputDecoration(labelText: "Género (Opcional)"),
            ),
            TextField(controller: tecSituacionLaboral, decoration: const InputDecoration(labelText: "Situación Laboral")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: completarRegistro, child: const Text("Finalizar Registro")),
          ],
        ),
      ),
    );
  }
}
