import 'package:flutter/material.dart';

class QACard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? surfaceTintColor;
  final Color? shadowColor;

  const QACard({
    super.key,
    this.color,
    this.surfaceTintColor,
    this.shadowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 300.0,
            minHeight: 200.0,
            maxWidth: 900.0,
          ),
          child: child,
        ),
      ),
    );
  }
}
