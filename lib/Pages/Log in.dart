import 'package:brainibot/Pages/Sign%20up.dart';
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/Pages/User%20page.dart';
import 'package:brainibot/Widgets/Authform.dart';
import 'package:brainibot/auth/servei_auth.dart';
import 'package:flutter/material.dart';

class LogInPage extends StatefulWidget {
  final Function()? ferClic;

  const LogInPage({super.key, required this.ferClic});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController tecEmail = TextEditingController();
  final TextEditingController tecPassword = TextEditingController();

  Future<void> ferLogin(BuildContext context, String email, String password) async {
    String? error = await ServeiAuth().loginAmbEmaiIPassword(email, password);
    if (error != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color.fromARGB(255, 250, 183, 159),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text("Error"),
          content: Text("Email i/o password incorrectes."),
        ),
      );
    }
    // No necesitas Navigator.pushReplacement aquí, PortalAuth manejará la navegación.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AuthForm(
                    title: 'Log In',
                    buttonText: 'Log In',
                    onSubmit: () => ferLogin(context, tecEmail.text, tecPassword.text),
                    imagePath: "lib/images/brainibot.png",
                    showForgotPassword: true,
                    emailController: tecEmail,
                    passwordController: tecPassword,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Todavía no estás registrado? ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.ferClic,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}