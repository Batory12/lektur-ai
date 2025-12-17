import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';
import 'package:lekturai_front/widgets/question_answer_container.dart';

class ReadingQuestionsScreen extends StatefulWidget {
  final String readingName;
  final int? toChapter;

  const ReadingQuestionsScreen({
    super.key,
    required this.readingName,
    this.toChapter,
  });

  @override
  State<ReadingQuestionsScreen> createState() => _ReadingQuestionsScreenState();
}

class _ReadingQuestionsScreenState extends State<ReadingQuestionsScreen> {
  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Zadanie z matury",
      showDrawer: true,
      body: SingleChildScrollView(
        child: QuestionAnswerContainer(
          isMatura: false,
          readingName: widget.readingName,
          toChapter: widget.toChapter,
        ),
      ),
    );
  }
}
