import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../utils/exercise_data.dart';
import '../../widgets/workout_summary.dart';

class StandardWorkoutPage extends StatefulWidget {
  final String workoutType;
  final String workoutCategory;
  final int targetReps;
  final double targetDuration;
  final String? initialExercise;

  const StandardWorkoutPage({
    Key? key,
    required this.workoutType,
    required this.workoutCategory,
    this.targetReps = 10,
    this.targetDuration = 40.0,
    this.initialExercise,
  }) : super(key: key);

  @override
  _StandardWorkoutPageState createState() => _StandardWorkoutPageState();
}

class _StandardWorkoutPageState extends State<StandardWorkoutPage> {
  int _exerciseIndex = 0;
  late List<Map<String, String>> _exercises;
  late Stopwatch _stopwatch;
  VideoPlayerController? _videoController;
  bool _isWorkoutStarted = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  Map<String, int> _exerciseDurations = {};

  @override
  void initState() {
    super.initState();
    _exercises = ExerciseData.exercises[widget.workoutCategory] ?? [];
    if (_exercises.isEmpty) {
      print('No exercises found for category: ${widget.workoutCategory}');
      _exercises = [];
    }
    if (widget.initialExercise != null) {
      _exerciseIndex = _exercises.indexWhere((e) => e['name'] == widget.initialExercise);
      if (_exerciseIndex == -1) _exerciseIndex = 0;
    }
    _stopwatch = Stopwatch();
    _loadVideo();
  }

  void _loadVideo() {
    _videoController?.dispose();
    if (_exercises.isEmpty || _exerciseIndex >= _exercises.length) return;
    String? videoPath = _exercises[_exerciseIndex]['video'];
    if (videoPath == null) {
      videoPath = 'assets/videos/default.mp4';
    }
    _videoController = VideoPlayerController.asset(videoPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          if (_isWorkoutStarted) {
            _videoController!.play();
            _videoController!.setLooping(true);
          }
        }
      }).catchError((error) {
        print('Video initialization error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $error 😢')),
        );
      });
  }

  void _startWorkout() {
    setState(() {
      _countdownSeconds = 5;
      _isWorkoutStarted = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _isWorkoutStarted = true;
          _stopwatch.start();
          if (_videoController != null && _videoController!.value.isInitialized) {
            _videoController!.play();
            _videoController!.setLooping(true);
          }
          timer.cancel();
        }
      });
    });
  }

  void _nextExercise() {
    if (_exercises.isEmpty || _exerciseIndex >= _exercises.length) {
      _endWorkout();
      return;
    }

    final currentExercise = _exercises[_exerciseIndex];
    _exerciseDurations[currentExercise['name']!] =
        (_exerciseDurations[currentExercise['name']!] ?? 0) + _stopwatch.elapsed.inSeconds;
    _stopwatch.reset();

    if (_exerciseIndex < _exercises.length - 1 && widget.initialExercise == null) {
      setState(() {
        _exerciseIndex++;
        _isWorkoutStarted = false;
        _countdownSeconds = 5;
        _loadVideo();
      });
    } else {
      _endWorkout();
    }
  }

  // Save workout summary to Hive
  Future<void> _saveWorkoutSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, cannot save workout summary');
      return;
    }

    try {
      final box = await Hive.openBox('workouts_${user.uid}');
      final totalDuration = _exerciseDurations.values.fold(0, (sum, duration) => sum + duration);
      final exerciseName = _exercises.isNotEmpty
          ? _exercises[_exerciseIndex]['name']!.toLowerCase().replaceAll(' ', '_')
          : widget.workoutType.toLowerCase().replaceAll(' ', '_');
      final summary = {
        'exerciseName': exerciseName, // Normalized (e.g., "squat", "bench_press")
        'date': DateTime.now().toIso8601String(),
        'totalReps': 0, // No rep counting in Standard mode
        'goodReps': 0,
        'badReps': 0,
        'durationSeconds': totalDuration.toDouble(),
        'mode': 'Standard',
        'isRepBased': false, // Standard mode is time-based
        'isGoodForm': true, // Assume good form (no pose detection)
      };
      await box.add(summary);
      print('Saved workout summary: $summary');
    } catch (e) {
      print('Error saving workout summary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save workout: $e')),
        );
      }
    }
  }

  void _endWorkout() {
    _stopwatch.stop();
    _videoController?.pause();
    int totalDuration = _exerciseDurations.values.fold(0, (sum, duration) => sum + duration);
    String exerciseType = _exercises.isNotEmpty
        ? _exercises[_exerciseIndex]['name']!.toLowerCase().replaceAll(' ', '_')
        : widget.workoutType.toLowerCase().replaceAll(' ', '_');

    // Save the workout summary before navigating
    _saveWorkoutSummary();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSummary(
          totalReps: 0, // No rep counting in Standard mode
          goodReps: 0,
          badReps: 0,
          durationSeconds: totalDuration,
          exerciseType: exerciseType,
          workoutType: widget.workoutCategory,
          mode: 'Standard',
          onDone: () => Navigator.pushNamed(context, '/dashboard'),
        ),
      ),
    );
    print('Navigating to WorkoutSummary: duration=$totalDuration');
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _countdownTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.workoutCategory,
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
          child: Center(
            child: Text(
              'No exercises available for this category.',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    final currentExercise = _exercises[_exerciseIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentExercise['name']!,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Time: ${_stopwatch.elapsed.inMinutes}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.initialExercise == null)
                    Text(
                      "Exercise ${_exerciseIndex + 1} / ${_exercises.length}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_isWorkoutStarted && _countdownSeconds > 0)
                Container(
                  height: 200,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _countdownSeconds == 5 ? 'Get Ready!' : '$_countdownSeconds',
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (_videoController != null && _videoController!.value.isInitialized)
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              const SizedBox(height: 20),
              if (!_isWorkoutStarted)
                Center(
                  child: ElevatedButton(
                    onPressed: _startWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB39DDB),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Start',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Card(
                color: Colors.black.withOpacity(0.5),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentExercise['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Target: ${currentExercise['duration'] ?? currentExercise['targetReps']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentExercise['desc'] ?? 'No description available.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'How to Perform:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentExercise['steps'] ?? 'No steps provided.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (_isWorkoutStarted)
                Center(
                  child: ElevatedButton(
                    onPressed: _nextExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB39DDB),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      widget.initialExercise == null && _exerciseIndex < _exercises.length - 1
                          ? 'Next Exercise'
                          : 'Finish',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}