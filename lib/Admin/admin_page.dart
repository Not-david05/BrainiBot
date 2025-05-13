import 'package:brainibot/Firebase/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
//
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

  Future<Map<String, String>> getUserData(String uid) async {
    DocumentSnapshot perfilSnapshot = await FirebaseFirestore.instance
        .collection("Usuaris")
        .doc(uid)
        .collection("Perfil")
        .doc("DatosPersonales")
        .get();

    if (perfilSnapshot.exists) {
      return {
        "nombre": perfilSnapshot["nombre"] ?? "Sin nombre",
        "email": perfilSnapshot["email"] ?? "Sin email",
      };
    }
    return {"nombre": "Sin nombre", "email": "Sin email"};
  }

  void showDeleteDialog(BuildContext context, String uid) {
    int countdown = 5;
    bool canDelete = false;
    late Timer timer;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (!context.mounted) {
                t.cancel();
                return;
              }
              if (countdown > 0) {
                setState(() {
                  countdown--;
                });
              } else {
                t.cancel();
                setState(() {
                  canDelete = true;
                });
              }
            });

            return AlertDialog(
              title: const Text("Eliminar Usuario"),
              content: Text(canDelete
                  ? "¿Estás seguro de que quieres eliminar este usuario?"
                  : "Espera $countdown segundos antes de poder eliminar."),
              actions: [
                TextButton(
                  onPressed: () {
                    timer.cancel();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: canDelete
                      ? () async {
                          await deleteUser(uid);
                          timer.cancel();
                          Navigator.pop(dialogContext);
                        }
                      : null,
                  child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
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
          Expanded(
            child: Container(
              color: Colors.pink[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                            return FutureBuilder<Map<String, String>>(
                              future: getUserData(uid),
                              builder: (context, dataSnapshot) {
                                String nombre = dataSnapshot.data?["nombre"] ?? "Cargando...";
                                String email = dataSnapshot.data?["email"] ?? "Cargando...";

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
                                    title: Text(nombre),
                                    subtitle: Text("Email: $email\nUID: $uid"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => showDeleteDialog(context, uid),
                                    ),
                                  ),
                                );
                              },
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

  Future<void> deleteUser(String uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      // 1️⃣ Eliminar los datos en Firestore
      CollectionReference perfilRef = firestore.collection("Usuaris").doc(uid).collection("Perfil");
      QuerySnapshot perfilSnapshot = await perfilRef.get();
      for (var doc in perfilSnapshot.docs) {
        await doc.reference.delete();
      }
      await firestore.collection("Usuaris").doc(uid).delete();

      // 2️⃣ Eliminar el usuario en Firebase Authentication
      User? userToDelete = await getUserByUid(uid);
      if (userToDelete != null) {
        await userToDelete.delete();
      } else {
        print("Usuario no encontrado en Firebase Auth.");
      }

    } catch (e) {
      print("Error al eliminar usuario: $e");
    }
  }

  Future<User?> getUserByUid(String uid) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    return auth.currentUser?.uid == uid ? auth.currentUser : null;
  }
}
