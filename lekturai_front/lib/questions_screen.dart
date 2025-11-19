import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';
import 'package:lekturai_front/widgets/question_answer_container.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Zadanie z lektury",
      showDrawer: true,
      body: QuestionAnswerContainer(),
    );
  }
}
