import 'package:flutter/material.dart';
import 'package:lekturai_front/api/history.dart';
import 'package:lekturai_front/services/profile_service.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';
import 'package:lekturai_front/widgets/question_answer_container.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return HistoryScreenState();
  }
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Widget> loadedItems = <Widget>[];
  final ScrollController scroller = ScrollController();
  double screenHeight = 0.0;
  int last_loaded = 0;
  HistoryApi api = HistoryApi();
  ProfileService profile = ProfileService();
  String? uid;

  void _onScroll() {
    if (scroller.position.pixels >=
        scroller.position.maxScrollExtent - screenHeight * 2) {
      loadMoreItems(last_loaded + 1, last_loaded + 5);
      last_loaded += 5;
    }
  }

  Future<void> loadMoreItems(int from, int to) async {
    List<HistoryQuestion> questions = await api.getMaturaHistory(
      from: from,
      to: to,
      uid: uid!,
    );
    List<QuestionAnswerContainer> loaded = questions
        .map(
          (question) => QuestionAnswerContainer(
            isMatura: true,
            questionText: question.question,
            answerText: question.answer,
            evaluationText: question.eval,
            evaluationTitle: "${question.points}",
          ),
        )
        .toList();
    setState(() {
      loadedItems.addAll(loaded);
      if (loaded.length < to - from) {
        loadedItems.add(Text("No more items to load."));
      }
    });
  }

  @override
  void initState() {
    scroller.addListener(_onScroll);
    uid = profile.currentUser?.uid;
    if (uid == null) {
      throw Exception("Can't find current user");
    }
    loadMoreItems(0, 5);
    last_loaded = 5;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    return CommonScaffold(
      title: 'History',
      body: ListView(
        controller: scroller,
        children: loadedItems,
        key: ValueKey(loadedItems.length),
      ),
      showDrawer: true,
    );
  }
}
