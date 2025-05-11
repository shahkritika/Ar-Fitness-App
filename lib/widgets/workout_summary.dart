import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkoutSummary extends StatelessWidget {
  final int totalReps;
  final int goodReps;
  final int badReps;
  final int durationSeconds;
  final String exerciseType;
  final VoidCallback onDone;

  const WorkoutSummary({
    Key? key,
    required this.totalReps,
    required this.goodReps,
    required this.badReps,
    required this.durationSeconds,
    required this.exerciseType,
    required this.onDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: durationSeconds);
    final formattedTime = '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final double accuracy = totalReps > 0 ? (goodReps / totalReps) * 100 : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  '🔥 WORKOUT COMPLETE! 🔥',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildNeonCard(
                  context,
                  child: Column(
                    children: [
                      Text(
                        exerciseType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You crushed it!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.timer,
                      value: formattedTime,
                      label: 'Duration',
                      color: const Color(0xFF00D9F5),
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.repeat,
                      value: '$totalReps',
                      label: 'Total Reps',
                      color: const Color(0xFF00F5A0),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.check_circle,
                      value: '$goodReps',
                      label: 'Good Reps',
                      color: Colors.green,
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.warning,
                      value: '$badReps',
                      label: 'Bad Reps',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildAccuracyMeter(context, accuracy),
                const SizedBox(height: 40),
                _buildDoneButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonCard(BuildContext context, {required Widget child, required Gradient gradient}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyMeter(BuildContext context, double accuracy) {
    return Column(
      children: [
        Text(
          'FORM ACCURACY',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 15),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: CircularProgressIndicator(
                value: accuracy / 100,
                strokeWidth: 15,
                backgroundColor: Colors.grey[800],
                color: _getAccuracyColor(accuracy),
              ),
            ),
            Column(
              children: [
                Text(
                  '${accuracy.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getAccuracyFeedback(accuracy),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onDone,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00F5A0),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        shadowColor: const Color(0xFF00F5A0).withOpacity(0.5),
      ),
      child: const Text(
        'OK',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return const Color(0xFF00F5A0);
    if (accuracy >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getAccuracyFeedback(double accuracy) {
    if (accuracy >= 90) return 'FLAWLESS!';
    if (accuracy >= 70) return 'GREAT JOB!';
    if (accuracy >= 50) return 'GOOD ENOUGH';
    return 'NEEDS WORK';
  }
}