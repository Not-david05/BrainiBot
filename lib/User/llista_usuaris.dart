// lib/pages/llista_usuaris_page.dart // Crearemos esta página después
import 'package:brainibot/User/perfil_usuari_page.dart';
import 'package:brainibot/User/servei_usuari.dart'; // Asegúrate de que la ruta sea correcta
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear Timestamp

class LlistaUsuarisPage extends StatefulWidget {
  const LlistaUsuarisPage({Key? key}) : super(key: key);

  @override
  State<LlistaUsuarisPage> createState() => _LlistaUsuarisPageState();
}

class _LlistaUsuarisPageState extends State<LlistaUsuarisPage> {
  final ServeiUsuari _serveiUsuari = ServeiUsuari();

  String _formatLastSeen(Timestamp? lastSeen) {
    if (lastSeen == null) return 'Desconocido';
    final now = DateTime.now();
    final date = lastSeen.toDate();
    final difference = now.difference(date);

    if (difference.inSeconds < 5) return 'Online'; // Considerar online si es muy reciente
    if (difference.inMinutes < 1) return 'Hace ${difference.inSeconds} seg';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours} hr';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} día(s)';
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  void initState() {
    super.initState();
    _serveiUsuari.updateLastSeen(); // Actualizar lastSeen al entrar a esta pantalla
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _serveiUsuari.getLlistaUsuarisStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay otros usuarios registrados.'));
          }

          final usuaris = snapshot.data!.docs;

          return ListView.builder(
            itemCount: usuaris.length,
            itemBuilder: (context, index) {
              final usuariDoc = usuaris[index];
              final data = usuariDoc.data() as Map<String, dynamic>? ?? {};
              final userId = usuariDoc.id;

              final nom = data['nom'] as String? ?? data['email'] as String? ?? 'Usuario Desconocido';
              final profileImageUrl = data['profile_image_url'] as String?;
              final lastSeenTimestamp = data['lastSeen'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl == null || profileImageUrl.isEmpty
                        ? Icon(Icons.person, size: 30, color: theme.colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  title: Text(nom, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                  subtitle: Text('Últ. vez: ${_formatLastSeen(lastSeenTimestamp)}', style: theme.textTheme.bodySmall),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.outline),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerfilUsuariPage(userId: userId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}