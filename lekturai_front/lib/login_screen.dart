import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Login",
      showDrawer: false,
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
                      Navigator.pushNamed(context, '/home');
                    },
                    child: const Text('Log in'),
                  ),
                  Text("No account?"),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the second screen
                      Navigator.pushNamed(context, '/home');
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
