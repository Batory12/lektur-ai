import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login and reschedule notifications
      await updateLastLoginTime();
      await _rescheduleNotifications();
      
      return AuthResult(success: true, user: result.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: 'Wystąpił nieoczekiwany błąd');
    }
  }

  // Register with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create user document in Firestore
        await _createUserDocument(user, displayName);

        return AuthResult(success: true, user: user);
      }
      return AuthResult(success: false, error: 'Nie udało się utworzyć konta');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: 'Wystąpił nieoczekiwany błąd');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'balance': 0,
        'city': null,
        'school': null,
        'className': null,
        'notificationFrequency': 'Codziennie',
        'notificationHour': 10,
        'notificationMinute': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Błąd podczas tworzenia dokumentu użytkownika: $e');
    }
  }

  // Update last login time
  Future<void> updateLastLoginTime() async {
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Błąd podczas aktualizacji czasu logowania: $e');
      }
    }
  }

  // Reschedule notifications based on user preference
  Future<void> _rescheduleNotifications() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String frequency = data['notificationFrequency'] ?? 'Codziennie';
          int hour = data['notificationHour'] ?? 10;
          int minute = data['notificationMinute'] ?? 0;
          await NotificationService().scheduleNotifications(frequency, hour: hour, minute: minute);
        }
      } catch (e) {
        print('Błąd podczas planowania powiadomień: $e');
      }
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        return doc.data() as Map<String, dynamic>?;
      } catch (e) {
        print('Błąd podczas pobierania danych użytkownika: $e');
        return null;
      }
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Błąd podczas wylogowywania: $e');
    }
  }

  // Delete account
  Future<AuthResult> deleteAccount() async {
    if (currentUser == null) {
      return AuthResult(
        success: false,
        error: 'Brak zalogowanego użytkownika',
      );
    }

    try {
      String uid = currentUser!.uid;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Firebase Auth
      await currentUser!.delete();

      return AuthResult(
        success: true,
        message: 'Konto zostało pomyślnie usunięte',
      );
    } on FirebaseAuthException catch (e) {
      // If the error is requires-recent-login, user needs to re-authenticate
      if (e.code == 'requires-recent-login') {
        return AuthResult(
          success: false,
          error: 'Aby usunąć konto, musisz się najpierw wylogować i zalogować ponownie',
        );
      }
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Wystąpił błąd podczas usuwania konta: $e',
      );
    }
  }

  Future<bool> changePassword(String newPassword) async {
    if (currentUser != null) {
      try {
        await currentUser!.updatePassword(newPassword);
        print("Password updated!");
        return true;
      } catch (e) {
        print("Error updating password: $e");
      }
    }
    return false;
  }

  // Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: 'Link do resetowania hasła został wysłany na Twój email',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: 'Wystąpił nieoczekiwany błąd');
    }
  }

  // Convert Firebase error codes to Polish messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Hasło jest zbyt słabe';
      case 'email-already-in-use':
        return 'Konto z tym adresem email już istnieje';
      case 'invalid-email':
        return 'Nieprawidłowy adres email';
      case 'user-not-found':
        return 'Użytkownik o tym adresie email nie istnieje';
      case 'wrong-password':
        return 'Nieprawidłowe hasło';
      case 'user-disabled':
        return 'To konto zostało zablokowane';
      case 'too-many-requests':
        return 'Zbyt wiele prób logowania. Spróbuj ponownie później';
      case 'network-request-failed':
        return 'Błąd połączenia sieciowego';
      case 'invalid-credential':
        return 'Nieprawidłowe dane logowania';
      default:
        return 'Wystąpił błąd: $code';
    }
  }
}

// Result class for auth operations
class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final String? message;

  AuthResult({
    required this.success,
    this.user,
    this.error,
    this.message,
  });
}
