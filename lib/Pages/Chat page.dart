import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/chat/missatge.dart';
import 'package:brainibot/chat/servei_chat.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ServeiChat _serveiChat = ServeiChat();
  final ServeiAuth _serveiAuth = ServeiAuth();
  late Stream<QuerySnapshot> _missatgesStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _missatgesStream = _serveiChat.getMissatges();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _ferScrollCapAvall();
      });
    });
  }

  void _ferScrollCapAvall() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 40,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      await _serveiChat.enviarMissatge(message);
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 500), () {
        _ferScrollCapAvall();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EAF8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4EAF8),
        elevation: 0,
        title: Text("Chat", style: TextStyle(color: Colors.black)),
        leading: Icon(Icons.account_circle, color: Colors.black),
        actions: [
          IconButton(icon: Icon(Icons.help_outline, color: Colors.black), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          IconButton(icon: Icon(Icons.settings, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _missatgesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No hay mensajes aún."));
                }

                String idUsuariActual = _serveiAuth.getUsuariActual()!.uid;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var missatgeData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isCurrentUser = missatgeData["idAutor"] == idUsuariActual;

                    return Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.purple.shade200 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          missatgeData["missatge"],
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.add), onPressed: () {}),
          IconButton(icon: Icon(Icons.emoji_emotions_outlined), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                filled: true,
                fillColor: const Color.fromARGB(255, 243, 241, 241),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
