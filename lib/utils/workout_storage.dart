import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WorkoutRecord {
  final String exerciseType;
  final String workoutType;
  final int totalReps;
  final int goodReps;
  final int badReps;
  final int durationSeconds;
  final String mode;
  final DateTime timestamp;

  WorkoutRecord({
    required this.exerciseType,
    required this.workoutType,
    required this.totalReps,
    required this.goodReps,
    required this.badReps,
    required this.durationSeconds,
    required this.mode,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'exerciseType': exerciseType,
        'workoutType': workoutType,
        'totalReps': totalReps,
        'goodReps': goodReps,
        'badReps': badReps,
        'durationSeconds': durationSeconds,
        'mode': mode,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        exerciseType: json['exerciseType'],
        workoutType: json['workoutType'],
        totalReps: json['totalReps'],
        goodReps: json['goodReps'],
        badReps: json['badReps'],
        durationSeconds: json['durationSeconds'],
        mode: json['mode'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class WorkoutStorage {
  static const String _key = 'workout_records';

  Future<void> saveWorkout(WorkoutRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getWorkouts();
    records.add(record);
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setStringList(
        _key, jsonList.map((r) => jsonEncode(r)).toList());
    print('Saved workout: ${record.exerciseType}, ${record.timestamp}');
  }

  Future<List<WorkoutRecord>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((json) => WorkoutRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> clearWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    print('Cleared all workout records');
  }

  Future<List<WorkoutRecord>> getWorkoutsByExercise(String exerciseType) async {
    final records = await getWorkouts();
    return records.where((r) => r.exerciseType == exerciseType).toList();
  }
}