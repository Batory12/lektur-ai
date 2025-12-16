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
  int lastLoaded = 0;
  bool noMoreData = false;
  HistoryApi api = HistoryApi();
  ProfileService profile = ProfileService();
  String? uid;

  void _onScroll() {
    if (!noMoreData &&
        scroller.position.pixels >=
            scroller.position.maxScrollExtent - screenHeight * 2) {
      loadMoreItems(lastLoaded + 1, lastLoaded + 5).then((_) {
        setState(() {});
      });
      lastLoaded += 5;
    }
  }

  Future<void> loadMoreItems(int from, int to) async {
    List<HistoryQuestion> questions = await api.getReadingsHistory(
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
            evalInitiallyLoading: false,
            questionInitiallyLoading: false,
          ),
        )
        .toList();
    loadedItems.addAll(loaded);
    if (loaded.length < to - from) {
      loadedItems.add(Text("No more items to load."));
      noMoreData = true;
    }
  }

  @override
  void initState() {
    scroller.addListener(_onScroll);
    uid = profile.currentUser?.uid;
    if (uid == null) {
      throw Exception("Can't find current user");
    }
    loadMoreItems(0, 5).then((_) {
      setState(() {});
    });
    lastLoaded = 5;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    return CommonScaffold(
      key: ValueKey(loadedItems.length),
      title: 'History',
      body: ListView(controller: scroller, children: loadedItems),
      showDrawer: true,
    );
  }
}
