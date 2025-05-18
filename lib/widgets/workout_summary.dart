import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class WorkoutSummary extends StatelessWidget {
  final int totalReps;
  final int goodReps;
  final int badReps;
  final int durationSeconds;
  final String exerciseType;
  final String workoutType;
  final String mode;
  final VoidCallback? onDone;

  const WorkoutSummary({
    Key? key,
    required this.totalReps,
    required this.goodReps,
    required this.badReps,
    required this.durationSeconds,
    required this.exerciseType,
    required this.workoutType,
    required this.mode,
    this.onDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B48FF),
              Color(0xFFA78BFA),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'You Crushed It! 🔥',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Workout: $workoutType',
                          style: GoogleFonts.orbitron(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Exercise: $exerciseType ($mode)',
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Reps: $totalReps 💪',
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Good Reps: $goodReps ✅',
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Bad Reps: $badReps 😬',
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Duration: $durationSeconds seconds ⏱️',
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ZoomIn(
                  duration: const Duration(milliseconds: 1000),
                  child: ElevatedButton(
                    onPressed: onDone ?? () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6B48FF), Color(0xFFA78BFA)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Done! Let’s Go! 🚀',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}