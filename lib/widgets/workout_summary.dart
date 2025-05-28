import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutSummary extends StatefulWidget {
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
  State<WorkoutSummary> createState() => _WorkoutSummaryState();
}

class _WorkoutSummaryState extends State<WorkoutSummary> {
  bool _isSaving = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Map exercise types to icons/emojis and motivational headers
  static const Map<String, Map<String, String>> _exerciseMeta = {
    'squat': {'icon': '🦵', 'header': 'You crushed those squats! 🫶'},
    'pushup': {'icon': '💪', 'header': 'Pushup king/queen! 🔥'},
    'deadlift': {'icon': '🏋️', 'header': 'Deadlift domination! 💥'},
    'lunge': {'icon': '🦵', 'header': 'Lunge legend! 🌟'},
    'plank': {'icon': '⏱️', 'header': 'Plank powerhouse! ⏱️'},
    'bench_press': {'icon': '🏋️', 'header': 'Bench press beast! 💪'},
    'jumping_jacks': {'icon': '✨', 'header': 'Jumping jacks slayed! ✨'},
    'mountain_climbers': {'icon': '🏃', 'header': 'Mountain climbers conquered! 🏃'},
    'running_in_place': {'icon': '🏃', 'header': 'Ran it up! 🏃'},
    'skaters': {'icon': '⛸️', 'header': 'Skater vibes on point! ⛸️'},
    'butt_kicks': {'icon': '🦵', 'header': 'Butt kicks brought it! 🦵'},
    'jump_rope': {'icon': '🪢', 'header': 'Jump rope royalty! 🪢'},
    'burpees': {'icon': '💥', 'header': 'Burpee boss! 💥'},
    'high_knees': {'icon': '🏃', 'header': 'High knees hero! 🏃'},
    'jump_squats': {'icon': '🦵', 'header': 'Jump squat star! 🌟'},
    'lunges_with_jumps': {'icon': '🦵', 'header': 'Lunge jump legend! 🌟'},
    'plank_to_pushup': {'icon': '💪', 'header': 'Plank to pushup pro! 💪'},
  };

  String _getFormFeedback() {
    if (widget.mode == 'Standard') {
      return 'Great effort! Focus on maintaining steady pacing in Standard mode. 🚀';
    }
    if (widget.badReps == 0) return 'Perfect form, keep it up! 😎';
    switch (widget.exerciseType) {
      case 'jumping_jacks':
        return 'Try spreading legs wider and syncing arms! ✨';
      case 'mountain_climbers':
        return 'Keep hips level and tuck knees higher! 🏃';
      case 'running_in_place':
        return 'Lift those knees higher and stay upright! 🏃';
      case 'skaters':
        return 'Cross trailing leg more and stay upright! ⛸️';
      case 'butt_kicks':
        return 'Kick heels closer to glutes! 🦵';
      case 'jump_rope':
        return 'Minimize knee bend and sync arms! 🪢';
      case 'squat':
        return 'Keep knees aligned and go deeper! 🦵';
      case 'pushup':
        return 'Align elbows and lower chest more! 💪';
      case 'deadlift':
        return 'Don\'t round your back, hinge at hips! 🏋️';
      case 'lunge':
        return 'Keep front knee over ankle! 🦵';
      case 'bench_press':
        return 'Tuck elbows and align wrists! 🏋️';
      case 'plank':
        return 'Straighten body and level hips! ⏱️';
      case 'burpees':
        return 'Keep core tight and land softly! 💥';
      case 'high_knees':
        return 'Lift knees higher and stay upright! 🏃';
      case 'jump_squats':
        return 'Land softly and keep knees aligned! 🦵';
      case 'lunges_with_jumps':
        return 'Keep front knee over ankle on landing! 🦵';
      case 'plank_to_pushup':
        return 'Keep hips stable during transition! 💪';
      default:
        return 'Work on form for better reps! 💪';
    }
  }

  Future<void> _saveWorkoutSummary() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to save your workout'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Use user-specific box name
      final box = await Hive.openBox('workouts_${user.uid}');

      await box.put(DateTime.now().millisecondsSinceEpoch.toString(), {
        'totalReps': widget.totalReps,
        'goodReps': widget.goodReps,
        'badReps': widget.badReps,
        'durationSeconds': widget.durationSeconds,
        'exerciseType': widget.exerciseType,
        'workoutType': widget.workoutType,
        'mode': widget.mode,
        'date': DateTime.now().toIso8601String(),
        'userId': user.uid, // Store user ID for verification
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (widget.onDone != null && mounted) widget.onDone!();
    } catch (e) {
      print('Error saving workout summary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _saveWorkoutSummary,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _exerciseMeta[widget.exerciseType] ?? {
      'icon': '💪',
      'header': 'You crushed it! 🫶'
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ZoomIn(
                  duration: const Duration(milliseconds: 600),
                  child: Flexible(
                    child: Text(
                      meta['header']!,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeIn(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 100),
                  child: Flexible(
                    child: Text(
                      '${meta['icon']} ${widget.exerciseType.replaceAll('_', ' ').toUpperCase()} (${widget.mode})',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeIn(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFB39DDB).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFB39DDB).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workoutType,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Duration',
                          '${widget.durationSeconds ~/ 60}:${(widget.durationSeconds % 60).toString().padLeft(2, '0')} min ⏱️',
                        ),
                        if (widget.mode == 'AR') ...[
                          _buildStatRow('Reps', '${widget.totalReps} ${meta['icon']}'),
                          _buildStatRow('Good', '${widget.goodReps} ✅'),
                          _buildStatRow('Bad', '${widget.badReps} 😬'),
                        ],
                        if (widget.mode == 'Standard')
                          _buildStatRow('Mode', 'Standard (duration-based) 📏'),
                        const SizedBox(height: 12),
                        Text(
                          'Tip: ${_getFormFeedback()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ZoomIn(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isSaving)
                        Flexible(
                          flex: 1,
                          child: GestureDetector(
                            onTap: _saveWorkoutSummary,
                            child: Pulse(
                              duration: const Duration(milliseconds: 1200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFB39DDB),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFB39DDB).withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Save Workout',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isSaving)
                        const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(width: 10),
                      Flexible(
                        flex: 1,
                        child: GestureDetector(
                          onTap: _isSaving ? null : (widget.onDone ?? () => Navigator.pop(context)),
                          child: Pulse(
                            duration: const Duration(milliseconds: 1200),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Color(0xFFB39DDB),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFB39DDB).withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Done, let\'s bounce! 🚀',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}