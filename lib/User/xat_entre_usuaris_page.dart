// lib/pages/xat_entre_usuaris_page.dart
import 'package:brainibot/User/servei_usuari.dart';
// Asegúrate que la ruta sea correcta
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class XatEntreUsuarisPage extends StatefulWidget {
  final String chatId;
  final String otherUserId; // Necesario para saber con quién hablamos y para enviar mensajes
  final String chatName;   // Nombre del otro usuario para la AppBar

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(durationMillis: 500));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({int durationMillis = 300}) {
    if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
       Future.delayed(const Duration(milliseconds: 100), () { // Pequeño delay para asegurar que el layout esté completo
          if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) { // Doble check
             _scrollController.animateTo(
               _scrollController.position.maxScrollExtent,
               duration: Duration(milliseconds: durationMillis),
               curve: Curves.easeOut,
             );
          }
       });
    }
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty && !_isSending) {
      if (mounted) setState(() => _isSending = true);
      _controller.clear();

      String? error = await _serveiUsuari.enviarMissatgeXat(
        widget.chatId,
        message,
        widget.otherUserId, // Necesario para actualizar lastMessage o notificaciones futuras
      );

      if (mounted) {
        setState(() => _isSending = false);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar: $error'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        } else {
           _scrollToBottom(); // Scroll after successful send
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
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: _isSending ? "Enviando..." : "Escribe tu mensaje...",
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                // border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                // filled: true,
                // fillColor: theme.colorScheme.surfaceVariant,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _isSending ? null : (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          _isSending
            ? Container(
                width: 44, height: 44,
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
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
                tooltip: "Enviar mensaje",
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
        // Podrías añadir aquí la foto de perfil del otro usuario si la pasas o la cargas
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _missatgesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Aún no hay mensajes.\n¡Saluda a ${widget.chatName}!",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                      ),
                    ),
                  );
                }

                // Scroll to bottom after messages are built
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                final missatges = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
                  itemCount: missatges.length,
                  itemBuilder: (context, index) {
                    var doc = missatges[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    bool isCurrentUser = data['idAutor'] == currentUserId;

                    Alignment alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
                    Color bubbleColor = isCurrentUser ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer;
                    Color textColor = isCurrentUser ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer;
                    EdgeInsets bubbleMargin = EdgeInsets.symmetric(vertical: 5);

                     if (isCurrentUser) {
                        bubbleMargin = const EdgeInsets.only(left: 70, top: 5, bottom: 5, right: 0);
                      } else {
                        bubbleMargin = const EdgeInsets.only(right: 70, top: 5, bottom: 5, left: 0);
                      }


                    return Align(
                      alignment: alignment,
                      child: Container(
                        margin: bubbleMargin,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                           borderRadius: BorderRadius.only(
                             topLeft: const Radius.circular(18),
                             topRight: const Radius.circular(18),
                             bottomLeft: isCurrentUser ? const Radius.circular(18) : const Radius.circular(6),
                             bottomRight: isCurrentUser ? const Radius.circular(6) : const Radius.circular(18),
                          ),
                          boxShadow: [
                             BoxShadow(
                               offset: const Offset(0,1.5),
                               blurRadius: 1.5,
                               color: Colors.black.withOpacity(0.06)
                             )
                           ]
                        ),
                        child: Text(
                          data['missatge'] ?? '[Mensaje vacío]',
                           style: theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.3) ?? TextStyle(color: textColor, fontSize: 15.5, height: 1.3)
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