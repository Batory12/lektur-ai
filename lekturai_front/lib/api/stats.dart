import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lekturai_front/api/api_config.dart';

/// Model for user daily stats response
class UserDailyStats {
  final int points;
  final String docId;

  UserDailyStats({
    required this.points,
    required this.docId,
  });

  factory UserDailyStats.fromJson(Map<String, dynamic> json) {
    return UserDailyStats(
      points: json['points'] ?? 0,
      docId: json['doc_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'doc_id': docId,
    };
  }
}

/// Model for average daily stats response
class AvgDailyStats {
  final double avgPoints;

  AvgDailyStats({required this.avgPoints});

  factory AvgDailyStats.fromJson(Map<String, dynamic> json) {
    return AvgDailyStats(
      avgPoints: (json['avg_points'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avg_points': avgPoints,
    };
  }
}

/// API class for stats-related endpoints
class StatsApi {
  final String baseUrl;

  StatsApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Get user daily stats
  /// 
  /// [userId] - The user ID to get stats for
  /// 
  /// Returns a list of [UserDailyStats]
  Future<List<UserDailyStats>> getUserDailyStats(String userId) async {
    final url = Uri.parse(ApiConfig.userDailyStatsEndpoint).replace(
      queryParameters: {'user_id': userId},
    );

    ApiConfig.logRequest(
      method: 'GET',
      url: url.toString(),
    );

    final response = await http.get(url);

    ApiConfig.logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => UserDailyStats.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user daily stats: ${response.statusCode}');
    }
  }

  /// Get average school daily stats
  /// 
  /// [schoolName] - The name of the school
  /// [city] - The city where the school is located
  /// 
  /// Returns a list of [AvgDailyStats]
  Future<List<AvgDailyStats>> getAvgSchoolDaily({
    required String schoolName,
    required String city,
  }) async {
    final url = Uri.parse(ApiConfig.avgSchoolDailyStatsEndpoint).replace(
      queryParameters: {
        'school_name': schoolName,
        'city': city,
      },
    );

    ApiConfig.logRequest(
      method: 'GET',
      url: url.toString(),
    );

    final response = await http.get(url);

    ApiConfig.logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AvgDailyStats.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load average school daily stats: ${response.statusCode}');
    }
  }

  /// Get average class daily stats
  /// 
  /// [schoolName] - The name of the school
  /// [city] - The city where the school is located
  /// [className] - The name of the class
  /// 
  /// Returns a list of [AvgDailyStats]
  Future<List<AvgDailyStats>> getAvgClassDaily({
    required String schoolName,
    required String city,
    required String className,
  }) async {
    final url = Uri.parse(ApiConfig.avgClassDailyStatsEndpoint).replace(
      queryParameters: {
        'school_name': schoolName,
        'city': city,
        'class_name': className,
      },
    );

    ApiConfig.logRequest(
      method: 'GET',
      url: url.toString(),
    );

    final response = await http.get(url);

    ApiConfig.logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AvgDailyStats.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load average class daily stats: ${response.statusCode}');
    }
  }
}
