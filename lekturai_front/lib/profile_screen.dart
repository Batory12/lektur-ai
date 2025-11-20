import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/change_password.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const ChangePasswordWidget(),
    );
  }
}