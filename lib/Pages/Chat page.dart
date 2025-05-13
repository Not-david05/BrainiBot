import 'package:brainibot/auth/servei_auth.dart';
import 'package:brainibot/chat/servei_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// No necesitas importar dos veces MaterialApp
// import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Asegúrate de tener esta dependencia en pubspec.yaml
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isCallingFunction = false; // Para indicar si se está llamando a la función

  // --- Instancia de Cloud Functions ---
  // Asegúrate de que la región coincida con la de tu función si no es us-central1
  final HttpsCallable _generateResponseCallable = FirebaseFunctions.instanceFor(region: 'us-central1')
                                                       .httpsCallable('generateOpenAIResponse'); // Nombre exacto de tu función

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // --- _initializeChat (SIN CAMBIOS) ---
  void _initializeChat() async {
    try {
      String? idUsuariActual = ServeiAuth().getUsuariActual()?.uid;
      if (idUsuariActual == null) {
         print("Error: No se pudo obtener el ID del usuario actual.");
         if (mounted) {
           setState(() {
             currentChatName = "Error de autenticación";
           });
         }
         return;
      }

      CollectionReference chatsCollection = FirebaseFirestore.instance
          .collection("UsersChat")
          .doc(idUsuariActual)
          .collection("Chats");

      QuerySnapshot snapshot = await chatsCollection.orderBy("createdAt").get();
      String targetChatId;
      String targetChatName;

      if (snapshot.docs.isEmpty) {
        print("No se encontraron chats, creando uno nuevo...");
        targetChatId = await _serveiChat.createChat(null);
         DocumentSnapshot newChatDoc = await chatsCollection.doc(targetChatId).get();
         targetChatName = newChatDoc.exists && newChatDoc.data() != null
             ? (newChatDoc.data() as Map<String, dynamic>)['name'] ?? "Nuevo Chat"
             : "Nuevo Chat";
         print("Nuevo chat creado con ID: $targetChatId y nombre: $targetChatName");

      } else {
        var firstChat = snapshot.docs.first;
        targetChatId = firstChat.id;
        targetChatName = (firstChat.data() as Map<String, dynamic>?)?['name'] ?? 'Chat';
         print("Seleccionado chat existente con ID: $targetChatId y nombre: $targetChatName");
      }

       if (mounted) {
          setState(() {
            currentChatId = targetChatId;
            currentChatName = targetChatName;
            _missatgesStream = _serveiChat.getMissatges(currentChatId!);
          });
           WidgetsBinding.instance.addPostFrameCallback((_) {
             _scrollToBottom(durationMillis: 500);
          });
       }

    } catch (e) {
       print("Error en _initializeChat: $e");
       if (mounted) {
         setState(() {
            currentChatName = "Error al cargar";
         });
       }
    }
  }

  // --- _scrollToBottom (SIN CAMBIOS) ---
  void _scrollToBottom({int durationMillis = 300}) {
    if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
       Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
             _scrollController.animateTo(
               _scrollController.position.maxScrollExtent,
               duration: Duration(milliseconds: durationMillis),
               curve: Curves.easeOut,
             );
          }
       });
    }
  }

  // --- _sendMessage (SIN CAMBIOS RESPECTO A LA LÓGICA DE LLAMADA) ---
  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty && currentChatId != null && !_isCallingFunction) {
      String messageToSend = message;
      String chatIdForFunction = currentChatId!;

      if(mounted) {
        setState(() {
           _isCallingFunction = true; // Indicar que estamos procesando
           _controller.clear(); // Limpiar el input inmediatamente
        });
      }

      try {
        // 1. Enviar el mensaje del usuario a Firestore PRIMERO
        await _serveiChat.enviarMissatge(chatIdForFunction, messageToSend);
        print("Mensaje de usuario enviado a Firestore.");

        // 2. Llamar a la Cloud Function para generar la respuesta del bot
        print("Llamando a la Cloud Function 'generateOpenAIResponse'...");
        final HttpsCallableResult result = await _generateResponseCallable.call(
          <String, dynamic>{
            'chatId': chatIdForFunction,
            'message': messageToSend,
          },
        );
        print("Llamada a Cloud Function completada. Resultado: ${result.data}");
        // La Cloud Function se encarga de guardar la respuesta del bot en Firestore.
        // No necesitamos hacer nada con result.data['response'] aquí,
        // porque el StreamBuilder actualizará la UI cuando el nuevo mensaje del bot aparezca.

      } on FirebaseFunctionsException catch (e) {
        // Error específico de Cloud Functions
        print("Error al llamar a Cloud Function (${e.code}): ${e.message}");
        print("Detalls: ${e.details}");
         if(mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error al contactar al asistente: ${e.message ?? "Error desconocido"}'))
             );
         }
         // La Cloud Function debería haber guardado un mensaje de error en Firestore
         // si el error ocurrió DENTRO de la función. Si el error fue de conexión/permisos
         // antes de ejecutar la función, no habrá mensaje de error del bot.
      } catch (e) {
         // Otros errores (p.ej., al enviar el mensaje del usuario)
         print("Error en _sendMessage: $e");
         if(mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error inesperado al enviar el mensaje: ${e.toString()}'))
             );
         }
      } finally {
         // Asegurarse de resetear el estado de carga incluso si hay error
          if (mounted) {
             setState(() {
                _isCallingFunction = false;
             });
          }
      }
    } else if (_isCallingFunction) {
       print("Esperando respuesta anterior...");
       // Opcional: Mostrar un pequeño aviso
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Esperando respuesta anterior...'), duration: Duration(seconds: 2),)
         );
       }
    }
  }

  // --- _switchChat (SIN CAMBIOS) ---
  void _switchChat(String chatId, String chatName) {
     if (chatId == currentChatId) {
       Navigator.pop(context);
       return;
     }
    if (mounted){
      setState(() {
        currentChatId = chatId;
        currentChatName = chatName;
        _missatgesStream = _serveiChat.getMissatges(currentChatId!);
         _isCallingFunction = false; // Resetear estado al cambiar de chat
      });
      Navigator.pop(context); // Cierra el Drawer solo si el estado se actualizó
      WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(durationMillis: 100);
       });
    } else {
         Navigator.pop(context); // Cierra el drawer aunque no se pueda actualizar estado
    }
  }

  // --- _showCreateChatDialog (SIN CAMBIOS) ---
  void _showCreateChatDialog() {
    TextEditingController chatNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Crear Nuevo Chat"),
          content: TextField(
            controller: chatNameController,
            decoration: InputDecoration(hintText: "Nombre del chat (opcional)"),
             textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                String? nameInput = chatNameController.text.trim();
                if (nameInput.isEmpty) nameInput = null;

                try {
                   String? userId = ServeiAuth().getUsuariActual()?.uid;
                   if (userId == null) throw Exception("Usuario no autenticado");

                   String newChatId = await _serveiChat.createChat(nameInput);
                   DocumentSnapshot newChatDoc = await FirebaseFirestore.instance
                       .collection("UsersChat")
                       .doc(userId)
                       .collection("Chats")
                       .doc(newChatId)
                       .get();

                   String newChatName = "Nuevo Chat";
                   if (newChatDoc.exists && newChatDoc.data() != null) {
                      newChatName = (newChatDoc.data() as Map<String, dynamic>)['name'] ?? newChatName;
                   }

                   _switchChat(newChatId, newChatName);

                 } catch (e) {
                    print("Error al crear chat: $e");
                    if(mounted) { // Comprueba antes de mostrar SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Error al crear el chat: ${e.toString()}'))
                      );
                    }
                 }
              },
              child: Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  // --- _buildChatDrawer (SIN CAMBIOS) ---
  Widget _buildChatDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
            child: Text("Mis Chats", style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColorDark)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _serveiChat.getChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                   print("Error en stream de chats: ${snapshot.error}");
                  return Center(child: Text("Error al cargar chats."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No tienes chats aún.\n¡Crea uno nuevo!"));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot chatDoc = snapshot.data!.docs[index];
                    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>? ?? {};
                    String chatId = chatDoc.id;
                    String chatName = chatData["name"] ?? "Sin nombre";

                    return ListTile(
                      title: Text(chatName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      selected: chatId == currentChatId,
                      selectedTileColor: Colors.purple.withOpacity(0.1),
                      leading: Icon(Icons.chat_bubble_outline, color: chatId == currentChatId ? Colors.purple : Colors.grey),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                        tooltip: "Eliminar chat",
                        onPressed: () async {
                          bool confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Eliminar Chat'),
                                  content: Text('¿Estás seguro de que quieres eliminar "$chatName" y todos sus mensajes permanentemente?'),
                                  actions: <Widget>[
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancelar')),
                                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                                  ],
                                );
                              },
                            ) ?? false;

                          if (confirmDelete) {
                            // Cierra el drawer ANTES de la operación async para evitar problemas de contexto
                            if (Navigator.canPop(context)){
                                Navigator.pop(context);
                            }
                             try {
                                await _serveiChat.deleteChat(chatId);
                                if (chatId == currentChatId) {
                                  print("Chat actual eliminado, reinicializando...");
                                  // Re-inicializa para seleccionar otro chat o crear uno nuevo
                                   if (mounted) {
                                      setState(() {
                                         currentChatId = null; // Forzar estado de carga
                                         currentChatName = "Cargando...";
                                         _missatgesStream = Stream.empty();
                                      });
                                      _initializeChat();
                                   }
                                } else {
                                   // Solo muestra confirmación si no estamos recargando
                                   if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Chat "$chatName" eliminado.'))
                                      );
                                   }
                                }
                             } catch (e) {
                               print("Error al eliminar chat desde drawer: $e");
                               if (mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text('Error al eliminar el chat.'))
                                 );
                               }
                             }
                          }
                        },
                      ),
                      onTap: () {
                        _switchChat(chatId, chatName);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add_comment_outlined),
              label: Text("Nuevo Chat"),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40)),
              onPressed: _showCreateChatDialog,
            ),
          ),
        ],
      ),
    );
  }

  // --- _buildMessageInput (SIN CAMBIOS) ---
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
       decoration: BoxDecoration(
         color: Theme.of(context).cardColor,
         boxShadow: [ BoxShadow(offset: Offset(0,-1), blurRadius: 4, color: Colors.black.withOpacity(0.05)) ]
       ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isCallingFunction, // Deshabilitar mientras carga
              decoration: InputDecoration(
                hintText: _isCallingFunction ? "Generando respuesta..." : "Escribe tu mensaje...",
                filled: true,
                fillColor: _isCallingFunction ? Colors.grey.shade200 : const Color.fromARGB(255, 243, 241, 241),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
               textCapitalization: TextCapitalization.sentences,
               onSubmitted: _isCallingFunction ? null : (_) => _sendMessage(), // No enviar si está cargando
            ),
          ),
          SizedBox(width: 8),
          // Mostrar un indicador de progreso o el botón de enviar
          _isCallingFunction
             ? Container(
                  width: 24, // Tamaño similar al IconButton
                  height: 24,
                  margin: EdgeInsets.all(12), // Margen similar al IconButton
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
             : IconButton(
                  icon: Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _sendMessage, // Ya comprueba _isCallingFunction dentro
                  tooltip: "Enviar mensaje",
             ),
        ],
      ),
    );
  }

  // --- build (MODIFICADO para usar los IDs correctos del bot: HF_Mistral_Bot y HF_Mistral_Error) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildChatDrawer(),
      backgroundColor: Color(0xFFF4EAF8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4EAF8),
        elevation: 0,
        title: Text(
          currentChatName,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            tooltip: "Abrir menú de chats",
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // IconButton(icon: Icon(Icons.help_outline, color: Colors.black), tooltip: "Ayuda", onPressed: () {}), // Opcional
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: currentChatId == null
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       CircularProgressIndicator(),
                       SizedBox(height: 10),
                       Text("Cargando chat...")
                    ],
                 ))
                : StreamBuilder<QuerySnapshot>(
                    stream: _missatgesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print("Error en StreamBuilder de mensajes: ${snapshot.error}");
                        return Center(child: Text("Error al cargar los mensajes."));
                      }

                       // Scroll automático
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                             _scrollToBottom();
                          }
                       });

                      if (!snapshot.hasData || snapshot.data == null) {
                         // Mostrar indicador solo si está realmente esperando datos iniciales
                        if(snapshot.connectionState == ConnectionState.waiting){
                           return const Center(child: CircularProgressIndicator());
                        }
                        // Si no está esperando y no hay datos (raro, podría ser un stream vacío inicial)
                        return Center(child: Text("Cargando mensajes...", textAlign: TextAlign.center,));
                      }

                       if (snapshot.data!.docs.isEmpty) {
                          // El chat existe pero no tiene mensajes
                          return Center(child: Text("Aún no hay mensajes.\n¡Empieza la conversación!", textAlign: TextAlign.center,));
                       }

                      // --- CAMBIO AQUÍ: Usar los IDs correctos de HF_Mistral_Bot ---
                      String? idUsuariActual = ServeiAuth().getUsuariActual()?.uid;
                      // IDs para el bot (deben coincidir EXACTAMENTE con los de index.js)
                      const String botId = "HF_Mistral_Bot";         // <-- ACTUALIZADO
                      const String botErrorId = "HF_Mistral_Error";  // <-- ACTUALIZADO
                      // -------------------------------------------

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.0),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          Map<String, dynamic> missatgeData = doc.data() as Map<String, dynamic>? ?? {};
                          String autorId = missatgeData["idAutor"] ?? "";
                          String missatgeText = missatgeData["missatge"] ?? "[Mensaje vacío]";

                          bool isCurrentUser = (idUsuariActual != null && autorId == idUsuariActual);
                          // Comprobar si es el bot o el mensaje de error del bot
                          bool isBot = autorId == botId; // <-- Usa la constante actualizada
                          bool isBotError = autorId == botErrorId; // <-- Usa la constante actualizada

                          // Lógica de estilos condicionales (SIN CAMBIOS)
                          Alignment alignment;
                          Color bubbleColor;
                          Color textColor;
                          EdgeInsets bubbleMargin = EdgeInsets.symmetric(vertical: 4);

                          if (isCurrentUser) {
                            alignment = Alignment.centerRight;
                            bubbleColor = Colors.purple.shade200;
                            textColor = Colors.white;
                             bubbleMargin = EdgeInsets.only(left: 60, top: 4, bottom: 4, right: 0);
                          } else if (isBot) { // Ahora detectará "HF_Mistral_Bot"
                            alignment = Alignment.centerLeft;
                            bubbleColor = Colors.grey.shade200;
                            textColor = Colors.black87;
                            bubbleMargin = EdgeInsets.only(right: 60, top: 4, bottom: 4, left: 0);
                          } else if (isBotError) { // Ahora detectará "HF_Mistral_Error"
                            alignment = Alignment.centerLeft;
                            bubbleColor = Colors.red.shade100;
                            textColor = Colors.red.shade900;
                             bubbleMargin = EdgeInsets.only(right: 60, top: 4, bottom: 4, left: 0);
                          } else {
                             // Mensajes inesperados (quizás de versiones anteriores o sistema)
                            alignment = Alignment.center;
                            bubbleColor = Colors.blueGrey.shade100;
                            textColor = Colors.black54;
                          }

                          return Align(
                            alignment: alignment,
                            child: Container(
                              margin: bubbleMargin,
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.only(
                                   topLeft: Radius.circular(16), topRight: Radius.circular(16),
                                   bottomLeft: isCurrentUser ? Radius.circular(16) : Radius.circular(4),
                                   bottomRight: isCurrentUser ? Radius.circular(4) : Radius.circular(16),
                                ),
                                 boxShadow: [ BoxShadow(offset: Offset(0,1), blurRadius: 2, color: Colors.black.withOpacity(0.1)) ]
                              ),
                              child: Text(
                                missatgeText,
                                style: TextStyle( color: textColor, fontSize: 15,),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          _buildMessageInput(), // El input modificado
        ],
      ),
    );
  }
}