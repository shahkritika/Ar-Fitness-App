import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/exercise_data.dart';
import 'ExerciseListPage.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = ExerciseData.exercises.keys.toList();
    print('WorkoutPage: Categories: $categories');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Workout Categories',
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final workoutName = categories[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  workoutName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  print('Navigating to ExerciseListPage: category=$workoutName');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseListPage(category: workoutName),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}