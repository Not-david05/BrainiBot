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

  // Controladores para los campos del perfil
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _fechaNacController = TextEditingController();
  final TextEditingController _generoController = TextEditingController();
  final TextEditingController _situacionLaboralController = TextEditingController();

  // Booleans para controlar el estado de edición de cada campo
  bool _isNombreEditable = false;
  bool _isApellidosEditable = false;
  bool _isFechaNacEditable = false;
  bool _isGeneroEditable = false;
  bool _isSituacionEditable = false;

  // URL de la imagen de perfil
  String? _imageUrl;

  // Definimos algunos colores de ejemplo (ajústalos según tu preferencia)
  final Color _backgroundColor = const Color(0xFFF7ECFA); // Fondo general
  final Color _appBarColor = const Color(0xFFCF93D8);     // AppBar
  final Color _cardColor = Colors.white;                  // Tarjetas/Containers
  final Color _accentColor = const Color.fromARGB(255, 197, 143, 233);     // Botón "Guardar" (ejemplo)

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
    _fechaNacController.dispose();
    _generoController.dispose();
    _situacionLaboralController.dispose();
    super.dispose();
  }

  /// Recupera los datos del perfil en la subcolección "Perfil" → doc("DatosPersonales")
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
        _nombreController.text = data["nombre"] ?? "";
        _apellidosController.text = data["apellidos"] ?? "";
        _fechaNacController.text = data["fechaNacimiento"] ?? "";
        _generoController.text = data["genero"] ?? "";
        _situacionLaboralController.text = data["situacionLaboral"] ?? "";
      }
    } catch (e) {
      print("Error al obtener datos del perfil: $e");
    }
  }

  /// Sube la imagen seleccionada a Firebase Storage y guarda su URL en Firestore (campo "profile_image_url")
  Future<void> _pujarImatge() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    try {
      // Path en Storage (por ejemplo "profile_images/{uid}.jpg")
      Reference ref =
          _storage.ref().child("profile_images").child("${currentUser.uid}.jpg");
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Obtiene la URL de descarga
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Guarda la URL de la imagen en Firestore (colección "Usuaris")
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

  /// Recupera la URL de la imagen de perfil desde Firestore (campo "profile_image_url")
  Future<void> _fetchUserImage() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    final doc = await _firestore.collection("Usuaris").doc(currentUser.uid).get();
    if (doc.exists && doc.data() != null && doc.data()!["profile_image_url"] != null) {
      setState(() {
        _imageUrl = doc.data()!["profile_image_url"];
      });
    }
  }

  /// Guarda los datos del perfil llamando al método updateUserProfile del servicio
  Future<void> _guardarPerfil() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    final String? error = await ServeiAuth().updateUserProfile(
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      fechaNacimiento: _fechaNacController.text.trim(),
      genero: _generoController.text.trim(),
      situacionLaboral: _situacionLaboralController.text.trim(),
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
      setState(() {}); // O cierra esta pantalla
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ServeiAuth().getUsuariActual();

    return Scaffold(
      // Color de fondo principal
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // Se muestra el correo actual en el AppBar
        title: Text(currentUser?.email ?? ""),
        centerTitle: true,
        backgroundColor: _appBarColor, // Color del AppBar
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              // Foto de perfil + botón "Editar foto de perfil"
              GestureDetector(
                onTap: _pujarImatge,
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Botón de editar foto
                    TextButton(
                      onPressed: _pujarImatge,
                      style: TextButton.styleFrom(
                        foregroundColor: _accentColor, // Color de texto
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
              // Campos del perfil con estilo ListTile y edición habilitada al pulsar el lápiz
              _buildProfileField(
                icon: Icons.person,
                label: "Nombre",
                controller: _nombreController,
                isEditable: _isNombreEditable,
                onToggleEditable: () {
                  setState(() {
                    _isNombreEditable = !_isNombreEditable;
                  });
                },
              ),
              _buildProfileField(
                icon: Icons.person_outline,
                label: "Apellidos",
                controller: _apellidosController,
                isEditable: _isApellidosEditable,
                onToggleEditable: () {
                  setState(() {
                    _isApellidosEditable = !_isApellidosEditable;
                  });
                },
              ),
              _buildProfileField(
                icon: Icons.calendar_month,
                label: "Fecha de Nacimiento",
                controller: _fechaNacController,
                isEditable: _isFechaNacEditable,
                onToggleEditable: () {
                  setState(() {
                    _isFechaNacEditable = !_isFechaNacEditable;
                  });
                },
              ),
              _buildProfileField(
                icon: Icons.wc,
                label: "Género",
                controller: _generoController,
                isEditable: _isGeneroEditable,
                onToggleEditable: () {
                  setState(() {
                    _isGeneroEditable = !_isGeneroEditable;
                  });
                },
              ),
              _buildProfileField(
                icon: Icons.work,
                label: "Situación Laboral",
                controller: _situacionLaboralController,
                isEditable: _isSituacionEditable,
                onToggleEditable: () {
                  setState(() {
                    _isSituacionEditable = !_isSituacionEditable;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Botón "Guardar" que actualiza todos los campos en la subcolección "Perfil"
              ElevatedButton(
                onPressed: _guardarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor, // Color de fondo del botón
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Guardar cambios",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para cada campo del perfil que permite activar/desactivar la edición
  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    required VoidCallback onToggleEditable,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _cardColor, // Color del recuadro
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          label,
          style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
        ),
        subtitle: TextField(
          controller: controller,
          readOnly: !isEditable,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Escribe aquí...",
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            color: Colors.grey[800],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isEditable ? Icons.check : Icons.edit,
            color: _accentColor,
          ),
          onPressed: onToggleEditable,
        ),
      ),
    );
  }
}
