import 'dart:convert';

import 'package:lekturai_front/api/api_config.dart';
import 'package:http/http.dart' as http;

abstract class Exercise {
  final String title;
  final String text;

  Exercise({required this.title, required this.text});
}

class MaturaExercise extends Exercise {
  final String id;

  MaturaExercise({required this.id, required super.text, required super.title});

  factory MaturaExercise.fromJson(Map<String, dynamic> json) {
    return MaturaExercise(
      id: json['excercise_id'],
      title: json['excercise_title'],
      text: json['excercise_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'excercise_id': id,
      'excercise_title': title,
      'excercise_text': text,
    };
  }
}

class ReadingExercise extends Exercise {
  ReadingExercise({required super.title, required super.text});

  factory ReadingExercise.fromJson(Map<String, dynamic> json) {
    return ReadingExercise(
      title: json['excercise_title'],
      text: json['excercise_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'excercise_title': title, 'excercise_text': text};
  }
}

class ReadingExerciseSubmit {
  final String title;
  final String text;
  final String answer;

  ReadingExerciseSubmit({
    required this.title,
    required this.text,
    required this.answer,
  });

  factory ReadingExerciseSubmit.fromJson(Map<String, dynamic> json) {
    return ReadingExerciseSubmit(
      title: json['excercise_title'],
      text: json['excercise_text'],
      answer: json['user_answer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'excercise_title': title,
      'excercise_text': text,
      'user_answer': answer,
    };
  }
}

class MaturaSubmit {
  final String id;
  final String answer;

  MaturaSubmit({required this.id, required this.answer});

  Map<String, dynamic> toJson() {
    return {'excercise_id': id, 'user_answer': answer};
  }
}

class ReadingGradeResponse {
  final double grade;
  final String feedback;

  ReadingGradeResponse({required this.grade, required this.feedback});

  factory ReadingGradeResponse.fromJson(Map<String, dynamic> json) {
    return ReadingGradeResponse(
      grade: json['grade'],
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'grade': grade, 'feedback': feedback};
  }
}

class MaturaGradeResponse {
  final String exerciseId;
  final double grade;
  final String feedback;

  MaturaGradeResponse({
    required this.exerciseId,
    required this.grade,
    required this.feedback,
  });

  factory MaturaGradeResponse.fromJson(Map<String, dynamic> json) {
    return MaturaGradeResponse(
      exerciseId: json['excercise_id'],
      grade: json['grade'],
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'grade': grade, 'feedback': feedback, 'excercise_id': exerciseId};
  }
}

class ExerciseApi {
  Future<MaturaExercise> getMaturaExercise() async {
    final url = Uri.parse(ApiConfig.urlFor(ApiConfig.maturaExcerciseEndpoint));
    final headers = {'Content-Type': 'application/json'};

    ApiConfig.logRequest(method: 'GET', url: url.toString(), headers: headers);

    try {
      final response = await http.get(url, headers: headers);

      ApiConfig.logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> bodyJson = data;
        final exercise = MaturaExercise.fromJson(bodyJson);
        return exercise;
      } else {
        throw Exception('Failed to get exercise: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; //TODO for now
    }
  }

  Future<MaturaGradeResponse> submitMaturaExercise(
    MaturaSubmit answer,
    String uid,
  ) async {
    final url = Uri.parse(
      ApiConfig.urlFor(
        "${ApiConfig.maturaExcerciseEndpoint}/${answer.id}?user_id=$uid",
      ),
    );
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(answer.toJson());

    ApiConfig.logRequest(
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: body,
    );

    try {
      final response = await http.post(url, headers: headers, body: body);

      ApiConfig.logResponse(response);
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return MaturaGradeResponse.fromJson(jsonBody);
      } else {
        throw Exception('Failed to get contexts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; //TODO for now
    }
  }

  Future<ReadingExercise> getReadingExercise(
    String name,
    int? toChapter,
  ) async {
    final url = Uri.parse(
      "${ApiConfig.urlFor(ApiConfig.readingExcerciseEndpoint)}/$name${toChapter != null ? "?to_chapter=$toChapter" : ""}",
    );
    final headers = {'Content-Type': 'application/json'};

    ApiConfig.logRequest(method: 'GET', url: url.toString(), headers: headers);

    try {
      final response = await http.get(url, headers: headers);

      ApiConfig.logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> bodyJson = data;
        final exercise = ReadingExercise.fromJson(bodyJson);
        return exercise;
      } else {
        throw Exception('Failed to get exercise: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; //TODO for now
    }
  }

  Future<ReadingGradeResponse> submitReadingExercise(
    ReadingExerciseSubmit answer,
    String uid,
  ) async {
    final url = Uri.parse(
      ApiConfig.urlFor("${ApiConfig.readingExcerciseEndpoint}?user_id=$uid"),
    );
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(answer.toJson());

    ApiConfig.logRequest(
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: body,
    );

    try {
      final response = await http.post(url, headers: headers, body: body);

      ApiConfig.logResponse(response);
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return ReadingGradeResponse.fromJson(jsonBody);
      } else {
        throw Exception('Failed to get contexts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; //TODO for now
    }
  }
}
