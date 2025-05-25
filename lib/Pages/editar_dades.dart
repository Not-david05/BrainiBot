import 'dart:io'; // Used for File, Platform, conditional on !kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For Uint8List
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brainibot/auth/servei_auth.dart'; // Assuming this path is correct
import 'package:file_picker/file_picker.dart'; // For web/desktop file picking

// Assuming your theme files are in a 'themes' directory relative to lib
// Adjust the import path if necessary
// import '../themes/app_themes.dart'; // Import your AppThemes // Comentado si no es esencial para la lógica principal

// Enum for image source selection
enum _ImageSourceOptions { camera, gallery }

class EditarDades extends StatefulWidget {
  const EditarDades({Key? key}) : super(key: key);

  @override
  State<EditarDades> createState() => _EditarDadesState();
}

class _EditarDadesState extends State<EditarDades> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // State variables for profile fields
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
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

  // State variables for image handling
  Uint8List? _imageBytes; // For web/desktop upload
  String? _imageUrl; // For display

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadProfileImage();
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
        if (mounted) {
          setState(() {
            _nombreController.text = data["nombre"] ?? "";
            _apellidosController.text = data["apellidos"] ?? "";
            if (data["fechaNacimiento"] is Timestamp) {
              _selectedDate = (data["fechaNacimiento"] as Timestamp).toDate();
            } else if (data["fechaNacimiento"] != null &&
                data["fechaNacimiento"] is String &&
                (data["fechaNacimiento"] as String).isNotEmpty) {
              try {
                List<String> parts = (data["fechaNacimiento"] as String).split('/');
                if (parts.length == 3) {
                  int day = int.tryParse(parts[0]) ?? 1;
                  int month = int.tryParse(parts[1]) ?? 1;
                  int year = int.tryParse(parts[2]) ?? 2000;
                  _selectedDate = DateTime(year, month, day);
                }
              } catch (e) {
                debugPrint("Error parsing date string: $e");
                _selectedDate = null;
              }
            }
            _generoSeleccionado = data["genero"];
            _situacionLaboralSeleccionada = data["situacionLaboral"];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar el perfil: $e")),
        );
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final user = ServeiAuth().getUsuariActual();
    if (user == null) return;
    try {
      final doc = await _firestore.collection('Usuaris').doc(user.uid).get();
      String? urlFromFirestore = doc.data()?['profile_image_url'];
      
      // DEBUG: Imprime la URL cargada desde Firestore
      debugPrint('URL cargada desde Firestore: $urlFromFirestore');

      if (urlFromFirestore != null && urlFromFirestore is String && urlFromFirestore.startsWith('http')) {
        if (mounted) setState(() => _imageUrl = urlFromFirestore);
      } else if (urlFromFirestore != null) { 
          debugPrint('URL inválida o malformada en Firestore (en _loadProfileImage): $urlFromFirestore');
          if (mounted) setState(() => _imageUrl = null);
      } else {
        debugPrint('No se encontró profile_image_url en Firestore para el usuario ${user.uid}');
        if (mounted) setState(() => _imageUrl = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar imagen: $e')));
      }
    }
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(_ImageSourceOptions.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(_ImageSourceOptions.gallery);
              },
            ),
            if (_imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(_ImageSourceOptions source) async {
    final user = ServeiAuth().getUsuariActual();
    if (user == null) return;

    XFile? pickedFileMobile;
    Uint8List? imageBytesForUpload; // Renombrado para evitar confusión con _imageBytes de estado

    bool dialogShown = false;

    try {
      bool isWebOrDesktop = kIsWeb || !(Platform.isAndroid || Platform.isIOS);

      if (isWebOrDesktop) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
        if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
           imageBytesForUpload = result.files.first.bytes;
        } else {
          return; 
        }
      } else { 
        pickedFileMobile = await _picker.pickImage(
          source: source == _ImageSourceOptions.camera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 800,
          imageQuality: 80,
        );
        if (pickedFileMobile == null) {
          return; 
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        dialogShown = true;
      }

      final fileName = '${user.uid}.jpg'; 
      final ref = _storage.ref().child('profile_images/$fileName');

      UploadTask uploadTask;
      if (isWebOrDesktop) {
        uploadTask = ref.putData(imageBytesForUpload!, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        uploadTask = ref.putFile(File(pickedFileMobile!.path), SettableMetadata(contentType: 'image/jpeg'));
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      
      // DEBUG: Imprime la URL obtenida directamente de getDownloadURL()
      debugPrint('URL de descarga obtenida POR getDownloadURL(): $url'); 

      await _firestore.collection('Usuaris').doc(user.uid).set({ 
        'profile_image_url': url,
      }, SetOptions(merge: true)); 

      if (mounted) {
        setState(() => _imageUrl = url);
        if (dialogShown) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada exitosamente')),
        );
      }
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      if (mounted) {
        if (dialogShown) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    } finally {
        // No es necesario limpiar _imageBytes aquí porque usamos imageBytesForUpload localmente.
        // _imageBytes del estado se usa para otra cosa o no se usa directamente en la subida.
        // Si _imageBytes se usara para la subida, se limpiaría aquí.
    }
  }

  Future<void> _deleteImage() async {
    final user = ServeiAuth().getUsuariActual();
    if (user == null) return;

    bool dialogShown = false;
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShown = true;
    }

    try {
      final fileName = '${user.uid}.jpg';
      try {
        await _storage.ref('profile_images/$fileName').delete();
      } catch (e) {
        if (e is FirebaseException && e.code == 'object-not-found') {
          debugPrint("Image not found in storage (object-not-found), proceeding to update Firestore.");
        } else {
          debugPrint("Error deleting from storage (non-critical for UI update): $e");
        }
      }

      await _firestore.collection('Usuaris').doc(user.uid).update({
        'profile_image_url': FieldValue.delete(), 
      });

      if (mounted) {
        setState(() => _imageUrl = null);
        if (dialogShown) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada')),
        );
      }
    } catch (e) {
      debugPrint('Error al actualizar Firestore para eliminar imagen: $e');
      if (mounted) {
        if (dialogShown) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la referencia de la imagen: $e')),
        );
      }
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme( 
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _guardarPerfil() async {
    final currentUser = ServeiAuth().getUsuariActual();
    if (currentUser == null) return;

    bool dialogShown = false;
    if (mounted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()));
      dialogShown = true;
    }

    try {
      await _firestore
          .collection('Usuaris')
          .doc(currentUser.uid)
          .collection('Perfil')
          .doc('DatosPersonales')
          .set({
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'fechaNacimiento':
            _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'genero': _generoSeleccionado,
        'situacionLaboral': _situacionLaboralSeleccionada,
      }, SetOptions(merge: true));

      if (mounted) {
        if (dialogShown) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito.')),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        if (dialogShown) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: $e')),
        );
      }
    }
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required Widget fieldWidget,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: fieldWidget,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      backgroundImage:
                          _imageUrl != null && _imageUrl!.startsWith('http') // Añadida comprobación extra
                              ? NetworkImage(_imageUrl!) 
                              : null,
                      child: _imageUrl == null || !_imageUrl!.startsWith('http')
                          ? Icon(Icons.person,
                              size: 60,
                              color: theme.colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: FloatingActionButton.small(
                        onPressed: _showImageOptions,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 2,
                        child: const Icon(Icons.edit, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Información Personal',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            _buildProfileField(
              icon: Icons.person,
              label: 'Nombre',
              fieldWidget: TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Escribe tu nombre',
                    isDense: true),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            _buildProfileField(
              icon: Icons.person_outline,
              label: 'Apellidos',
              fieldWidget: TextField(
                controller: _apellidosController,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Escribe tus apellidos',
                    isDense: true),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            _buildProfileField(
              icon: Icons.calendar_today,
              label: 'Fecha de Nacimiento',
              fieldWidget: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _selectedDate == null
                          ? 'Selecciona tu fecha'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _selectedDate == null ? theme.hintColor : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Información Adicional',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            _buildProfileField(
              icon: Icons.wc,
              label: 'Género',
              fieldWidget: DropdownButtonFormField<String>(
                value: _generoSeleccionado,
                hint: Text('Selecciona género', style: TextStyle(color: theme.hintColor)),
                onChanged: (v) => setState(() => _generoSeleccionado = v),
                items: _generos
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                style: theme.textTheme.bodyLarge,
                isExpanded: true,
              ),
            ),
            _buildProfileField(
              icon: Icons.work,
              label: 'Situación Laboral',
              fieldWidget: DropdownButtonFormField<String>(
                value: _situacionLaboralSeleccionada,
                hint: Text('Selecciona situación', style: TextStyle(color: theme.hintColor)),
                onChanged: (v) =>
                    setState(() => _situacionLaboralSeleccionada = v),
                items: _situacionesLaborales
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                style: theme.textTheme.bodyLarge,
                isExpanded: true,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                  onPressed: _guardarPerfil,
                  child: const Text('Guardar cambios'),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}