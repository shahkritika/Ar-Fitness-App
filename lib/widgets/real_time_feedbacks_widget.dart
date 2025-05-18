import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RealTimeFeedbackWidget extends StatelessWidget {
  final String workoutType;
  final String feedback;
  final String formFeedback;
  final int reps;
  final int goodReps;
  final int badReps;
  final bool isExerciseComplete;
  final double durationSeconds;

  const RealTimeFeedbackWidget({
    Key? key,
    required this.workoutType,
    required this.feedback,
    required this.formFeedback,
    required this.reps,
    required this.goodReps,
    required this.badReps,
    required this.isExerciseComplete,
    required this.durationSeconds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            feedback,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: const Color(0xFF6B48FF).withOpacity(0.5),
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (formFeedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              formFeedback,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: const Color(0xFF6B48FF).withOpacity(0.3),
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}