import 'package:brainibot/Admin/servei_admin.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brainibot/auth/servei_auth.dart';

class AdminListPage extends StatefulWidget {
  @override
  _AdminListPageState createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  final _serveiAdmin = ServeiAdmin();
  final TextEditingController _adminNameController = TextEditingController();

  void _createAdmin() async {
    String adminName = _adminNameController.text.trim();
    await _serveiAdmin.createAdmin(adminName);
    _adminNameController.clear();
    Navigator.pop(context);
  }

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Crear nuevo Admin"),
          content: TextField(
            controller: _adminNameController,
            decoration: InputDecoration(hintText: "Nombre del admin"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: _createAdmin,
              child: Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Administradores"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddAdminDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _serveiAdmin.getAdmins(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hay administradores"));
          }

          var admins = snapshot.data!.docs;

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              var admin = admins[index];
              return ListTile(
                title: Text(admin["name"]),
                subtitle: Text("ID: ${admin.id}"),
              );
            },
          );
        },
      ),
    );
  }
}
