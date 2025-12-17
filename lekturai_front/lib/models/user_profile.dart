import 'package:cloud_firestore/cloud_firestore.dart';


// User profile model
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? city;
  final String? school;
  final String? className;
  final String? notificationFrequency;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.city,
    this.school,
    this.className,
    this.notificationFrequency,
    this.createdAt,
    this.lastLoginAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      city: map['city'],
      school: map['school'],
      className: map['className'],
      notificationFrequency: map['notificationFrequency'] ?? 'Codziennie',
      createdAt: map['createdAt']?.toDate(),
      lastLoginAt: map['lastLoginAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'city': city,
      'school': school,
      'className': className,
      'notificationFrequency': notificationFrequency,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
