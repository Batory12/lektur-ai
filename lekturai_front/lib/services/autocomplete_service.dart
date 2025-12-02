import 'package:cloud_firestore/cloud_firestore.dart';

class AutocompleteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getCities(String query) async {
    if (query.isEmpty) return [];
    if (query.length < 3) return [];

    try {
      final querySnapshot = await _firestore
          .collection('schools')
          .where('city', isGreaterThanOrEqualTo: query)
          .where('city', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['city'] as String)
          .toSet()
          .toList();
    } catch (e) {
      print('Error fetching cities: $e');
      return [];
    }
  }

  Future<List<String>> getSchoolNames(String city, String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('schools')
          .where('city', isEqualTo: city)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();
    } catch (e) {
      print('Error fetching school names: $e');
      return [];
    }
  }
}