import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';
import 'package:lekturai_front/widgets/question_answer_container.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool isBackendProcessing = false;

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
      isBackendProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Zadanie z matury",
      showDrawer: true,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            if (isBackendProcessing)
              const Center(child: CircularProgressIndicator()),
            SlideTransition(
              position: _slideAnimation,
              child: QuestionAnswerContainer(
                isMatura: true,
                slideOut: _slideOut,
                slideIn: _slideIn,
              ),
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
