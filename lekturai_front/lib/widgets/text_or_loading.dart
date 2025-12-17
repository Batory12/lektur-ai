import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TextOrLoading extends StatelessWidget {
  final String? text;
  final bool finished;

  const TextOrLoading({super.key, this.text, this.finished = false});

  @override
  Widget build(BuildContext context) {
    return text == null
        ? CircularProgressIndicator()
        : MarkdownBody(
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            data: text!,
          );
  }
}
