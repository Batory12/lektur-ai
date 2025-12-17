import 'dart:convert';

import 'package:lekturai_front/api/api_config.dart';
import 'package:http/http.dart' as http;

class HistoryQuestion {
  final String type;
  final String question;
  final String answer;
  final String eval;
  final int points;
  final DateTime date;
  final String? id;

  HistoryQuestion({
    required this.type,
    required this.question,
    required this.answer,
    required this.eval,
    required this.date,
    required this.points,
    this.id,
  });

  factory HistoryQuestion.fromJson(Map<String, dynamic> json) {
    return HistoryQuestion(
      type: json["type"],
      question: json['question'],
      answer: json["response"],
      eval: json["eval"],
      points: json["points"],
      date: DateTime.parse(json["date"]),
      id: json["id"],
    );
  }
}

class HistoryApi {
  Future<List<HistoryQuestion>> getReadingsHistory({
    required String uid,
    String sortBy = "date",
    required int from,
    required int to,
  }) async {
    final url = Uri.parse(
      "${ApiConfig.urlFor(ApiConfig.readingsHistoryEndpoint)}/?user_id=$uid&sort_by=$sortBy&from_=$from&to=$to",
    );
    final headers = {'Content-Type': 'application/json'};

    ApiConfig.logRequest(method: 'GET', url: url.toString(), headers: headers);

    //try {
    final response = await http.get(url, headers: headers);

    ApiConfig.logResponse(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> bodyJson = data;
      List<HistoryQuestion> questions = bodyJson
          .map((item) => HistoryQuestion.fromJson(item as Map<String, dynamic>))
          .toList();
      return questions;
    } else {
      throw Exception('Failed to get exercise: ${response.statusCode}');
    }
    /*} catch (e) {
      rethrow; //TODO for now
    }*/
  }

  //boilerplate
  Future<List<HistoryQuestion>> getMaturaHistory({
    required String uid,
    String sortBy = "date",
    required int from,
    required int to,
  }) async {
    final url = Uri.parse(
      "${ApiConfig.urlFor(ApiConfig.maturaHistoryEndpoint)}/?user_id=$uid&sort_by=$sortBy&from_=$from&to=$to",
    );
    final headers = {'Content-Type': 'application/json'};

    ApiConfig.logRequest(method: 'GET', url: url.toString(), headers: headers);

    try {
      final response = await http.get(url, headers: headers);

      ApiConfig.logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> bodyJson = data;
        List<HistoryQuestion> questions = bodyJson
            .map(
              (item) => HistoryQuestion.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        return questions;
      } else {
        throw Exception('Failed to get exercise: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; //TODO for now
    }
  }
}
