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

class _ReadingQuestionsScreenState extends State<ReadingQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool isBackendProcessing = false;
  bool showNextButton = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -2.5)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
  }

  void _slideOut() {
    _slideController.forward();
    setState(() {
      isBackendProcessing = true;
    });
  }

  void _slideIn() {
    _slideController.reverse();
    setState(() {
      showNextButton = true;
      isBackendProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Zadanie z lektury",
      showDrawer: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                if (isBackendProcessing)
                  const Center(child: CircularProgressIndicator()),
                SlideTransition(
                  position: _slideAnimation,
                  child: QuestionAnswerContainer(
                    isMatura: false,
                    readingName: widget.readingName,
                    toChapter: widget.toChapter,
                    slideOut: _slideOut,
                    slideIn: _slideIn,
                  ),
                ),
              ],
            ),
            if (showNextButton)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReadingQuestionsScreen(
                        readingName: widget.readingName,
                      ),
                    ),
                  );
                },
                label: Text("Nowe zadanie"),
                icon: Icon(Icons.arrow_forward),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}
