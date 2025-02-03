import 'package:brainibot/Pages/Sign%20in.dart';
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/Widgets/Authform.dart';
import 'package:flutter/material.dart';


class LogInPage extends StatelessWidget {
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
                    onSubmit: () {
                     Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Starter(),
                        ),
                      );
                    },
                    imagePath: "lib/images/brainibot.png", // Optional: Add an image
                  ),
                  SizedBox(height: 16), // Space between the form and the message
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
                        onTap: () {
                          // Navigate to the SignInPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign In',
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