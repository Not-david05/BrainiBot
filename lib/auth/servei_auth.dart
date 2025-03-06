import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServeiAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //Usuari actual
  User? getUsuariActual() {
    return _auth.currentUser;
  }

  //Fer logout
  Future<void> ferLogout() async {
    return await _auth.signOut();
  }

  //Fer login
  Future<String?> loginAmbEmaiIPassword(String email, password) async {
    try {
      UserCredential credencialUsuari = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // comprobem si l'usuari ja esta donat d'alta a firestore (a FirebaseAuth, si hem arribat
      //aqui ja sabem que hi es). Si no estigues donat d'alta el donem
      // d'alta (a firestore).Fet per si de cas es dibes d'alta un usuari
      // directament des de la consola de firebase i no a traves de la nostra app
      final QuerySnapshot querySnapshot = await _firestore
          .collection("Usuaris")
          .where("Email", isEqualTo: email)
          .get();
      _firestore.collection("Usuaris").doc(credencialUsuari.user!.uid).set({
        "uid": credencialUsuari.user!.uid,
        "email": email,
        "nom": "",
      });
      if (querySnapshot.docs.isEmpty) {
        _firestore.collection("Usuaris").doc(credencialUsuari.user!.uid).set({
          "uid": credencialUsuari.user!.uid,
          "email": email,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return "Error: ${e.message}";
    }
  }

  //Fer registre
 Future<String?> resgitreAmbEmaiIPassword(String email, String password) async {
  try {
    UserCredential credencialUsuari = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Verificar si el usuario no es nulo
    if (credencialUsuari.user != null) {
      print("Usuari creat amb èxit: ${credencialUsuari.user!.uid}");
      await _firestore.collection("Usuaris").doc(credencialUsuari.user!.uid).set({
        "uid": credencialUsuari.user!.uid,
        "email": email,
        "nom": "",
      });
    } else {
      print("Error: No s'ha pogut obtenir l'usuari després del registre.");
      return "Error: No s'ha pogut obtenir l'usuari després del registre.";
    }

    return null;
  } on FirebaseAuthException catch (e) {
    print("Error de FirebaseAuth: ${e.code} - ${e.message}");
    switch (e.code) {
      case "email-already-in-use":
        return "Ja hi ha un usuari amb aquest email.";
      case "invalid-email":
        return "Email no vàlid.";
      case "operation-not-allowed":
        return "Email i/o password no habilitats.";
      case "weak-password":
        return "Cal un password més robust.";
      default:
        return "Error ${e.message}";
    }
  } catch (e) {
    print("Error inesperat: $e");
    return "Error inesperat: $e";
  }
}
}
