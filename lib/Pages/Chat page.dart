 // Ajusta si el nombre/ruta es diferente
import 'package:brainibot/Pages/User%20page.dart';
import 'package:brainibot/Widgets/custom_bottom_nav_bar.dart';
import 'package:brainibot/Widgets/task_manager_screen.dart';// Ajusta si la ruta es diferente
 // Ajusta si el nombre/ruta es diferente
import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/chat/servei_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:brainibot/Pages/editar_dades.dart'; // Para el PopupMenuButton

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ServeiChat _serveiChat = ServeiChat();
  Stream<QuerySnapshot> _missatgesStream = Stream.empty();
  final ScrollController _scrollController = ScrollController();

  String? currentChatId;
  String currentChatName = "Cargando...";
  bool _isCallingFunction = false;

  final HttpsCallable _generateResponseCallable = FirebaseFunctions.instanceFor(region: 'us-central1')
                                                       .httpsCallable('generateOpenAIResponse');

  final int _currentIndexInBottomNav = 2;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() async {
    try {
      String? idUsuariActual = ServeiAuth().getUsuariActual()?.uid;
      if (idUsuariActual == null) {
         if (mounted) setState(() { currentChatName = "Error de autenticación"; });
         return;
      }
      CollectionReference chatsCollection = FirebaseFirestore.instance.collection("UsersChat").doc(idUsuariActual).collection("Chats");
      QuerySnapshot snapshot = await chatsCollection.orderBy("createdAt", descending: true).limit(1).get();
      String targetChatId;
      String targetChatNameValue;
      if (snapshot.docs.isEmpty) {
        targetChatId = await _serveiChat.createChat(null);
         DocumentSnapshot newChatDoc = await chatsCollection.doc(targetChatId).get();
         targetChatNameValue = newChatDoc.exists && newChatDoc.data() != null ? (newChatDoc.data() as Map<String, dynamic>)['name'] ?? "Nuevo Chat" : "Nuevo Chat";
      } else {
        var firstChat = snapshot.docs.first;
        targetChatId = firstChat.id;
        targetChatNameValue = (firstChat.data() as Map<String, dynamic>?)?['name'] ?? 'Chat';
      }
       if (mounted) {
          setState(() { currentChatId = targetChatId; currentChatName = targetChatNameValue; _missatgesStream = _serveiChat.getMissatges(currentChatId!); });
           WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToBottom(durationMillis: 500); });
       }
    } catch (e) {
       if (mounted) setState(() { currentChatName = "Error al cargar"; });
    }
  }

  void _scrollToBottom({int durationMillis = 300}) {
    if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
       Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
             _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: durationMillis), curve: Curves.easeOut);
          }
       });
    }
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty && currentChatId != null && !_isCallingFunction) {
      String messageToSend = message; String chatIdForFunction = currentChatId!;
      if(mounted) { setState(() { _isCallingFunction = true; _controller.clear(); });}
      try {
        await _serveiChat.enviarMissatge(chatIdForFunction, messageToSend);
        await _generateResponseCallable.call(<String, dynamic>{ 'chatId': chatIdForFunction, 'message': messageToSend, });
      } on FirebaseFunctionsException catch (e) {
         if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Asistente: ${e.message}'))); }
      } catch (e) {
         if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'))); }
      } finally {
          if (mounted) { setState(() { _isCallingFunction = false; });}
      }
    } else if (_isCallingFunction) {
       if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Esperando respuesta...'), duration: Duration(seconds: 2)));}
    }
  }

  void _switchChat(String chatId, String chatNameValue) {
     if (chatId == currentChatId) { if (Navigator.canPop(context)) Navigator.pop(context); return; }
    if (mounted){
      setState(() { currentChatId = chatId; currentChatName = chatNameValue; _missatgesStream = _serveiChat.getMissatges(currentChatId!); _isCallingFunction = false; });
      if (Navigator.canPop(context)) Navigator.pop(context);
      WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToBottom(durationMillis: 100); });
    } else { if (Navigator.canPop(context)) Navigator.pop(context); }
  }

  void _showCreateChatDialog() {
    TextEditingController chatNameController = TextEditingController();
    showDialog(context: context, builder: (contextDialog) {
        return AlertDialog(title: Text("Crear Nuevo Chat"), content: TextField( controller: chatNameController, decoration: InputDecoration(hintText: "Nombre del chat (opcional)"), textCapitalization: TextCapitalization.sentences,),
          actions: [ TextButton(onPressed: () => Navigator.pop(contextDialog), child: Text("Cancelar")),
            TextButton(onPressed: () async { Navigator.pop(contextDialog); String? nameInput = chatNameController.text.trim(); if (nameInput.isEmpty) nameInput = null;
                try { String? userId = ServeiAuth().getUsuariActual()?.uid; if (userId == null) throw Exception("Usuario no autenticado");
                   String newChatId = await _serveiChat.createChat(nameInput);
                   DocumentSnapshot newChatDoc = await FirebaseFirestore.instance.collection("UsersChat").doc(userId).collection("Chats").doc(newChatId).get();
                   String newChatNameValue = "Nuevo Chat"; if (newChatDoc.exists && newChatDoc.data() != null) { newChatNameValue = (newChatDoc.data() as Map<String, dynamic>)['name'] ?? newChatNameValue;}
                   _switchChat(newChatId, newChatNameValue);
                 } catch (e) { if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear chat: ${e.toString()}'))); }}
              }, child: Text("Crear"),),
          ],);},);
  }

  Widget _buildChatDrawer() {
    return Drawer(child: Column(children: [ DrawerHeader(decoration: BoxDecoration(color: Colors.purple.shade50.withOpacity(0.7)), child: Center(child: Text("Mis Chats", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple.shade700,),),),),
          Expanded(child: StreamBuilder<QuerySnapshot>(stream: _serveiChat.getChats(), builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error al cargar chats."));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("No tienes chats aún.\n¡Crea uno nuevo para empezar!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600),),));
                return ListView.separated(itemCount: snapshot.data!.docs.length, separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16), itemBuilder: (context, index) {
                    DocumentSnapshot chatDoc = snapshot.data!.docs[index]; Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>? ?? {}; String chatId = chatDoc.id; String chatNameValue = chatData["name"] ?? "Sin nombre";
                    return ListTile(title: Text(chatNameValue, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w500)), selected: chatId == currentChatId, selectedTileColor: Colors.purple.withOpacity(0.1), leading: Icon(Icons.chat_bubble_outline, color: chatId == currentChatId ? Colors.purple.shade600 : Colors.grey.shade500, size: 22),
                      trailing: IconButton( icon: Icon(Icons.delete_outline, color: Colors.grey.shade500, size: 22), tooltip: "Eliminar chat",
                        onPressed: () async {
                          bool confirmDelete = await showDialog<bool>(context: context, builder: (BuildContext dialogContext) { return AlertDialog( title: Text('Eliminar Chat'), content: Text('¿Seguro que quieres eliminar "$chatNameValue"?'), actions: <Widget>[ TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('Cancelar')), TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('Eliminar', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold))),],);},) ?? false;
                          if (confirmDelete) {
                            final scaffoldState = Scaffold.maybeOf(context); if (scaffoldState?.isDrawerOpen ?? false) { Navigator.of(context).pop();}
                             try { await _serveiChat.deleteChat(chatId);
                                if (chatId == currentChatId) { if (mounted) { setState(() { currentChatId = null; currentChatName = "Cargando..."; _missatgesStream = Stream.empty(); }); _initializeChat();}}
                                else { if (mounted) {ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Chat "$chatNameValue" eliminado.')));}}
                             } catch (e) { if (mounted) {ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Error al eliminar.')));}}
                          }
                        },), onTap: () { _switchChat(chatId, chatNameValue); },);},);},),),
          Divider(height: 1), Padding(padding: const EdgeInsets.all(12.0), child: ElevatedButton.icon(icon: Icon(Icons.add_comment_outlined, size: 20), label: Text("Nuevo Chat", style: TextStyle(fontSize: 15)), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade500, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 2,), onPressed: _showCreateChatDialog,),),
        ],),);
  }

  Widget _buildMessageInput() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [ BoxShadow(offset: Offset(0,-1), blurRadius: 3, color: Colors.black.withOpacity(0.04)) ]),
      child: Row(children: [ Expanded(child: TextField(controller: _controller, enabled: !_isCallingFunction, decoration: InputDecoration(hintText: _isCallingFunction ? "Generando respuesta..." : "Escribe tu mensaje...", filled: true, fillColor: _isCallingFunction ? Colors.grey.shade200 : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.purple.shade300, width: 1.5)), contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),), textCapitalization: TextCapitalization.sentences, onSubmitted: _isCallingFunction ? null : (_) => _sendMessage(),),),
          SizedBox(width: 10), _isCallingFunction ? Container(width: 44, height: 44, padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade500)),)
             : IconButton(icon: Icon(Icons.send_rounded), iconSize: 26, style: IconButton.styleFrom(backgroundColor: Colors.purple.shade500, foregroundColor: Colors.white, padding: EdgeInsets.all(10),), onPressed: _sendMessage, tooltip: "Enviar mensaje",),
        ],),);
  }

  void _onBottomNavItemTapped(int index) {
    if (_currentIndexInBottomNav == index && index == 2) return;
    switch (index) {
      case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => User_page())); break;
      case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TaskManagerScreen())); break;
      case 2: if (ModalRoute.of(context)?.settings.name != '/chat') { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatPage()));} break;
    }
  }

  // Funciones para el PopupMenu (necesarias si no usamos CustomAppBar completa aquí)
  Future<void> _performSignOut(BuildContext passedContext) async {
    try {
      await ServeiAuth().ferLogout();
      print("Sesión cerrada desde ChatPage");
      // Opcional: Navegar a login
      // Navigator.of(passedContext).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => LoginPage()), (route) => false);
    } catch (e) {
      print("Error al cerrar sesión desde ChatPage: $e");
       if (mounted && ScaffoldMessenger.of(passedContext).mounted) {
        ScaffoldMessenger.of(passedContext).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión: $e"))
        );
      }
    }
  }

  void _performEditProfile(BuildContext passedContext) {
    Navigator.push(
      passedContext,
      MaterialPageRoute(builder: (context) => EditarDades()),
    ).then((_) {
      // Lógica de recarga si es necesario
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildChatDrawer(),
      backgroundColor: Color(0xFFFBF7FF),
      appBar: AppBar( // AppBar estándar de Flutter
        backgroundColor: Color(0xFFF4EAF8), // Color de fondo
        elevation: 0, // Sin sombra
        title: Text(
          currentChatName,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        // Leading para abrir el Drawer (funciona porque está en el mismo Scaffold)
        leading: Builder(
          builder: (BuildContext scaffoldContext) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              tooltip: "Abrir menú de chats",
              onPressed: () {
                Scaffold.of(scaffoldContext).openDrawer();
              },
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            tooltip: "Opciones",
            onSelected: (value) {
              // Usar el 'context' del build principal de _ChatPageState para las acciones
              if (value == 'logout') {
                _performSignOut(context);
              } else if (value == 'editar') {
                _performEditProfile(context);
              }
            },
            itemBuilder: (BuildContext popupContext) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'editar',
                child: Text('Editar perfil'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
          SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: currentChatId == null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Cargando chat...", style: TextStyle(fontSize: 16, color: Colors.grey.shade700))]))
                : StreamBuilder<QuerySnapshot>(
                    stream: _missatgesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text("Error al cargar los mensajes.", style: TextStyle(color: Colors.red.shade700)));
                      WidgetsBinding.instance.addPostFrameCallback((_) { if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) { _scrollToBottom(); }});
                      if (!snapshot.hasData || snapshot.data == null) { if(snapshot.connectionState == ConnectionState.waiting){ return const Center(child: CircularProgressIndicator());} return Center(child: Text("Cargando mensajes...", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)));}
                      if (snapshot.data!.docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Aún no hay mensajes.\n¡Empieza la conversación!", textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.grey.shade700, height: 1.5))));
                      
                      String? idUsuariActual = ServeiAuth().getUsuariActual()?.uid;
                      const String botId = "HF_Mistral_Bot";
                      const String botErrorId = "HF_Mistral_Error";

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index]; Map<String, dynamic> missatgeData = doc.data() as Map<String, dynamic>? ?? {}; String autorId = missatgeData["idAutor"] ?? ""; String missatgeText = missatgeData["missatge"] ?? "[Mensaje vacío]";
                          bool isCurrentUser = (idUsuariActual != null && autorId == idUsuariActual); bool isBot = autorId == botId; bool isBotError = autorId == botErrorId;
                          Alignment alignment; Color bubbleColor; Color textColor; EdgeInsets bubbleMargin = EdgeInsets.symmetric(vertical: 5);

                          if (isCurrentUser) {
                            alignment = Alignment.centerRight; bubbleColor = Colors.purple.shade400; textColor = Colors.white;
                            bubbleMargin = EdgeInsets.only(left: 70, top: 5, bottom: 5, right: 0);
                          } else if (isBot) {
                            alignment = Alignment.centerLeft; bubbleColor = Color(0xFFECEFF1); textColor = Colors.black87;
                            bubbleMargin = EdgeInsets.only(right: 70, top: 5, bottom: 5, left: 0);
                          } else if (isBotError) {
                            alignment = Alignment.centerLeft; bubbleColor = Colors.red.shade50; textColor = Colors.red.shade800;
                            bubbleMargin = EdgeInsets.only(right: 70, top: 5, bottom: 5, left: 0);
                          } else {
                            alignment = Alignment.center; bubbleColor = Colors.blueGrey.shade50; textColor = Colors.blueGrey.shade700;
                            bubbleMargin = EdgeInsets.symmetric(horizontal: 40, vertical: 8);
                          }

                          return Align(
                            alignment: alignment,
                            child: Container(
                              margin: bubbleMargin,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.only(
                                   topLeft: Radius.circular(18), topRight: Radius.circular(18),
                                   bottomLeft: isCurrentUser ? Radius.circular(18) : Radius.circular(6),
                                   bottomRight: isCurrentUser ? Radius.circular(6) : Radius.circular(18),
                                ),
                                 boxShadow: [ BoxShadow(offset: Offset(0,1.5), blurRadius: 2.5, color: Colors.black.withOpacity(0.08)) ]
                              ),
                              child: Text(missatgeText, style: TextStyle( color: textColor, fontSize: 15.5, height: 1.3)),
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndexInBottomNav,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }
}