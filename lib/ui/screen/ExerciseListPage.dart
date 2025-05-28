import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/exercise_data.dart';
import 'ARWorkoutPage.dart';
import 'standard_workout_page.dart';

class ExerciseListPage extends StatelessWidget {
  final String category;

  const ExerciseListPage({Key? key, required this.category}) : super(key: key);

  void _showModeSelectionDialog(BuildContext context, Map<String, dynamic> exercise) {
    final exerciseName = exercise['name'] ?? 'Unknown';
    final duration = exercise['duration'] ?? '30s';
    final targetReps = int.tryParse(exercise['targetReps']?.toString() ?? '10') ?? 10;
    final targetDuration = double.tryParse(duration.replaceAll('s', '')) ?? 40.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Choose Mode for $exerciseName',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                print('Navigating to ARWorkoutPage: exercise=$exerciseName, category=$category');
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ARWorkoutPage(
                      workoutType: category,
                      workoutCategory: category,
                      initialExercise: exerciseName,
                      targetReps: targetReps,
                      targetDuration: targetDuration,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB39DDB),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'AR Mode 🚀',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                print('Navigating to StandardWorkoutPage: exercise=$exerciseName, category=$category');
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StandardWorkoutPage(
                      workoutType: exerciseName,
                      workoutCategory: category,
                      targetReps: targetReps,
                      targetDuration: targetDuration,
                      initialExercise: exerciseName,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB39DDB),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Standard Mode 🎥',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseData.exercises[category] ?? [];
    print('ExerciseListPage: Category: $category, Exercises: $exercises');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$category Exercises',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFB39DDB),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFFB39DDB)],
          ),
        ),
        child: exercises.isEmpty
            ? Center(
                child: Text(
                  'No exercises found for $category 😢',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final exerciseName = exercise['name'] ?? 'Unknown';
                  final duration = exercise['duration'] ?? '30s';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Color(0xFFB39DDB), width: 1),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        exerciseName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Duration: $duration',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      onTap: () => _showModeSelectionDialog(context, exercise),
                    ),
                  );
                },
              ),
      ),
    );
  }
}