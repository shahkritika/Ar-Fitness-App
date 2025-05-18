import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../utils/exercise_data.dart';
import '../../widgets/workout_summary.dart';

class StandardWorkoutPage extends StatefulWidget {
  final String workoutType;
  final String? initialExercise;

  const StandardWorkoutPage({
    Key? key,
    required this.workoutType,
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
    _exercises = ExerciseData.exercises[widget.workoutType] ?? [];
    if (widget.initialExercise != null) {
      _exerciseIndex = _exercises.indexWhere((e) => e['name'] == widget.initialExercise);
      if (_exerciseIndex == -1) _exerciseIndex = 0;
    }
    _stopwatch = Stopwatch();
    _loadVideo();
  }

  void _loadVideo() {
    _videoController?.dispose();
    String? videoPath = _exercises[_exerciseIndex]["video"];
    if (videoPath != null) {
      _videoController = VideoPlayerController.asset(videoPath)
        ..initialize().then((_) {
          setState(() {});
          if (_isWorkoutStarted) {
            _videoController!.play();
            _videoController!.setLooping(true);
          }
        }).catchError((error) {
          print('Video initialization error: $error');
        });
    } else {
      _videoController = null;
    }
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
      _stopwatch.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutSummary(
            totalReps: 0,
            goodReps: 0,
            badReps: 0,
            durationSeconds: _exerciseDurations[currentExercise['name']!] ?? 0,
            exerciseType: currentExercise['name']!.toLowerCase().replaceAll(' ', '_'),
            workoutType: widget.workoutType,
            mode: 'Standard',
            onDone: () => Navigator.pop(context),
          ),
        ),
      );
    }
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
    final currentExercise = _exercises[_exerciseIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB39DDB),
        title: Text(widget.workoutType),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Workout Time: ${_stopwatch.elapsed.inMinutes}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  if (widget.initialExercise == null)
                    Text(
                      "Exercise ${_exerciseIndex + 1} / ${_exercises.length}",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                    style: const TextStyle(
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
                    ),
                    child: const Text(
                      "Start",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Card(
                color: const Color(0xFF1E1E2C),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentExercise["name"]!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Duration/Reps: ${currentExercise["duration"] ?? currentExercise["reps"]}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentExercise["desc"]!,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "How to Perform:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentExercise["steps"]!,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isWorkoutStarted)
                Center(
                  child: ElevatedButton(
                    onPressed: _nextExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB39DDB),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      widget.initialExercise == null && _exerciseIndex < _exercises.length - 1
                          ? "Next Exercise"
                          : "Finish",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}