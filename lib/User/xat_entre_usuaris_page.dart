import 'package:brainibot/User/servei_usuari.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class XatEntreUsuarisPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String chatName;

  const XatEntreUsuarisPage({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.chatName,
  }) : super(key: key);

  @override
  _XatEntreUsuarisPageState createState() => _XatEntreUsuarisPageState();
}

class _XatEntreUsuarisPageState extends State<XatEntreUsuarisPage> {
  final TextEditingController _controller = TextEditingController();
  final ServeiUsuari _serveiUsuari = ServeiUsuari();
  late Stream<QuerySnapshot> _missatgesStream;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _missatgesStream = _serveiUsuari.getMissatgesXatStream(widget.chatId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty && !_isSending) {
      if (mounted) setState(() => _isSending = true);
      _controller.clear();

      String? error = await _serveiUsuari.enviarMissatgeXat(
        widget.chatId,
        message,
        widget.otherUserId,
      );

      if (mounted) {
        setState(() => _isSending = false);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 3,
            color: theme.shadowColor.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: _isSending ? 'Enviando...' : 'Escribe tu mensaje...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _isSending ? null : (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          _isSending
              ? Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  iconSize: 26,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: _sendMessage,
                  tooltip: 'Enviar mensaje',
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _serveiUsuari.getUsuariActual()?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _missatgesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Aún no hay mensajes.\n¡Saluda a ${widget.chatName}!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                }

                // Invertir la lista para mostrar el último mensaje abajo y usar reverse
                final reversedDocs = docs.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
                  itemCount: reversedDocs.length,
                  itemBuilder: (context, index) {
                    var doc = reversedDocs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    
                    final String msgText = data['missatge'] ?? '[Mensaje vacío]';
                    final bool isMe = data['idAutor'] == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msgText,
                          style: TextStyle(
                            color: isMe
                                ? Colors.black // Cambiado a negro para los mensajes del propio usuario
                                : Colors.black, // Mantenido en negro para los mensajes de otros
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }
}