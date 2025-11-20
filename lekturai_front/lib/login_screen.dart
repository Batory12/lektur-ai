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
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 20.0,
                  children: <Widget>[
                    Text(
                      "Welcome Back",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Username"),
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: "Password"),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    Column(
                      spacing: 10.0,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to the second screen
                            Navigator.pushNamed(context, '/home');
                          },
                          child: const Text('Log in'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to the second screen
                            Navigator.pushNamed(context, '/home');
                          },
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
