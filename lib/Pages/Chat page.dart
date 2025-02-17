import 'package:flutter/material.dart';

class Chat_page extends StatefulWidget {
  @override
  _Chat_pageState createState() => _Chat_pageState();
}

class _Chat_pageState extends State<Chat_page> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      print("Mensaje enviado: $message");
      _controller.clear();
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
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, color: Colors.grey.shade600),
                        SizedBox(width: 8),
                        Text("...", style: TextStyle(color: Colors.grey.shade800)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Text("...", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
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
