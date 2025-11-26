import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/qa_card.dart';
import 'package:lekturai_front/widgets/text_or_loading.dart';

class QuestionAnswerContainer extends StatefulWidget {
  final String? questionTitle;
  final String? questionText;
  final String? answerText;
  final String? evaluationTitle;
  final String? evaluationText;
  final bool questionInitiallyLoading;
  final bool evalInitiallyLoading;
  const QuestionAnswerContainer({
    super.key,
    this.questionTitle,
    this.questionText,
    this.answerText,
    this.evaluationTitle,
    this.evaluationText,
    this.questionInitiallyLoading = true,
    this.evalInitiallyLoading = true,
  });

  @override
  State<StatefulWidget> createState() {
    return QAState();
  }
}

class QAState extends State<QuestionAnswerContainer> {
  String? questionTitle;
  String? questionText;
  String? answerText;
  String? evaluationTitle;
  String? evaluationText;
  bool questionTitleLoading = true;
  bool evalTitleLoading = true;
  bool questionTextLoading = true;
  bool evalTextLoading = true;

  final TextEditingController answerInput = TextEditingController();

  void setAnswer(String newAnswer) {
    setState(() {
      answerText = newAnswer;
      evaluationTitle = "test";
    });
  }

  @override
  void initState() {
    questionText = widget.questionText;
    questionTitle = widget.questionTitle;
    answerText = widget.answerText;
    evaluationTitle = widget.evaluationTitle;
    evaluationText = widget.evaluationText;
    questionTitleLoading = widget.questionInitiallyLoading;
    questionTextLoading = widget.questionInitiallyLoading;
    evalTitleLoading = widget.evalInitiallyLoading;
    evalTextLoading = widget.evalInitiallyLoading;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        cardTheme: CardThemeData(
          margin: EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: IntrinsicWidth(
          child: Column(
            children: [
              QACard(
                child: Column(
                  children: [
                    TextOrLoading(
                      text: questionTitle ?? "",
                      finished: !questionTitleLoading,
                    ),
                    TextOrLoading(
                      text: questionText,
                      finished: !questionTextLoading,
                    ),
                  ],
                ),
              ),
              answerText != null
                  ? QACard(color: Colors.cyan, child: Text(answerText!))
                  : QACard(
                      //"disappears" the card
                      color: Theme.of(context).canvasColor,
                      shadowColor: Theme.of(context).canvasColor,
                      surfaceTintColor: Theme.of(context).canvasColor,
                      child: Center(
                        child: Column(
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                labelText: "Twoja odpowiedź",
                              ),
                              controller: answerInput,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                print(
                                  "user submitted: $answerInput",
                                ); //yes, yes, this is a placeholder func
                                setAnswer(answerInput.text);
                              },
                              child: Text("Submit"),
                            ),
                          ],
                        ),
                      ),
                    ),
              if (evaluationText != null || evaluationTitle != null)
                QACard(
                  color: Colors.deepOrangeAccent,
                  child: Column(
                    children: [
                      TextOrLoading(
                        text: evaluationTitle,
                        finished: !evalTitleLoading,
                      ),
                      TextOrLoading(
                        text: evaluationText,
                        finished: !evalTextLoading,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
