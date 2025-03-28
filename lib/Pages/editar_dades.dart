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

  // Controlador para el TextField del nombre
  final TextEditingController _nomController = TextEditingController();

  // URL de la imagen de perfil
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserImage();
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  /// Recupera el campo "nom" del documento del usuario actual en Firestore
  Future<void> _fetchUserData() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    final doc = await _firestore.collection("Usuaris").doc(currentUser.uid).get();
    if (doc.exists && doc.data() != null && doc.data()!["nom"] != null) {
      _nomController.text = doc.data()!["nom"];
    }
  }

  /// Guarda el nuevo nombre en Firestore (campo "nom") y vuelve a la pantalla anterior
  Future<void> _guardarNom() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    String nom = _nomController.text.trim();
    if (nom.isEmpty) return;

    await _firestore.collection("Usuaris").doc(currentUser.uid).update({
      "nom": nom,
    });
    Navigator.pop(context);
  }

  /// Sube la imagen seleccionada a Firebase Storage y guarda su URL en Firestore
  Future<void> _pujarImatge() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    try {
      // Define el path para la imagen en Storage (por ejemplo, "profile_images/{uid}.jpg")
      Reference ref =
          _storage.ref().child("profile_images").child("${currentUser.uid}.jpg");
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      // Obtiene la URL de descarga
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Guarda la URL de la imagen en Firestore
      await _firestore.collection("Usuaris").doc(currentUser.uid).update({
        "profile_image_url": downloadUrl,
      });

      setState(() {
        _imageUrl = downloadUrl;
      });
      print("Imatge pujada.");
    } catch (e) {
      print("Error pujant la imatge: $e");
    }
  }

  /// Recupera la URL de la imagen de perfil almacenada en Firestore
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ServeiAuth().getUsuariActual();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar dades usuari"),
      ),
      body: SingleChildScrollView(
        // Para evitar desbordamientos en pantallas pequeñas
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("Edita les teves dades"),
                const SizedBox(height: 20),
                // Muestra el email del usuario actual
                Text(
                  currentUser?.email ?? "",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // TextField para el nombre del usuario
                TextField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    hintText: "Escriu el teu nom...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _guardarNom,
                  child: const Text("Guardar"),
                ),
                const SizedBox(height: 40),
                // Sección de imagen
                _imageUrl != null
                    ? Image.network(_imageUrl!, width: 100, height: 100)
                    : const Icon(Icons.image, size: 100),
                ElevatedButton(
                  onPressed: _pujarImatge,
                  child: const Text("Recuperar imatge"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
