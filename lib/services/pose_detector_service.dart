import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/exercise_analyzer.dart';

class PoseDetectorService {
  final PoseDetector _poseDetector;
  ExerciseAnalyzer _exerciseAnalyzer;
  final Function(AnalysisResult, Pose?) onAnalysisComplete;
  String _currentExercise = 'squat';
  double _elapsedSeconds = 0.0;
  Timer? _timer;

  PoseDetectorService({required this.onAnalysisComplete})
      : _poseDetector = PoseDetector(options: PoseDetectorOptions()),
        _exerciseAnalyzer = ExerciseAnalyzer(exerciseType: 'squat') {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _elapsedSeconds += 0.1;
    });
  }

  void setCurrentExercise(String exercise) {
    _currentExercise = exercise.toLowerCase();
    _exerciseAnalyzer = ExerciseAnalyzer(exerciseType: _currentExercise);
  }

  Future<void> processImage(InputImage inputImage) async {
    try {
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final analysis = _exerciseAnalyzer.processPose(pose, _elapsedSeconds);
        onAnalysisComplete(analysis, pose);
      } else {
        onAnalysisComplete(
          AnalysisResult(
            feedback: 'No person detected',
            formFeedback: '',
            reps: 0,
            goodReps: 0,
            badReps: 0,
            isComplete: false,
            isGoodForm: false,
            durationSeconds: _elapsedSeconds,
          ),
          null,
        );
      }
    } catch (e) {
      debugPrint("Pose detection failed: $e");
      onAnalysisComplete(
        AnalysisResult(
          feedback: 'Error analyzing pose',
          formFeedback: '',
          reps: 0,
          goodReps: 0,
          badReps: 0,
          isComplete: false,
          isGoodForm: false,
          durationSeconds: _elapsedSeconds,
        ),
        null,
      );
    }
  }

  void reset() {
    _exerciseAnalyzer.reset();
    _elapsedSeconds = 0.0;
  }

  void dispose() {
    _timer?.cancel();
    _poseDetector.close();
  }
}