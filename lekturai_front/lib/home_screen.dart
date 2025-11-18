import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Home',
      body: const Center(child: Text('Placeholder for the home screen')),
      showDrawer: true,
    );
  }
}
