import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SizedBox(
          width: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20.0,
            children: <Widget>[
              TextField(decoration: InputDecoration(labelText: "Username")),
              TextField(
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              Column(
                spacing: 5.0,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the second screen
                      Navigator.pushNamed(context, '/second');
                    },
                    child: const Text('Log in'),
                  ),
                  Text("No account?"),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the second screen
                      Navigator.pushNamed(context, '/second');
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
