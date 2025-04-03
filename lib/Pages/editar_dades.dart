import 'dart:io';
import 'package:flutter/material.dart';
import 'package:brainibot/auth/servei_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditarDades extends StatefulWidget {
  const EditarDades({Key? key}) : super(key: key);

  @override
  State<EditarDades> createState() => _EditarDadesState();
}

class _EditarDadesState extends State<EditarDades> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();

  // Usamos una variable DateTime para la fecha de nacimiento
  DateTime? _selectedDate;

  String? _generoSeleccionado;
  String? _situacionLaboralSeleccionada;

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

  // Booleans para controlar el estado de edición en campos de texto
  bool _isNombreEditable = false;
  bool _isApellidosEditable = false;

  String? _imageUrl;

  // Variables de estilo
  final Color _backgroundColor = const Color(0xFFF7ECFA);
  final Color _appBarColor = const Color(0xFFCF93D8);
  final Color _cardColor = Colors.white;
  final Color _accentColor = const Color.fromARGB(255, 197, 143, 233);

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserImage();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
  final currentUser = ServeiAuth().getUsuariActual();
  if (currentUser == null) return;

  try {
    final doc = await _firestore
        .collection("Usuaris")
        .doc(currentUser.uid)
        .collection("Perfil")
        .doc("DatosPersonales")
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        _nombreController.text = data["nombre"] ?? "";
        _apellidosController.text = data["apellidos"] ?? "";

        // Si el campo fechaNacimiento es un Timestamp, lo convertimos a DateTime
        if (data["fechaNacimiento"] != null && data["fechaNacimiento"] is Timestamp) {
          _selectedDate = (data["fechaNacimiento"] as Timestamp).toDate();
        } else if (data["fechaNacimiento"] != null &&
                   data["fechaNacimiento"] is String &&
                   (data["fechaNacimiento"] as String).isNotEmpty) {
          // En caso de que sea un String (opcional, si aún se guarda así)
          List<String> parts = (data["fechaNacimiento"] as String).split('/');
          if (parts.length == 3) {
            int day = int.tryParse(parts[0]) ?? 1;
            int month = int.tryParse(parts[1]) ?? 1;
            int year = int.tryParse(parts[2]) ?? 2000;
            _selectedDate = DateTime(year, month, day);
          }
        }
        _generoSeleccionado = data["genero"] ?? "";
        _situacionLaboralSeleccionada = data["situacionLaboral"] ?? "";
      });
    }
  } catch (e) {
    print("Error al obtener datos del perfil: $e");
  }
}


  Future<void> _pujarImatge() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    try {
      Reference ref = _storage
          .ref()
          .child("profile_images")
          .child("${currentUser.uid}.jpg");
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection("Usuaris").doc(currentUser.uid).update({
        "profile_image_url": downloadUrl,
      });

      setState(() {
        _imageUrl = downloadUrl;
      });
      print("Imagen de perfil subida correctamente.");
    } catch (e) {
      print("Error subiendo la imagen: $e");
    }
  }

  Future<void> _fetchUserImage() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    final doc = await _firestore.collection("Usuaris").doc(currentUser.uid).get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!["profile_image_url"] != null) {
      setState(() {
        _imageUrl = doc.data()!["profile_image_url"];
      });
    }
  }

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

  Future<void> _guardarPerfil() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    String fechaNacimientoStr = _selectedDate != null
        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
        : "";

    String? error = await ServeiAuth().updateUserProfile(
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      fechaNacimiento: fechaNacimientoStr,
      genero: _generoSeleccionado ?? "",
      situacionLaboral: _situacionLaboralSeleccionada ?? "",
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado con éxito.")),
      );
      Navigator.pop(context);
      setState(() {});
    }
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required Widget fieldWidget,
    Widget? trailing,
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
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ServeiAuth().getUsuariActual();
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(currentUser?.email ?? ""),
        centerTitle: true,
        backgroundColor: _appBarColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              // Imagen de perfil y botón para editar
              GestureDetector(
                onTap: _pujarImatge,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : null,
                      child: _imageUrl == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pujarImatge,
                      style: TextButton.styleFrom(
                        foregroundColor: _accentColor,
                      ),
                      child: const Text(
                        "Editar foto de perfil",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Campo de Nombre editable
              _buildProfileField(
                icon: Icons.person,
                label: "Nombre",
                fieldWidget: TextField(
                  controller: _nombreController,
                  readOnly: !_isNombreEditable,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Escribe aquí...",
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(color: Colors.grey[800]),
                ),
                trailing: IconButton(
                  icon: Icon(
                    _isNombreEditable ? Icons.check : Icons.edit,
                    color: _accentColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isNombreEditable = !_isNombreEditable;
                    });
                  },
                ),
              ),
              // Campo de Apellidos editable
              _buildProfileField(
                icon: Icons.person_outline,
                label: "Apellidos",
                fieldWidget: TextField(
                  controller: _apellidosController,
                  readOnly: !_isApellidosEditable,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Escribe aquí...",
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(color: Colors.grey[800]),
                ),
                trailing: IconButton(
                  icon: Icon(
                    _isApellidosEditable ? Icons.check : Icons.edit,
                    color: _accentColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isApellidosEditable = !_isApellidosEditable;
                    });
                  },
                ),
              ),
              // Fecha de nacimiento con calendario
             _buildProfileField(
              icon: Icons.calendar_today,
              label: "Fecha de Nacimiento",
              fieldWidget: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  child: Text(
                    _selectedDate == null
                        ? "Selecciona tu fecha de nacimiento"
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
              ),
            ),
              
              // Género
              _buildProfileField(
                icon: Icons.wc,
                label: "Género",
                fieldWidget: DropdownButtonFormField<String>(
                  value: _generoSeleccionado!.isNotEmpty ? _generoSeleccionado : null,
                  onChanged: (value) => setState(() {
                    _generoSeleccionado = value;
                  }),
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
              // Situación Laboral
              _buildProfileField(
                icon: Icons.work,
                label: "Situación Laboral",
                fieldWidget: DropdownButtonFormField<String>(
                  value: _situacionLaboralSeleccionada!.isNotEmpty ? _situacionLaboralSeleccionada : null,
                  onChanged: (value) => setState(() {
                    _situacionLaboralSeleccionada = value;
                  }),
                  items: _situacionesLaborales.map((String situacion) {
                    return DropdownMenuItem(
                      value: situacion,
                      child: Text(situacion),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Guardar cambios",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
