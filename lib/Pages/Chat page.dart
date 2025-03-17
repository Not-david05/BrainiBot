import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/chat/servei_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ServeiChat _serveiChat = ServeiChat();
  late Stream<QuerySnapshot> _missatgesStream;
  final ScrollController _scrollController = ScrollController();

  String? currentChatId;
  String currentChatName = "";

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// Inicializa el chat: si no hay chats se crea uno por defecto ("chat 1")
  void _initializeChat() async {
    String idUsuariActual = ServeiAuth().getUsuariActual()!.uid;
    CollectionReference chatsCollection = FirebaseFirestore.instance
        .collection("UsersChat")
        .doc(idUsuariActual)
        .collection("Chats");

    QuerySnapshot snapshot = await chatsCollection.get();
    if (snapshot.docs.isEmpty) {
      // No hay chats, crear el chat por defecto
      String newChatId = await _serveiChat.createChat(null);
      setState(() {
        currentChatId = newChatId;
        currentChatName = "chat 1";
        _missatgesStream = _serveiChat.getMissatges(currentChatId!);
      });
    } else {
      // Se selecciona el primer chat existente
      var firstChat = snapshot.docs.first;
      setState(() {
        currentChatId = firstChat.id;
        currentChatName = firstChat.get("name");
        _missatgesStream = _serveiChat.getMissatges(currentChatId!);
      });
    }

    // Se desplaza el scroll hacia abajo luego de renderizar la UI.
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
    if (message.isNotEmpty && currentChatId != null) {
      await _serveiChat.enviarMissatge(currentChatId!, message);
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 500), () {
        _ferScrollCapAvall();
      });
    }
  }

  /// Cambia el chat actual al seleccionado en el Drawer.
  void _switchChat(String chatId, String chatName) {
    setState(() {
      currentChatId = chatId;
      currentChatName = chatName;
      _missatgesStream = _serveiChat.getMissatges(currentChatId!);
    });
    Navigator.pop(context); // Cierra el Drawer.
  }

  /// Muestra un diálogo para crear un nuevo chat.
  void _showCreateChatDialog() {
    TextEditingController chatNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Crear Nuevo Chat"),
          content: TextField(
            controller: chatNameController,
            decoration: InputDecoration(hintText: "Nombre del chat"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                String nameInput = chatNameController.text;
                String newChatId = await _serveiChat.createChat(nameInput);
                // Se obtiene el nombre asignado del nuevo chat.
                DocumentSnapshot newChatDoc = await FirebaseFirestore.instance
                    .collection("UsersChat")
                    .doc(ServeiAuth().getUsuariActual()!.uid)
                    .collection("Chats")
                    .doc(newChatId)
                    .get();
                String newChatName = newChatDoc.get("name");
                setState(() {
                  currentChatId = newChatId;
                  currentChatName = newChatName;
                  _missatgesStream = _serveiChat.getMissatges(currentChatId!);
                });
              },
              child: Text("Crear"),
            ),
          ],
        );
      },
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

  /// Drawer que muestra la lista de chats y un botón fijo para crear uno nuevo.
  Widget _buildChatDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Text("Chats", style: TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _serveiChat.getChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No hay chats."));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var chatData =
                        snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    String chatId = snapshot.data!.docs[index].id;
                    String chatName = chatData["name"];
                    return ListTile(
                      title: Text(chatName),
                      selected: chatId == currentChatId,
                      onTap: () {
                        _switchChat(chatId, chatName);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _showCreateChatDialog,
              child: Text("Nuevo Chat"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildChatDrawer(),
      backgroundColor: Color(0xFFF4EAF8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4EAF8),
        elevation: 0,
        title: Text(currentChatName, style: TextStyle(color: Colors.black)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.help_outline, color: Colors.black), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          IconButton(icon: Icon(Icons.settings, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: currentChatId == null
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
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

                      String idUsuariActual = ServeiAuth().getUsuariActual()!.uid;

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.0),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var missatgeData =
                              snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          bool isCurrentUser = missatgeData["idAutor"] == idUsuariActual;

                          return Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.purple.shade200
                                    : Colors.grey.shade300,
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
}
