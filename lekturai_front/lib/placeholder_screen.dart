import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(title: "Placeholder", body: Placeholder());
  }
}
