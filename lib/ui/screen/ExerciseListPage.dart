import 'package:flutter/material.dart';
import 'package:fitness_app/utils/exercise_data.dart';
import 'ARWorkoutPage.dart';
import 'standard_workout_page.dart';

class ExerciseListPage extends StatefulWidget {
  final String workoutType;

  const ExerciseListPage({Key? key, required this.workoutType}) : super(key: key);

  @override
  _ExerciseListPageState createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  void _navigateToWorkout(String exerciseName, bool isArMode) {
    final arType = ExerciseData.getArType(exerciseName, widget.workoutType);
    Widget nextPage;

    if (isArMode && arType.isNotEmpty) {
      nextPage = ARWorkoutPage(
        workoutType: arType,
        workoutCategory: widget.workoutType,
        targetReps: widget.workoutType == 'Yoga' ? 20 : 10,
      );
    } else {
      nextPage = StandardWorkoutPage(
        workoutType: widget.workoutType,
        initialExercise: exerciseName,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseData.exercises[widget.workoutType] ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB39DDB),
        title: Text(
          "${widget.workoutType} Exercises",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            final arType = exercise['arType'] ?? '';
            return Card(
              color: const Color(0xFF1E1E2C),
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Image.asset(
                  'assets/icons/${exercise['name']!.toLowerCase().replaceAll(' ', '_')}.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center, color: Colors.white),
                ),
                title: Text(
                  exercise['name']!,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  exercise['duration'] ?? exercise['reps'] ?? 'N/A',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.videocam,
                        color: arType.isEmpty ? Colors.grey : Colors.white,
                      ),
                      onPressed: arType.isEmpty
                          ? null
                          : () => _navigateToWorkout(exercise['name']!, true),
                      tooltip: 'AR Mode',
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () => _navigateToWorkout(exercise['name']!, false),
                      tooltip: 'Standard Mode',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}