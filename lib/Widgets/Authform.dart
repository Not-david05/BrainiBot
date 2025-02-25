import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback onSubmit;
  final String? imagePath;
  final bool showForgotPassword;
  final bool showRememberMe;

  const AuthForm({
    Key? key,
    required this.title,
    required this.buttonText,
    required this.onSubmit,
    this.imagePath,
    this.showForgotPassword = false,
    this.showRememberMe = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool _rememberMe = false;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) // Display image if provided
              Image.asset(
                imagePath!,
                height: 400,
                width: 300,
              ),
            if (imagePath != null) SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
             SizedBox(height: 16),
            if (showRememberMe)
              Row(
                children: [
                  StatefulBuilder(
                    builder: (context, setState) => Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                  ),
                  Text(
                    'Remember me',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color.fromARGB(255, 27, 96, 245),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            if (showForgotPassword) ...[
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Add your forgot password logic here
                },
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


