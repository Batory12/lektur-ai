import 'package:flutter/material.dart';
import 'package:lekturai_front/api/exercise.dart';
import 'package:lekturai_front/services/profile_service.dart';
import 'package:lekturai_front/theme/colors.dart';
import 'package:lekturai_front/theme/text_styles.dart';
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
  final bool isMatura;
  //This is bad, I'll refactor it in fabled "Sometime Later"
  final String? readingName;
  final int? toChapter;
  final VoidCallback? slideOut;
  final VoidCallback? slideIn;

  const QuestionAnswerContainer({
    super.key,
    this.questionTitle,
    this.questionText,
    this.answerText,
    this.evaluationTitle,
    this.evaluationText,
    this.questionInitiallyLoading = true,
    this.evalInitiallyLoading = true,
    required this.isMatura,
    this.readingName,
    this.toChapter,
    this.slideIn,
    this.slideOut,
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
  bool isMatura = true;
  bool questionTitleLoading = true;
  bool evalTitleLoading = true;
  bool questionTextLoading = true;
  bool evalTextLoading = true;
  ExerciseApi api = ExerciseApi();
  String? questionId;
  String? uid;

  //This is bad, I'll refactor it in fabled "Sometime Later"
  String? readingName;
  int? toChapter;
  //This is really bad and needs so much refactoring
  List<AuxilaryRead>? reads;

  final TextEditingController answerInput = TextEditingController();

  Future<void> loadQuestion() async {
    Exercise question = isMatura
        ? await api.getMaturaExercise()
        : await api.getReadingExercise(readingName!, toChapter);
    setState(() {
      questionText = question.text;
      questionTitle = question.title;
      questionTextLoading = false;
      questionTitleLoading = false;
    });
    if (question is MaturaExercise) {
      questionId = question.id;
      reads = question.reads;
    }
  }

  Future<void> setMaturaAnswer(String newAnswer) async {
    if ((isMatura && questionId == null) ||
        questionText == null ||
        questionTitle == null) {
      throw Exception("no question loaded!");
    }
    setState(() {
      answerText = newAnswer;
      evaluationText = "";
    });
    if (isMatura) {
      final submit = MaturaSubmit(answer: newAnswer, id: questionId!);
      final grade = await api.submitMaturaExercise(submit, uid!);
      setState(() {
        evaluationText = grade.feedback;
        evaluationTitle = "Ocena: ${grade.grade}";
        evalTextLoading = false;
        evalTitleLoading = false;
      });
    } else {
      final submit = ReadingExerciseSubmit(
        answer: newAnswer,
        text: questionText!,
        title: questionTitle!,
      );
      final grade = await api.submitReadingExercise(submit, uid!);
      setState(() {
        evaluationText = grade.feedback;
        evaluationTitle = "Ocena: ${grade.grade}";
        evalTextLoading = false;
        evalTitleLoading = false;
      });
    }
    if (widget.slideIn != null) widget.slideIn!();
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
    isMatura = widget.isMatura;
    readingName = widget.readingName;
    toChapter = widget.toChapter;
    uid = ProfileService().currentUser?.uid;
    if (uid == null) {
      throw Exception("user id is null");
    }
    super.initState();
    if (questionText == null) {
      loadQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(textTheme: AppTextStyles.appTextTheme),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Column(
                children: [
                  TextOrLoading(
                    text: questionTitle != null ? "# $questionTitle" : "",
                    finished: !questionTitleLoading,
                  ),
                  TextOrLoading(
                    text: questionText,
                    finished: !questionTextLoading,
                  ),
                ],
              ),
              answerText != null
                  ? QACard(
                      color: AppColors.primaryLight,
                      child: Text(answerText!),
                    )
                  : QACard(
                      //"disappears" the card
                      color: Theme.of(context).canvasColor,
                      shadowColor: Theme.of(context).canvasColor,
                      surfaceTintColor: Theme.of(context).canvasColor,
                      child: Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Twoja odpowiedź",
                                ),
                                controller: answerInput,
                              ),
                            ),
                            Row(
                              children: [
                                if (reads != null && reads!.isNotEmpty)
                                  IconButton(
                                    onPressed: () {
                                      showReadDialog(context, reads!);
                                    },
                                    icon: Icon(Icons.book),
                                  ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setMaturaAnswer(answerInput.text);
                                    if (widget.slideOut != null)
                                      widget.slideOut!();
                                  },
                                  label: Text("Wyślij"),
                                  icon: Icon(Icons.rocket_launch),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              if (evaluationText != null || evaluationTitle != null)
                Column(
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
            ],
          ),
        ),
      ),
    );
  }
}

void showReadDialog(BuildContext context, List<AuxilaryRead> reads) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Wybierz tekst do przeczytania.'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reads.length,
            itemBuilder: (context, index) {
              final read = reads[index];
              return ListTile(
                title: Text(read.title),
                subtitle: Text('autorstwa ${read.author}'),
                onTap: () {
                  Navigator.pop(context); // Close the dialog
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(read.title),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('autorstwa: ${read.author}'),
                              const SizedBox(height: 10),
                              Text(read.text),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Wróć'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wróć'),
          ),
        ],
      );
    },
  );
}
