import 'package:flutter/material.dart';
import 'second_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Define routes
      routes: {
        '/': (context) => const LoginScreen(),
        '/second': (context) => const SecondScreen(),
      },
      initialRoute: '/',
    );
  }
}
