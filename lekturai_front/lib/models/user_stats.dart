

import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int currentStreak;
  final Timestamp lastTaskDate;
  final int longestStreak;
  final int points;
  final int totalTasksDone;

  UserStats({
    required this.currentStreak,
    required this.lastTaskDate,
    required this.longestStreak,
    required this.points,
    required this.totalTasksDone,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentStreak: json['current_streak'] ?? 0,
      lastTaskDate: json['last_task_date'],
      longestStreak: json['longest_streak'] ?? 0,
      points: json['points'] ?? 0,
      totalTasksDone: json['total_tasks_done'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'last_task_date': lastTaskDate,
      'longest_streak': longestStreak,
      'points': points,
      'total_tasks_done': totalTasksDone,
    };
  }
}