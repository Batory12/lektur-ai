import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  }
  
  static const String contextsEndpoint = '/contexts';
  
  static String get contextsUrl => baseUrl + contextsEndpoint;
  
  // Debug logging for API requests
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
  }) {
    print('=== API REQUEST ===');
    print('Method: $method');
    print('URL: $url');
    
    if (headers != null && headers.isNotEmpty) {
      print('Headers:');
      headers.forEach((key, value) {
        print('  $key: $value');
      });
    }
    
    if (body != null && body.isNotEmpty) {
      print('Body:');
      try {
        // Try to format JSON body for better readability
        final jsonBody = jsonDecode(body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonBody);
        print(prettyJson);
      } catch (e) {
        // If not JSON, print as is
        print(body);
      }
    }
    
    print('==================');
  }
  
  // Debug logging for API responses
  static void logResponse(http.Response response) {
    print('=== API RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Reason Phrase: ${response.reasonPhrase}');
    
    if (response.headers.isNotEmpty) {
      print('Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
    }
    
    if (response.body.isNotEmpty) {
      print('Body:');
      try {
        // Try to format JSON response for better readability
        final jsonBody = jsonDecode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonBody);
        print(prettyJson);
      } catch (e) {
        // If not JSON, print as is
        print(response.body);
      }
    }
    
    print('===================');
  }
}