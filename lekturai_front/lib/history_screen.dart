import 'package:flutter/material.dart';
import 'package:lekturai_front/api/history.dart';
import 'package:lekturai_front/services/profile_service.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';
import 'package:lekturai_front/widgets/question_answer_container.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return HistoryScreenState();
  }
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Widget> loadedItems = <Widget>[];
  List<HistoryQuestion> maturas = [];
  List<HistoryQuestion> readings = [];
  final ScrollController scroller = ScrollController();
  double screenHeight = 0.0;
  int lastLoadedReadings = 0;
  int lastLoadedMatura = 0;
  bool noMoreDataM = false;
  bool noMoreDataR = false;
  bool loadingData = false;
  HistoryApi api = HistoryApi();
  ProfileService profile = ProfileService();
  String? uid;
  final int bufferQuestions = 5;

  void _onScroll() {
    if (!loadingData &&
        !(noMoreDataM && noMoreDataR) &&
        scroller.position.pixels >=
            scroller.position.maxScrollExtent - screenHeight * 2) {
      appendNum(5);
    }
  }

  Future<void> appendNum(int num) async {
    loadingData = true;
    for (int i = 0; i < 5; i++) {
      await appendNext();
    }
    loadingData = false;
    setState(() {});
  }

  Future<void> appendNext() async {
    List<Future<List<HistoryQuestion>>> fetches = [];
    List<bool> didFetch = [false, false];
    if (!noMoreDataM && maturas.isEmpty) {
      fetches.add(
        api.getMaturaHistory(
          from: lastLoadedMatura + 1,
          to: lastLoadedMatura + bufferQuestions,
          uid: uid!,
        ),
      );
      didFetch[0] = true;
    }
    if (!noMoreDataR && readings.isEmpty) {
      fetches.add(
        api.getReadingsHistory(
          from: lastLoadedReadings + 1,
          to: lastLoadedReadings + bufferQuestions,
          uid: uid!,
        ),
      );
      didFetch[1] = true;
      lastLoadedReadings += bufferQuestions;
    }
    if (didFetch[0] || didFetch[1]) {
      final gotQuestions = await Future.wait(fetches);
      if (didFetch[0]) {
        if (gotQuestions[0].length < bufferQuestions) {
          noMoreDataM = true;
        }
        maturas.addAll(gotQuestions[0]);
        gotQuestions.removeAt(0);
      }
      if (didFetch[1]) {
        if (gotQuestions[0].length < bufferQuestions) {
          noMoreDataR = true;
        }
        readings.addAll(gotQuestions[0]);
        gotQuestions.removeAt(0);
      }
    }
    if (readings.isEmpty) {
      if (maturas.isNotEmpty) {
        final question = maturas[0];
        loadedItems.add(
          Column(
            children: [
              const Divider(
                height: 40,
                thickness: 1,
                color: Colors.grey,
                indent: 10,
                endIndent: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat("dd-MM-yyyy kk:mm").format(question.date)),
                  question.type == "reading"
                      ? Text("Zadanie z lektur")
                      : Text("Zadanie z matury"),
                ],
              ),
              QuestionAnswerContainer(
                isMatura: true,
                questionText: question.question,
                answerText: question.answer,
                evaluationText: question.eval,
                evaluationTitle: "Ocena: ${question.points}",
                evalInitiallyLoading: false,
                questionInitiallyLoading: false,
              ),
            ],
          ),
        );
        maturas.removeAt(0);
      }
    } else if (maturas.isEmpty) {
      final question = readings[0];
      loadedItems.add(
        Column(
          children: [
            const Divider(
              height: 40,
              thickness: 1,
              color: Colors.grey,
              indent: 10,
              endIndent: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat("dd-MM-yyyy kk:mm").format(question.date)),
                question.type == "reading"
                    ? Text("Zadanie z lektur")
                    : Text("Zadanie z matury"),
              ],
            ),
            QuestionAnswerContainer(
              isMatura: false,
              questionText: question.question,
              answerText: question.answer,
              evaluationText: question.eval,
              evaluationTitle: "Ocena: ${question.points}",
              evalInitiallyLoading: false,
              questionInitiallyLoading: false,
            ),
          ],
        ),
      );
      readings.removeAt(0);
    } else if (readings[0].date.isBefore(maturas[0].date)) {
      final question = readings[0];
      loadedItems.add(
        Column(
          children: [
            const Divider(
              height: 40,
              thickness: 1,
              color: Colors.grey,
              indent: 10,
              endIndent: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat("dd-MM-yyyy kk:mm").format(question.date)),
                question.type == "reading"
                    ? Text("Zadanie z lektur")
                    : Text("Zadanie z matury"),
              ],
            ),
            QuestionAnswerContainer(
              isMatura: false,
              questionText: question.question,
              answerText: question.answer,
              evaluationText: question.eval,
              evaluationTitle: "Ocena: ${question.points}",
              evalInitiallyLoading: false,
              questionInitiallyLoading: false,
            ),
          ],
        ),
      );
      readings.removeAt(0);
    } else {
      final question = maturas[0];
      loadedItems.add(
        Column(
          children: [
            const Divider(
              height: 40,
              thickness: 1,
              color: Colors.grey,
              indent: 10,
              endIndent: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat("dd-MM-yyyy kk:mm").format(question.date)),
                question.type == "reading"
                    ? Text("Zadanie z lektur")
                    : Text("Zadanie z matury"),
              ],
            ),
            QuestionAnswerContainer(
              isMatura: true,
              questionText: question.question,
              answerText: question.answer,
              evaluationText: question.eval,
              evaluationTitle: "Ocena: ${question.points}",
              evalInitiallyLoading: false,
              questionInitiallyLoading: false,
            ),
          ],
        ),
      );
      maturas.removeAt(0);
    }
  }

  @override
  void initState() {
    scroller.addListener(_onScroll);
    uid = profile.currentUser?.uid;
    if (uid == null) {
      throw Exception("Can't find current user");
    }
    appendNum(5);
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
