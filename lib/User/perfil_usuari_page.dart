// lib/pages/perfil_usuari_page.dart
import 'package:brainibot/User/servei_usuari.dart'; // Asegúrate de que la ruta sea correcta
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class PerfilUsuariPage extends StatefulWidget {
  final String userId;
  const PerfilUsuariPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<PerfilUsuariPage> createState() => _PerfilUsuariPageState();
}

class _PerfilUsuariPageState extends State<PerfilUsuariPage> {
  final ServeiUsuari _serveiUsuari = ServeiUsuari();
  Map<String, dynamic>? _dadesBasiquesUsuari;
  Map<String, dynamic>? _perfilDetallatUsuari;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dadesBasiques = await _serveiUsuari.getDadesUsuari(widget.userId);
      final perfilDetallat = await _serveiUsuari.getPerfilUsuari(widget.userId);
      if (mounted) {
        setState(() {
          _dadesBasiquesUsuari = dadesBasiques;
          _perfilDetallatUsuari = perfilDetallat;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error al cargar el perfil: $e";
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInfoCard(String title, String? value, IconData icon, ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.outline)),
        subtitle: Text(
          value ?? 'No especificado',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  String _formatFecha(dynamic fechaData) {
    if (fechaData == null) return 'No especificada';
    if (fechaData is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(fechaData.toDate());
    }
    if (fechaData is String && fechaData.isNotEmpty) {
        try {
            // Intenta parsear si es un string dd/MM/yyyy, si no, devuélvelo tal cual
            DateFormat('dd/MM/yyyy').parseStrict(fechaData);
            return fechaData;
        } catch (e) {
            // Podría ser un formato diferente o texto, devolver tal cual o manejar
            return fechaData; 
        }
    }
    return 'Fecha inválida';
  }

  Widget _buildFriendshipButton(AsyncSnapshot<DocumentSnapshot> snapshot, ThemeData theme) {
    if (!snapshot.hasData || !snapshot.data!.exists) {
      // No hay relación, mostrar botón de añadir
      return ElevatedButton.icon(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Añadir Amigo'),
        onPressed: () async {
          final result = await _serveiUsuari.sendFriendRequest(widget.userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result ?? 'Solicitud enviada.')),
            );
          }
        },
      );
    }

    final data = snapshot.data!.data() as Map<String, dynamic>;
    final status = data['status'];
    final requesterId = data['requesterId'];
    final currentUserId = _serveiUsuari.getUsuariActual()?.uid;

    if (status == 'pending') {
      if (requesterId == currentUserId) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.hourglass_empty),
          label: const Text('Solicitud Enviada'),
          onPressed: null, // Deshabilitado o permitir cancelar
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        );
      } else { // Solicitud recibida de este usuario
        return Column(
          children: [
            Text("Te ha enviado una solicitud de amistad.", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: const Text('Aceptar'),
                  onPressed: () async {
                    final result = await _serveiUsuari.acceptFriendRequest(widget.userId);
                     if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result ?? 'Solicitud aceptada.')),
                      );
                    }
                  },
                ),
                TextButton(
                  child: const Text('Rechazar'),
                  onPressed: () async {
                     final result = await _serveiUsuari.declineFriendRequest(widget.userId);
                     if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result ?? 'Solicitud rechazada.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      }
    } else if (status == 'accepted') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check_circle),
        label: const Text('Amigos'),
        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
        onPressed: () async { // Opción para eliminar amigo
          bool confirm = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Eliminar Amigo"),
              content: const Text("¿Seguro que quieres eliminar a este amigo?"),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text("Eliminar", style: TextStyle(color: theme.colorScheme.error))),
              ],
            )
          ) ?? false;
          if (confirm) {
            final result = await _serveiUsuari.removeFriend(widget.userId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result ?? 'Amigo eliminado.')),
              );
            }
          }
        },
      );
    }
    // Otros estados como 'declined' o 'blocked' podrían tener su UI específica
    return ElevatedButton(
      child: const Text('Añadir Amigo (Estado desconocido)'),
      onPressed: () async { /* Lógica de enviar solicitud */ },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(_errorMessage!)));
    }
    if (_dadesBasiquesUsuari == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Usuario no encontrado.')));
    }

    final nomMostra = _perfilDetallatUsuari?['nombre'] as String? ?? _dadesBasiquesUsuari?['nom'] as String? ?? _dadesBasiquesUsuari?['email'] as String? ?? 'Desconocido';
    final cognoms = _perfilDetallatUsuari?['apellidos'] as String? ?? '';
    final nomComplet = '$nomMostra $cognoms'.trim();
    final profileImageUrl = _dadesBasiquesUsuari?['profile_image_url'] as String?;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(nomComplet),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.surfaceVariant,
              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl == null || profileImageUrl.isEmpty
                  ? Icon(Icons.person, size: 60, color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              nomComplet,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_dadesBasiquesUsuari?['email'] != null)
              Text(
                _dadesBasiquesUsuari!['email'],
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // Botón de amistad
            StreamBuilder<DocumentSnapshot>(
              stream: _serveiUsuari.getFriendshipStatusStream(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return _buildFriendshipButton(snapshot, theme);
              }
            ),
            const SizedBox(height: 24),
            const Divider(),
             Text('Información del Perfil', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),

            if (_perfilDetallatUsuari != null) ...[
              _buildInfoCard('Nombre', _perfilDetallatUsuari!['nombre'], Icons.person, theme),
              _buildInfoCard('Apellidos', _perfilDetallatUsuari!['apellidos'], Icons.badge, theme),
              _buildInfoCard('Fecha Nacimiento', _formatFecha(_perfilDetallatUsuari!['fechaNacimiento']), Icons.cake, theme),
              _buildInfoCard('Género', _perfilDetallatUsuari!['genero'], Icons.wc, theme),
              _buildInfoCard('Situación Laboral', _perfilDetallatUsuari!['situacionLaboral'], Icons.work, theme),
            ] else ... [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Este usuario aún no ha completado su perfil.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              )
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}