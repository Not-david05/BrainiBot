import 'package:brainibot/Firebase/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminPage());
}

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Usuarios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const UserListPage(),
    );
  }
}

class UserListPage extends StatelessWidget {
  const UserListPage({Key? key}) : super(key: key);

  Stream<QuerySnapshot> getUsersStream() {
    return FirebaseFirestore.instance.collection("Usuaris").snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR (menú lateral)
          Container(
            width: 70,
            color: Colors.pink[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    overlayColor: Colors.pink,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 30),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.people),
                  tooltip: 'Usuarios',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Tareas',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.analytics),
                  tooltip: 'Métricas de uso',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.person),
                  tooltip: 'Modo usuario',
                ),
              ],
            ),
          ),
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.pink[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ENCABEZADO
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: const Text(
                      'Lista de Usuarios',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // LISTA DE USUARIOS DESDE FIRESTORE
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getUsersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No hay usuarios disponibles"));
                        }

                        var users = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var user = users[index];
                            String uid = user.id;
                            String? username = user["nombre"] ?? "Sin nombre";

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[400],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text("Wa"),
                                subtitle: Text("UID: $uid"),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
