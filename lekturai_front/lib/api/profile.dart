import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileApi {
  final String? baseUrl;

  ProfileApi({this.baseUrl});

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
  List<String> getCityAutocompletions(String query) {
    final cities = ['Warszawa', 'Wrocław', 'Wisła'];
    return cities.where((city) => city.toLowerCase().startsWith(query.toLowerCase())).toList();
  //   final url = Uri.parse('$baseUrl/cities/autocomplete?query=$query');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     // Assuming the response body is a JSON array of city names
  //     final List<dynamic> data = jsonDecode(response.body);
  //     return data.cast<String>();
  //   } else {
  //     throw Exception('Failed to load city autocompletions');
  //   }
  }

  List<String> getSchoolAutocompletions(String city, String query) {
    final schools = {
      'Warszawa': ['Liceum Ogólnokształcące im. Stefana Batorego', 'XXX LO'],
      'Wrocław': ['I Liceum Ogólnokształcące', 'II Liceum Ogólnokształcące'],
      'Wisła': ['Liceum Ogólnokształcące w Wiśle'],
    };

    final citySchools = schools[city] ?? [];
    return citySchools.where((school) => school.toLowerCase().startsWith(query.toLowerCase())).toList();
  }
}