import 'package:flutter/material.dart';
import 'package:lekturai_front/placeholder_screen.dart';
import 'home_screen.dart';
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
        '/home': (context) => const HomeScreen(),
        '/zlektur': (context) => const PlaceholderScreen(),
        '/zmatur': (context) => const PlaceholderScreen(),
        '/rozprawka': (context) => const PlaceholderScreen(),
        '/historia': (context) => const PlaceholderScreen(),
      },
      initialRoute: '/',
    );
  }
}
