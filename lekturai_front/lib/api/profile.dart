import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MockProfileApi {
  final String? baseUrl;
  List<dynamic> _schoolsData = [];

  MockProfileApi({this.baseUrl});

  Future<void> loadSchools() async {
    if (_schoolsData.isEmpty) {
      final String response = await rootBundle.loadString('assets/schools.json');
      _schoolsData = json.decode(response);
    }
  }

  Future<http.Response> changePassword(String userId, String oldPassword, String newPassword) {
    final url = Uri.parse('$baseUrl/users/$userId/change-password');
    return http.post(
      url,
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<List<String>> getCityAutocompletions(String query) async {
    await loadSchools();
    return _schoolsData
        .map((e) => e['city'] as String)
        .where((city) => city.toLowerCase().startsWith(query.toLowerCase()))
        .toList();
  }

  Future<List<String>> getSchoolAutocompletions(String city, String query) async {
    await loadSchools();
    final cityData = _schoolsData.firstWhere(
      (e) => e['city'] == city,
      orElse: () => {'schools': []},
    );
    final List<dynamic> schools = cityData['schools'];
    return schools
        .map((e) => e as String)
        .where((school) => school.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}