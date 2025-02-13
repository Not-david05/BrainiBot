
import 'package:brainibot/Pages/Starter.dart';
import 'package:brainibot/Widgets/Authform.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatelessWidget {
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
              child: AuthForm(
                title: 'Sign In',
                buttonText: 'Sign In',
                onSubmit: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Starter(),
                    ),
                  );
                },
                imagePath: "lib/images/brainibot.png",
              ),
            ),
          ),
        ),
      ),
    );
  }
}