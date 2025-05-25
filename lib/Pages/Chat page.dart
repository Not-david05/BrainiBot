import 'package:brainibot/Pages/User%20page.dart'; // Renombrado a DashboardScreen en la refactorización anterior
import 'package:brainibot/Widgets/custom_bottom_nav_bar.dart';
import 'package:brainibot/Widgets/task_manager_screen.dart';
import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/chat/servei_chat.dart';
import 'package:brainibot/themes/app_colors.dart'; // Necesario para AppColors.lightUserPageAppBarBg y lightUserPagePrimaryText
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:brainibot/Pages/editar_dades.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

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
       print("Error inicializando chat: $e");
    }
  }

  void _scrollToBottom({int durationMillis = 300}) {
    if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
       Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
             _scrollController.animateTo(
               _scrollController.position.maxScrollExtent, 
               duration: Duration(milliseconds: durationMillis), 
               curve: Curves.easeOut
             );
          }
       });
    }
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    final theme = Theme.of(context); // Obtener el tema para SnackBar

    if (message.isNotEmpty && currentChatId != null && !_isCallingFunction) {
      String messageToSend = message; 
      String chatIdForFunction = currentChatId!;
      
      if(mounted) { setState(() { _isCallingFunction = true; _controller.clear(); });}
      
      try {
        await _serveiChat.enviarMissatge(chatIdForFunction, messageToSend);
        _generateResponseCallable.call<void>(<String, dynamic>{ 
          'chatId': chatIdForFunction, 
          'message': messageToSend, 
        });
      } on FirebaseFunctionsException catch (e) {
         if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Asistente: ${e.message}'), backgroundColor: theme.colorScheme.error)); }
      } catch (e) {
         if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: theme.colorScheme.error)); }
      } finally {
          if (mounted) { setState(() { _isCallingFunction = false; });}
      }
    } else if (_isCallingFunction) {
       if(mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esperando respuesta...'), duration: Duration(seconds: 2)));}
    }
  }

  void _switchChat(String chatId, String chatNameValue) {
     if (chatId == currentChatId) { 
       if (Navigator.canPop(context)) Navigator.pop(context);
       return; 
     }
    if (mounted){
      setState(() { 
        currentChatId = chatId; 
        currentChatName = chatNameValue; 
        _missatgesStream = _serveiChat.getMissatges(currentChatId!); 
        _isCallingFunction = false;
      });
      if (Navigator.canPop(context)) Navigator.pop(context);
      WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToBottom(durationMillis: 100); });
    } else { 
      if (Navigator.canPop(context)) Navigator.pop(context); 
    }
  }

  void _showCreateChatDialog() {
    TextEditingController chatNameController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context, 
      builder: (contextDialog) {
        return AlertDialog(
          title: const Text("Crear Nuevo Chat"), 
          content: TextField( 
            controller: chatNameController, 
            decoration: const InputDecoration(hintText: "Nombre del chat (opcional)"),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [ 
            TextButton(onPressed: () => Navigator.pop(contextDialog), child: const Text("Cancelar")),
            TextButton(
              onPressed: () async { 
                Navigator.pop(contextDialog); 
                String? nameInput = chatNameController.text.trim(); 
                if (nameInput.isEmpty) nameInput = null;
                try { 
                  String? userId = ServeiAuth().getUsuariActual()?.uid; 
                  if (userId == null) throw Exception("Usuario no autenticado");
                   String newChatId = await _serveiChat.createChat(nameInput);
                   DocumentSnapshot newChatDoc = await FirebaseFirestore.instance.collection("UsersChat").doc(userId).collection("Chats").doc(newChatId).get();
                   String newChatNameValue = "Nuevo Chat";
                   if (newChatDoc.exists && newChatDoc.data() != null) { 
                     newChatNameValue = (newChatDoc.data() as Map<String, dynamic>)['name'] ?? newChatNameValue;
                   }
                   _switchChat(newChatId, newChatNameValue);
                 } catch (e) { 
                   if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear chat: ${e.toString()}'), backgroundColor: theme.colorScheme.error)); }
                 }
              }, 
              child: const Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatDrawer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      child: Column(
        children: [ 
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.7)), 
            child: Center(
              child: Text(
                "Mis Chats", 
                style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _serveiChat.getChats(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                if (snapshot.hasError) return Center(child: Text("Error al cargar chats.", style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), 
                      child: Text(
                        "No tienes chats aún.\n¡Crea uno nuevo para empezar!", 
                        textAlign: TextAlign.center, 
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: snapshot.data!.docs.length, 
                  separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor), 
                  itemBuilder: (context, index) {
                    DocumentSnapshot chatDoc = snapshot.data!.docs[index]; 
                    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>? ?? {}; 
                    String chatId = chatDoc.id; 
                    String chatNameValue = chatData["name"] ?? "Sin nombre";
                    bool isSelected = chatId == currentChatId;

                    return ListTile(
                      title: Text(
                        chatNameValue, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: textTheme.titleSmall?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? colorScheme.primary : colorScheme.onSurface)
                      ), 
                      selected: isSelected, 
                      selectedTileColor: colorScheme.primary.withOpacity(0.1), 
                      leading: Icon(
                        Icons.chat_bubble_outline_rounded, 
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant, 
                        size: 22
                      ),
                      trailing: IconButton( 
                        icon: Icon(Icons.delete_outline_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.7), size: 22), 
                        tooltip: "Eliminar chat",
                        onPressed: () async {
                          bool confirmDelete = await showDialog<bool>(
                            context: context, 
                            builder: (BuildContext dialogContext) { 
                              return AlertDialog( 
                                title: Text('Eliminar Chat "$chatNameValue"?'), 
                                content: const Text('Esta acción no se puede deshacer.'), 
                                actions: <Widget>[ 
                                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')), 
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true), 
                                    child: Text('Eliminar', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          ) ?? false;
                          if (confirmDelete) {
                            final scaffoldState = Scaffold.maybeOf(context); 
                            if (scaffoldState?.isDrawerOpen ?? false) { Navigator.of(context).pop();}
                             try { 
                                await _serveiChat.deleteChat(chatId);
                                if (chatId == currentChatId) { 
                                  if (mounted) { 
                                    setState(() { currentChatId = null; currentChatName = "Cargando..."; _missatgesStream = Stream.empty(); }); 
                                    _initializeChat();
                                  }
                                } else { 
                                  if (mounted) {ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Chat "$chatNameValue" eliminado.'), backgroundColor: colorScheme.primary,));}
                                }
                             } catch (e) { 
                               if (mounted) {ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Error al eliminar.'), backgroundColor: colorScheme.error,));}
                             }
                          }
                        },
                      ), 
                      onTap: () { _switchChat(chatId, chatNameValue); },
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, color: theme.dividerColor), 
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_comment_outlined, size: 20), 
              label: const Text("Nuevo Chat", style: TextStyle(fontSize: 15)), 
              onPressed: _showCreateChatDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), 
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, 
        boxShadow: [ 
          BoxShadow(
            offset: const Offset(0,-1), 
            blurRadius: 3, 
            color: theme.shadowColor.withOpacity(0.08) // Usar shadowColor del tema
          ) 
        ]
      ),
      child: Row(
        children: [ 
          Expanded(
            child: TextField(
              controller: _controller, 
              enabled: !_isCallingFunction, 
              decoration: InputDecoration(
                hintText: _isCallingFunction ? "Generando respuesta..." : "Escribe tu mensaje...", 
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ), 
              textCapitalization: TextCapitalization.sentences, 
              onSubmitted: _isCallingFunction ? null : (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10), 
          _isCallingFunction 
            ? Container(
                width: 44, height: 44, 
                padding: const EdgeInsets.all(10), 
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary)),
              )
            : IconButton(
                icon: const Icon(Icons.send_rounded), 
                iconSize: 26, 
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: _sendMessage, 
                tooltip: "Enviar mensaje",
              ),
        ],
      ),
    );
  }

  void _onBottomNavItemTapped(int index) {
    if (_currentIndexInBottomNav == index && index == 2) return;
    switch (index) {
      case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())); break;
      case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TaskManagerScreen())); break; // Añadido const
      case 2: 
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != '/chat') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatPage()));
        }
        break;
    }
  }

  Future<void> _performSignOut(BuildContext passedContext) async {
    final theme = Theme.of(passedContext);
    try {
      await ServeiAuth().ferLogout();
      print("Sesión cerrada desde ChatPage");
    } catch (e) {
      print("Error al cerrar sesión desde ChatPage: $e");
       if (mounted && ScaffoldMessenger.of(passedContext).mounted) {
        ScaffoldMessenger.of(passedContext).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión: $e"), backgroundColor: theme.colorScheme.error)
        );
      }
    }
  }

  void _performEditProfile(BuildContext passedContext) {
    Navigator.push(
      passedContext,
      MaterialPageRoute(builder: (context) => const EditarDades()),
    ).then((_) {});
  }


  @override
  Widget build(BuildContext context) {
    final themeGlobal = Theme.of(context); // Tema global para el Scaffold y widgets internos
    final colorSchemeGlobal = themeGlobal.colorScheme;
    final textThemeGlobal = themeGlobal.textTheme;

    // Tema específico para el AppBar de esta página
    final appBarSpecificTheme = themeGlobal.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightUserPageAppBarBg, // ROSA (igual que brainiBotPink)
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.lightUserPagePrimaryText), // NEGRO para iconos
        actionsIconTheme: const IconThemeData(color: AppColors.lightUserPagePrimaryText), // NEGRO para iconos de acción
        titleTextStyle: textThemeGlobal.titleLarge?.copyWith( // Usar un estilo base del tema global
          color: AppColors.lightUserPagePrimaryText, // NEGRO para el título
          fontWeight: FontWeight.w500, // o bold
        ) ?? const TextStyle( // Fallback si titleLarge es null
          color: AppColors.lightUserPagePrimaryText,
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),
      ),
      // Si el PopupMenuButton dentro de este AppBar específico necesita un estilo diferente:
      popupMenuTheme: themeGlobal.popupMenuTheme.copyWith(
         // Por ejemplo, si el fondo del popup debe ser diferente al del tema global
         // color: AppColors.lightUserPageCardBg, 
         // textStyle: TextStyle(color: AppColors.lightUserPagePrimaryText),
      ),
    );


    return Scaffold(
      backgroundColor: themeGlobal.scaffoldBackgroundColor, // Del tema global
      drawer: _buildChatDrawer(), // _buildChatDrawer ya usa el tema global
      
      // Envolvemos el AppBar con el Theme específico
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Theme(
          data: appBarSpecificTheme, // Aplicamos el tema específico para el AppBar
          child: AppBar(
            // No se necesita backgroundColor, foregroundColor, etc., aquí,
            // ya que se toman del appBarSpecificTheme.
            title: Text(
              currentChatName,
              overflow: TextOverflow.ellipsis,
            ),
            leading: Builder(
              builder: (BuildContext scaffoldContext) { // scaffoldContext tiene el appBarSpecificTheme
                return IconButton(
                  icon: const Icon(Icons.menu), // El color viene del iconTheme del appBarSpecificTheme
                  tooltip: "Abrir menú de chats",
                  onPressed: () {
                    Scaffold.of(scaffoldContext).openDrawer();
                  },
                );
              },
            ),
            actions: [
              PopupMenuButton<String>(
                // El icono toma color del actionsIconTheme del appBarSpecificTheme
                tooltip: "Opciones",
                onSelected: (value) {
                  // Usar el 'context' del build de _ChatPageState para las acciones
                  if (value == 'logout') {
                    _performSignOut(context); 
                  } else if (value == 'editar') {
                    _performEditProfile(context);
                  }
                },
                // El estilo de los items se toma del popupMenuTheme del appBarSpecificTheme
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
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: currentChatId == null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircularProgressIndicator(color: colorSchemeGlobal.primary), 
                    const SizedBox(height: 16), 
                    Text("Cargando chat...", style: textThemeGlobal.titleMedium?.copyWith(color: colorSchemeGlobal.onSurfaceVariant))
                  ]))
                : StreamBuilder<QuerySnapshot>(
                    stream: _missatgesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text("Error al cargar los mensajes.", style: textThemeGlobal.bodyLarge?.copyWith(color: colorSchemeGlobal.error)));
                      
                      if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                         WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToBottom(); });
                      }
                      
                      if (!snapshot.hasData || snapshot.data == null) { 
                        if(snapshot.connectionState == ConnectionState.waiting){ 
                          return Center(child: CircularProgressIndicator(color: colorSchemeGlobal.primary));
                        } 
                        return Center(child: Text("Cargando mensajes...", textAlign: TextAlign.center, style: textThemeGlobal.titleMedium?.copyWith(color: colorSchemeGlobal.onSurfaceVariant)));
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0), 
                            child: Text(
                              "Aún no hay mensajes.\n¡Empieza la conversación!", 
                              textAlign: TextAlign.center, 
                              style: textThemeGlobal.titleLarge?.copyWith(color: colorSchemeGlobal.onSurfaceVariant, height: 1.5)
                            )
                          )
                        );
                      }
                      
                      String? idUsuariActual = ServeiAuth().getUsuariActual()?.uid;
                      const String botId = "HF_Mistral_Bot";
                      const String botErrorId = "HF_Mistral_Error";

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index]; 
                          Map<String, dynamic> missatgeData = doc.data() as Map<String, dynamic>? ?? {}; 
                          String autorId = missatgeData["idAutor"] ?? ""; 
                          String missatgeText = missatgeData["missatge"] ?? "[Mensaje vacío]";
                          
                          bool isCurrentUser = (idUsuariActual != null && autorId == idUsuariActual); 
                          bool isBot = autorId == botId; 
                          bool isBotError = autorId == botErrorId;
                          
                          Alignment alignment; 
                          Color bubbleColor; 
                          Color textColor; 
                          EdgeInsets bubbleMargin = const EdgeInsets.symmetric(vertical: 5);

                          if (isCurrentUser) {
                            alignment = Alignment.centerRight; 
                            bubbleColor = colorSchemeGlobal.primary;
                            textColor = colorSchemeGlobal.onPrimary;
                            bubbleMargin = const EdgeInsets.only(left: 70, top: 5, bottom: 5, right: 0);
                          } else if (isBot) {
                            alignment = Alignment.centerLeft; 
                            bubbleColor = colorSchemeGlobal.surfaceVariant;
                            textColor = colorSchemeGlobal.onSurfaceVariant;
                            bubbleMargin = const EdgeInsets.only(right: 70, top: 5, bottom: 5, left: 0);
                          } else if (isBotError) {
                            alignment = Alignment.centerLeft; 
                            bubbleColor = colorSchemeGlobal.errorContainer;
                            textColor = colorSchemeGlobal.onErrorContainer;
                            bubbleMargin = const EdgeInsets.only(right: 70, top: 5, bottom: 5, left: 0);
                          } else { 
                            alignment = Alignment.center; 
                            bubbleColor = colorSchemeGlobal.secondaryContainer;
                            textColor = colorSchemeGlobal.onSecondaryContainer;
                            bubbleMargin = const EdgeInsets.symmetric(horizontal: 40, vertical: 8);
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
                                missatgeText, 
                                style: textThemeGlobal.bodyMedium?.copyWith(color: textColor, height: 1.3) ?? TextStyle(color: textColor, fontSize: 15.5, height: 1.3)
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          _buildMessageInput(), // _buildMessageInput ya usa el tema global
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar( // CustomBottomNavBar ya está tematizado
        currentIndex: _currentIndexInBottomNav,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }
}