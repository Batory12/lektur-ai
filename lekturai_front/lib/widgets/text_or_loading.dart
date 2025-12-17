import 'package:flutter/material.dart';

class TextOrLoading extends StatelessWidget {
  final String? text;
  final bool finished;

  const TextOrLoading({super.key, this.text, this.finished = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        text: text ?? "",
        children: [
          if (!finished)
            WidgetSpan(
              child: SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
