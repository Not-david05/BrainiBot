import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/Pages/User%20page.dart';
import 'package:brainibot/Widgets/Authform.dart';
import 'package:brainibot/auth/servei_auth.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  final Function()? ferClic;

  const SignInPage({super.key, required this.ferClic});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController tecEmail = TextEditingController();
  final TextEditingController tecPassword = TextEditingController();
  final TextEditingController tecConfPass = TextEditingController();

  Future<void> ferRegistre(BuildContext context, String email, String password, String confPassword) async {
    if (password.isEmpty || email.isEmpty) {
      return;
    }
    if (password != confPassword) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color.fromARGB(255, 250, 183, 159),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text("Error"),
          content: Text("Les contrasenyes no coincideixen."),
        ),
      );
      return;
    }
    String? error = await ServeiAuth().resgitreAmbEmaiIPassword(email, password);
    if (error != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color.fromARGB(255, 250, 183, 159),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text("Error"),
          content: Text(error),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthForm(
                    title: 'Sign up',
                    buttonText: 'Sign up',
                    onSubmit: () => ferRegistre(context, tecEmail.text, tecPassword.text, tecConfPass.text),
                    imagePath: "lib/images/brainibot.png",
                    showRememberMe: true,
                    showConfirmPassword: true,
                    confirmPasswordController: tecConfPass,
                    emailController: tecEmail,
                    passwordController: tecPassword,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ja estas registrat? ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.ferClic,
                        child: Text(
                          'Log in',
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