import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lekturai_front/models/user_stats.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user profile data
  Future<UserProfile?> getUserProfile() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Błąd podczas pobierania profilu: $e');
      return null;
    }
  }

  Future<UserStats?> getUserStats() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('user-all-time-stats')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserStats.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Błąd podczas pobierania statystyk użytkownika: $e');
      return null;
    }
  }

  // Update user's school information
  Future<ProfileUpdateResult> updateSchoolInfo({
    required String city,
    required String school,
    required String className,
  }) async {
    if (currentUser == null) {
      return ProfileUpdateResult(
        success: false,
        error: 'Użytkownik nie jest zalogowany',
      );
    }

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'city': city,
        'school': school,
        'className': className,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ProfileUpdateResult(
        success: true,
        message: 'Dane szkoły zostały zaktualizowane',
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        error: 'Błąd podczas aktualizacji: $e',
      );
    }
  }

  // Update user's city
  Future<ProfileUpdateResult> updateCity(String city) async {
    if (currentUser == null) {
      return ProfileUpdateResult(
        success: false,
        error: 'Użytkownik nie jest zalogowany',
      );
    }

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'city': city,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ProfileUpdateResult(
        success: true,
        message: 'Miejscowość została zaktualizowana',
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        error: 'Błąd podczas aktualizacji miejscowości: $e',
      );
    }
  }

  // Update user's school
  Future<ProfileUpdateResult> updateSchool(String school) async {
    if (currentUser == null) {
      return ProfileUpdateResult(
        success: false,
        error: 'Użytkownik nie jest zalogowany',
      );
    }

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'school': school,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ProfileUpdateResult(
        success: true,
        message: 'Szkoła została zaktualizowana',
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        error: 'Błąd podczas aktualizacji szkoły: $e',
      );
    }
  }

  // Update user's class
  Future<ProfileUpdateResult> updateClass(String className) async {
    if (currentUser == null) {
      return ProfileUpdateResult(
        success: false,
        error: 'Użytkownik nie jest zalogowany',
      );
    }

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'className': className,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ProfileUpdateResult(
        success: true,
        message: 'Klasa została zaktualizowana',
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        error: 'Błąd podczas aktualizacji klasy: $e',
      );
    }
  }

  // Update notification frequency
  Future<ProfileUpdateResult> updateNotificationFrequency(String frequency) async {
    if (currentUser == null) {
      return ProfileUpdateResult(
        success: false,
        error: 'Użytkownik nie jest zalogowany',
      );
    }

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'notificationFrequency': frequency,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ProfileUpdateResult(
        success: true,
        message: 'Częstotliwość powiadomień została zaktualizowana',
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        error: 'Błąd podczas aktualizacji powiadomień: $e',
      );
    }
  }

  // Stream of user profile changes
  Stream<UserProfile?> getUserProfileStream() {
    if (currentUser == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
// Result class for profile operations
class ProfileUpdateResult {
  final bool success;
  final String? message;
  final String? error;

  ProfileUpdateResult({
    required this.success,
    this.message,
    this.error,
  });
}
