import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class Context {
  final String contextType;
  final String contextTitle;
  final String contextDescription;

  Context({
    required this.contextType,
    required this.contextTitle,
    required this.contextDescription,
  });

  factory Context.fromJson(Map<String, dynamic> json) {
    return Context(
      contextType: json['context_type'],
      contextTitle: json['context_title'],
      contextDescription: json['context_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'context_type': contextType,
      'context_title': contextTitle,
      'context_description': contextDescription,
    };
  }
}

class ContextRequest {
  final String contextType;
  final String contextAdditionalDescription;

  ContextRequest({
    required this.contextType,
    required this.contextAdditionalDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'context_type': contextType,
      'context_additional_description': contextAdditionalDescription,
    };
  }
}

class EssayContextsRequest {
  final String title;
  final List<ContextRequest> contexts;

  EssayContextsRequest({
    required this.title,
    required this.contexts,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'contexts': contexts.map((c) => c.toJson()).toList(),
    };
  }
}

class ContextsApi {
  Future<List<Context>> getContexts(EssayContextsRequest request) async {
    final url = Uri.parse(ApiConfig.contextsUrl);
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(request.toJson());
    
    // Log the request
    ApiConfig.logRequest(
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: body,
    );
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Log the response
      ApiConfig.logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> contextsJson = data['contexts'];
        return contextsJson.map((json) => Context.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get contexts: ${response.statusCode}');
      }
    } catch (e) {
      print('=== API ERROR ===');
      print('Error getting contexts: $e');
      print('=================');
      throw Exception('Error getting contexts: $e');
    }
  }

  // Predefined context types based on docs/rozprawka.md
  static const List<String> availableContextTypes = [
    'literacki',
    'historycznoliteracki',
    'teoretycznoliteracki',
    'historyczny',
    'filozoficzny',
    'kulturowy',
    'biograficzny',
    'biblijny',
    'mitologiczny',
    'religijny',
    'egzystencjalny',
    'społeczny',
    'polityczny',
    'artystyczny',
  ];

  static String getContextTypeDisplayName(String contextType) {
    switch (contextType) {
      case 'literacki':
        return 'Kontekst literacki';
      case 'historycznoliteracki':
        return 'Kontekst historycznoliteracki';
      case 'teoretycznoliteracki':
        return 'Kontekst teoretycznoliteracki';
      case 'historyczny':
        return 'Kontekst historyczny';
      case 'filozoficzny':
        return 'Kontekst filozoficzny';
      case 'kulturowy':
        return 'Kontekst kulturowy';
      case 'biograficzny':
        return 'Kontekst biograficzny';
      case 'biblijny':
        return 'Kontekst biblijny';
      case 'mitologiczny':
        return 'Kontekst mitologiczny';
      case 'religijny':
        return 'Kontekst religijny';
      case 'egzystencjalny':
        return 'Kontekst egzystencjalny';
      case 'społeczny':
        return 'Kontekst społeczny';
      case 'polityczny':
        return 'Kontekst polityczny';
      case 'artystyczny':
        return 'Kontekst artystyczny';
      default:
        return contextType;
    }
  }

  static String getContextTypeDescription(String contextType) {
    switch (contextType) {
      case 'literacki':
        return 'Odniesienie do innych utworów literackich';
      case 'historycznoliteracki':
        return 'Odniesienie do prądów literackich danej epoki, np. romantyzmu czy pozytywizmu';
      case 'teoretycznoliteracki':
        return 'Odniesienie do wiedzy z zakresu teorii literatury, np. gatunków literackich';
      case 'historyczny':
        return 'Odniesienie do konkretnych wydarzeń historycznych, np. powstania, wojen';
      case 'filozoficzny':
        return 'Odniesienie do poglądów filozoficznych i traktatów filozoficznych';
      case 'kulturowy':
        return 'Odniesienie do wierzeń, tradycji i wartości kulturowych';
      case 'biograficzny':
        return 'Odniesienie do faktów z życia autora, które miały wpływ na powstanie dzieła';
      case 'biblijny':
        return 'Odniesienie do treści, motywów lub postaci z Biblii';
      case 'mitologiczny':
        return 'Odniesienie do mitów greckich, rzymskich lub innych';
      case 'religijny':
        return 'Odniesienie do zasad wiary, dogmatów czy podstaw danej religii';
      case 'egzystencjalny':
        return 'Odniesienie do problemów związanych z losem człowieka, sensu życia i śmierci';
      case 'społeczny':
        return 'Odniesienie do zjawisk społecznych, struktury społeczeństwa, obyczajowości';
      case 'polityczny':
        return 'Odniesienie do działań politycznych, ustroju państwa czy władzy';
      case 'artystyczny':
        return 'Odniesienie do innych dziedzin sztuki, takich jak film, malarstwo czy muzyka';
      default:
        return '';
    }
  }
}