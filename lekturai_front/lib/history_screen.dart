import 'package:flutter/material.dart';
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

  void _onScroll() {
    if (scroller.position.pixels >=
        scroller.position.maxScrollExtent - screenHeight * 2) {
      loadMoreItems(5);
    }
  }

  Future<void> loadMoreItems(int nToLoad) async {
    //TODO: actually load the items from backend
    List<Widget> loaded = [
      QuestionAnswerContainer(
        questionTitle: "Gibberish question",
        questionText: "lkshdgdisuabfisadbkjfbkj",
        answerText: "This is gibberish!",
        evaluationTitle: "Correct!",
        evaluationText:
            "This absolutely is gibberish. It's loading mocked data until I implement actually loading from backend",
        questionInitiallyLoading: false,
        evalInitiallyLoading: false,
        isMatura: false,
      ),
      QuestionAnswerContainer(
        questionTitle: "Gibberish question2",
        questionText: "lkshdgdisuabfisadbkjfbkj",
        answerText: "This is gibberish!",
        evaluationTitle: "Correct!",
        evaluationText:
            "This absolutely is gibberish. It's loading mocked data until I implement actually loading from backend",
        questionInitiallyLoading: false,
        evalInitiallyLoading: false,
        isMatura: false,
      ),
      QuestionAnswerContainer(
        questionTitle: "Gibberish question3",
        questionText: "lkshdgdisuabfisadbkjfbkj",
        answerText: "This is gibberish!",
        evaluationTitle: "Correct!",
        evaluationText:
            "This absolutely is gibberish. It's loading mocked data until I implement actually loading from backend",
        questionInitiallyLoading: false,
        evalInitiallyLoading: false,
        isMatura: false,
      ),
    ];
    setState(() {
      loadedItems.addAll(loaded);
    });
  }

  @override
  void initState() {
    scroller.addListener(_onScroll);
    loadMoreItems(5);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    return CommonScaffold(
      title: 'History',
      body: ListView(controller: scroller, children: loadedItems),
      showDrawer: true,
    );
  }
}
