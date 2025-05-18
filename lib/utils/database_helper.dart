import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static dynamic _database; // Use dynamic to hold Database or FirebaseFirestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseHelper._init();

  Future<dynamic> get database async {
    if (_database != null) return _database;
    if (kIsWeb) {
      _database = _firestore; // Use Firestore for web
    } else {
      _database = await _initDB('fitness.db');
    }
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        date TEXT,
        category TEXT,
        duration INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER,
        exercise_name TEXT,
        reps INTEGER,
        good_reps INTEGER,
        bad_reps INTEGER,
        duration INTEGER,
        mode TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (workout_id) REFERENCES workouts (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE exercises ADD COLUMN good_reps INTEGER');
      await db.execute('ALTER TABLE exercises ADD COLUMN bad_reps INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE workouts ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE workouts ADD COLUMN synced INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE exercises ADD COLUMN synced INTEGER DEFAULT 0');
    }
  }

  Future<int> insertWorkout(Map<String, dynamic> workout) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    workout['user_id'] = userId;
    workout['synced'] = 0;

    if (kIsWeb) {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .add(workout..remove('id')); // Remove id for Firestore auto-ID
      return int.parse(docRef.id);
    } else {
      final db = await database;
      final id = await db.insert('workouts', workout);
      await _syncWorkoutToFirestore(workout, id);
      return id;
    }
  }

  Future<int> insertExercise(Map<String, dynamic> exercise) async {
    exercise['synced'] = 0;
    final workoutId = exercise['workout_id'];
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (kIsWeb) {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId.toString())
          .collection('exercises')
          .add(exercise..remove('id'));
      return int.parse(docRef.id);
    } else {
      final db = await database;
      final id = await db.insert('exercises', exercise);
      await _syncExerciseToFirestore(exercise, id, workoutId);
      return id;
    }
  }

  Future<void> _syncWorkoutToFirestore(Map<String, dynamic> workout, int localId) async {
    if (kIsWeb) return; // No sync needed for web
    try {
      final userId = workout['user_id'];
      final workoutData = Map<String, dynamic>.from(workout)..remove('synced');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(localId.toString())
          .set(workoutData);
      final db = await database;
      await db.update(
        'workouts',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      print('Error syncing workout to Firestore: $e');
    }
  }

  Future<void> _syncExerciseToFirestore(Map<String, dynamic> exercise, int localId, int workoutId) async {
    if (kIsWeb) return; // No sync needed for web
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final exerciseData = Map<String, dynamic>.from(exercise)..remove('synced');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId.toString())
          .collection('exercises')
          .doc(localId.toString())
          .set(exerciseData);
      final db = await database;
      await db.update(
        'exercises',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      print('Error syncing exercise to Firestore: $e');
    }
  }

  Future<void> syncLocalWithFirestore() async {
    if (kIsWeb) return; // No local database on web
    final db = await database;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Sync unsynced local workouts
    final unsyncedWorkouts = await db.query(
      'workouts',
      where: 'user_id = ? AND synced = ?',
      whereArgs: [userId, 0],
    );
    for (var workout in unsyncedWorkouts) {
      await _syncWorkoutToFirestore(workout, workout['id'] as int);
    }

    // Sync unsynced local exercises
    final unsyncedExercises = await db.query(
      'exercises',
      where: 'synced = ?',
      whereArgs: [0],
    );
    for (var exercise in unsyncedExercises) {
      await _syncExerciseToFirestore(exercise, exercise['id'] as int, exercise['workout_id'] as int);
    }

    // Fetch Firestore workouts to local
    final firestoreWorkouts = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .get();
    for (var doc in firestoreWorkouts.docs) {
      final workoutData = doc.data();
      final localWorkout = await db.query(
        'workouts',
        where: 'id = ? AND user_id = ?',
        whereArgs: [int.parse(doc.id), userId],
      );
      if (localWorkout.isEmpty) {
        final workoutId = await db.insert('workouts', {
          ...workoutData,
          'id': int.parse(doc.id),
          'user_id': userId,
          'synced': 1,
        });

        final firestoreExercises = await _firestore
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(doc.id)
            .collection('exercises')
            .get();
        for (var exDoc in firestoreExercises.docs) {
          final exerciseData = exDoc.data();
          await db.insert('exercises', {
            ...exerciseData,
            'id': int.parse(exDoc.id),
            'workout_id': workoutId,
            'synced': 1,
          });
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutProgress(String userId) async {
    if (kIsWeb) {
      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .orderBy('date', descending: true)
          .get();
      final List<Map<String, dynamic>> result = [];

      for (var workoutDoc in workoutsSnapshot.docs) {
        final workout = workoutDoc.data();
        workout['id'] = int.parse(workoutDoc.id);
        final exercisesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(workoutDoc.id)
            .collection('exercises')
            .get();
        final exercises = exercisesSnapshot.docs.map((e) {
          final data = e.data();
          data['id'] = int.parse(e.id);
          return data;
        }).toList();
        result.add({
          'workout': workout,
          'exercises': exercises,
        });
      }
      return result;
    } else {
      final db = await database;
      final workouts = await db.query(
        'workouts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      final List<Map<String, dynamic>> result = [];

      for (var workout in workouts) {
        final exercises = await db.query(
          'exercises',
          where: 'workout_id = ?',
          whereArgs: [workout['id']],
        );
        result.add({
          'workout': workout,
          'exercises': exercises,
        });
      }
      return result;
    }
  }

  Future<Map<String, dynamic>> getProgressSummary(String userId) async {
    if (kIsWeb) {
      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .get();
      final exercisesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .get()
          .then((snapshot) async {
        final allExercises = <Map<String, dynamic>>[];
        for (var workoutDoc in snapshot.docs) {
          final exercises = await _firestore
              .collection('users')
              .doc(userId)
              .collection('workouts')
              .doc(workoutDoc.id)
              .collection('exercises')
              .get();
          allExercises.addAll(exercises.docs.map((e) => e.data()));
        }
        return allExercises;
      });

      final totalWorkouts = workoutsSnapshot.docs.length;
      final totalExercises = exercisesSnapshot.length;
      final totalReps = exercisesSnapshot.fold<num>(0, (sum, e) => sum + (e['reps'] ?? 0)).toInt();
      final avgGoodReps = exercisesSnapshot.isEmpty
          ? 0.0
          : exercisesSnapshot.fold<num>(0, (sum, e) => sum + (e['good_reps'] ?? 0)) / exercisesSnapshot.length;
      final avgBadReps = exercisesSnapshot.isEmpty
          ? 0.0
          : exercisesSnapshot.fold<num>(0, (sum, e) => sum + (e['bad_reps'] ?? 0)) / exercisesSnapshot.length;
      final totalDuration = exercisesSnapshot.fold<num>(0, (sum, e) => sum + (e['duration'] ?? 0)).toInt();

      return {
        'total_workouts': totalWorkouts,
        'total_exercises': totalExercises,
        'total_reps': totalReps,
        'avg_good_reps': avgGoodReps,
        'avg_bad_reps': avgBadReps,
        'total_duration': totalDuration,
      };
    } else {
      final db = await database;
      final workoutCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM workouts WHERE user_id = ?',
        [userId],
      );
      final workoutCount = workoutCountResult[0]['count'] as int? ?? 0;

      final exerciseStats = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_exercises,
          SUM(reps) as total_reps,
          AVG(good_reps) as avg_good_reps,
          AVG(bad_reps) as avg_bad_reps,
          SUM(duration) as total_duration
        FROM exercises e
        JOIN workouts w ON e.workout_id = w.id
        WHERE w.user_id = ?
        ''',
        [userId],
      );

      return {
        'total_workouts': workoutCount,
        'total_exercises': exerciseStats[0]['total_exercises'] ?? 0,
        'total_reps': exerciseStats[0]['total_reps'] ?? 0,
        'avg_good_reps': exerciseStats[0]['avg_good_reps'] ?? 0.0,
        'avg_bad_reps': exerciseStats[0]['avg_bad_reps'] ?? 0.0,
        'total_duration': exerciseStats[0]['total_duration'] ?? 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getProgressByDate(String userId, String exerciseName) async {
    if (kIsWeb) {
      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .get();
      final Map<String, Map<String, dynamic>> groupedByDate = {};

      for (var workoutDoc in workoutsSnapshot.docs) {
        final workout = workoutDoc.data();
        final date = workout['date'];
        final exercisesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(workoutDoc.id)
            .collection('exercises')
            .where('exercise_name', isEqualTo: exerciseName.isEmpty ? null : exerciseName)
            .get();

        final totalReps = exercisesSnapshot.docs.fold<num>(0, (sum, e) => sum + (e.data()['reps'] ?? 0)).toInt();
        final totalDuration = exercisesSnapshot.docs.fold<num>(0, (sum, e) => sum + (e.data()['duration'] ?? 0)).toInt();

        if (totalReps > 0 || totalDuration > 0) {
          if (groupedByDate.containsKey(date)) {
            groupedByDate[date]!['total_reps'] += totalReps;
            groupedByDate[date]!['total_duration'] += totalDuration;
          } else {
            groupedByDate[date] = {
              'date': date,
              'total_reps': totalReps,
              'total_duration': totalDuration,
            };
          }
        }
      }

      final result = groupedByDate.values.toList()
        ..sort((a, b) => a['date'].compareTo(b['date']));
      return result;
    } else {
      final db = await database;
      final query = exerciseName.isEmpty
          ? '''
            SELECT 
              w.date,
              SUM(e.reps) as total_reps,
              SUM(e.duration) as total_duration
            FROM workouts w
            LEFT JOIN exercises e ON w.id = e.workout_id
            WHERE w.user_id = ?
            GROUP BY w.date
            ORDER BY w.date ASC
          '''
          : '''
            SELECT 
              w.date,
              SUM(e.reps) as total_reps,
              SUM(e.duration) as total_duration
            FROM workouts w
            JOIN exercises e ON w.id = e.workout_id
            WHERE w.user_id = ? AND e.exercise_name = ?
            GROUP BY w.date
            ORDER BY w.date ASC
          ''';

      final result = exerciseName.isEmpty
          ? await db.rawQuery(query, [userId])
          : await db.rawQuery(query, [userId, exerciseName]);

      return result;
    }
  }

  Future<void> close() async {
    if (!kIsWeb) {
      final db = await database;
      await db.close();
    }
  }
}