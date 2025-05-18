import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class AnalysisResult {
  final String feedback;
  final String formFeedback;
  final int reps;
  final int goodReps;
  final int badReps;
  final bool isComplete;
  final bool isGoodForm;
  final double durationSeconds; // For timed exercises

  AnalysisResult({
    required this.feedback,
    required this.formFeedback,
    required this.reps,
    required this.goodReps,
    required this.badReps,
    required this.isComplete,
    required this.isGoodForm,
    this.durationSeconds = 0.0,
  });
}

class ExerciseAnalyzer {
  final String exerciseType;
  int _repCount = 0;
  int _goodReps = 0;
  int _badReps = 0;
  bool _isDown = false;
  final int _targetReps;
  double _durationSeconds = 0.0;
  final double _targetDuration;
  bool _isPoseHeld = false;
  final Map<String, Map<String, dynamic>> _thresholds = {
    'squat': {
      'downThreshold': 110.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'pushup': {
      'downThreshold': 100.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist'],
      'isRepBased': true,
    },
    'deadlift': {
      'downThreshold': 100.0,
      'upThreshold': 140.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'bench_press': {
      'downThreshold': 90.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist'],
      'isRepBased': true,
    },
    'lunge': {
      'downThreshold': 100.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'plank': {
      'targetDuration': 40.0,
      'alignmentThreshold': 10.0,
      'landmarks': ['leftShoulder', 'leftHip', 'leftAnkle', 'rightShoulder', 'rightHip', 'rightAnkle'],
      'isRepBased': false,
    },
    'jumping_jacks': {
      'downThreshold': 90.0,
      'upThreshold': 150.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist'],
      'isRepBased': true,
    },
    'mountain_climbers': {
      'downThreshold': 90.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'running_in_place': {
      'downThreshold': 90.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'skaters': {
      'downThreshold': 100.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'butt_kicks': {
      'downThreshold': 90.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'jump_rope': {
      'downThreshold': 90.0,
      'upThreshold': 110.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist'],
      'isRepBased': true,
    },
    'downward_dog': {
      'targetDuration': 30.0,
      'alignmentThreshold': 10.0,
      'landmarks': ['leftShoulder', 'leftHip', 'leftAnkle', 'rightShoulder', 'rightHip', 'rightAnkle'],
      'isRepBased': false,
    },
    'tree_pose': {
      'targetDuration': 30.0,
      'alignmentThreshold': 10.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': false,
    },
    'warrior_ii': {
      'targetDuration': 30.0,
      'alignmentThreshold': 10.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': false,
    },
    'child_pose': {
      'targetDuration': 30.0,
      'alignmentThreshold': 10.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': false,
    },
    'bridge_pose': {
      'targetDuration': 30.0,
      'alignmentThreshold': 10.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': false,
    },
    'seated_forward_bend': {
      'targetDuration': 30.0,
      'alignmentThreshold': 10.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': false,
    },
    'burpees': {
      'downThreshold': 100.0,
      'upThreshold': 140.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'high_knees': {
      'downThreshold': 90.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'jump_squats': {
      'downThreshold': 110.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'lunges_with_jumps': {
      'downThreshold': 100.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'plank_to_pushup': {
      'downThreshold': 100.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist'],
      'isRepBased': true,
    },
  };

  ExerciseAnalyzer({
    required this.exerciseType,
    int targetReps = 10,
    double targetDuration = 30.0,
  }) : _targetReps = targetReps,
       _targetDuration = targetDuration {
    if (!_thresholds.containsKey(exerciseType)) {
      print('Warning: Unsupported exercise type: $exerciseType. Supported types: ${_thresholds.keys}');
    }
  }

  double _calculateAngle(Point<double> a, Point<double> b, Point<double> c) {
    final abX = a.x - b.x;
    final abY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;

    final dotProduct = abX * bcX + abY * bcY;
    final magnitudeAB = sqrt(abX * abX + abY * abY);
    final magnitudeBC = sqrt(bcX * bcX + bcY * bcY);

    final cosineAngle = dotProduct / (magnitudeAB * magnitudeBC);
    return acos(cosineAngle.clamp(-1.0, 1.0)) * 180 / pi;
  }

  double _calculateAlignment(Pose pose, List<String> landmarks) {
    final points = landmarks.map((name) {
      final landmark = pose.landmarks[PoseLandmarkType.values.firstWhere((e) => e.toString().split('.').last == name)];
      return landmark != null ? Point<double>(landmark.x, landmark.y) : null;
    }).toList();

    if (points.any((p) => p == null)) return double.infinity;

    double totalDeviation = 0.0;
    for (int i = 0; i < points.length - 2; i += 3) {
      final angle = _calculateAngle(points[i]!, points[i + 1]!, points[i + 2]!);
      totalDeviation += (angle - 180.0).abs();
    }
    return totalDeviation / (points.length ~/ 3);
  }

  AnalysisResult processPose(Pose pose, double elapsedSeconds) {
    if (!_thresholds.containsKey(exerciseType)) {
      return AnalysisResult(
        feedback: 'Unsupported exercise: $exerciseType',
        formFeedback: 'Please select a valid exercise',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final thresholds = _thresholds[exerciseType]!;
    final isRepBased = thresholds['isRepBased'] as bool;
    final landmarks = thresholds['landmarks'] as List<String>;
    String feedback = 'Get in starting position';
    String formFeedback = '';
    bool isGoodForm = true;

    _durationSeconds = elapsedSeconds;

    if (isRepBased) {
      double? angle1, angle2;
      final landmarkTypes = landmarks.map((name) => PoseLandmarkType.values.firstWhere((e) => e.toString().split('.').last == name)).toList();

      final leftLandmarks = landmarkTypes.sublist(0, 3);
      final rightLandmarks = landmarkTypes.sublist(3, 6);
      final leftPoints = leftLandmarks.map((type) => pose.landmarks[type]).toList();
      final rightPoints = rightLandmarks.map((type) => pose.landmarks[type]).toList();

      if (leftPoints.every((p) => p != null && p.likelihood > 0.5)) {
        angle1 = _calculateAngle(
          Point(leftPoints[0]!.x, leftPoints[0]!.y),
          Point(leftPoints[1]!.x, leftPoints[1]!.y),
          Point(leftPoints[2]!.x, leftPoints[2]!.y),
        );
      }

      if (rightPoints.every((p) => p != null && p.likelihood > 0.5)) {
        angle2 = _calculateAngle(
          Point(rightPoints[0]!.x, rightPoints[0]!.y),
          Point(rightPoints[1]!.x, rightPoints[1]!.y),
          Point(rightPoints[2]!.x, rightPoints[2]!.y),
        );
      }

      final downThreshold = thresholds['downThreshold'] as double?;
      final upThreshold = thresholds['upThreshold'] as double?;
      final angleDiffThreshold = thresholds['angleDiffThreshold'] as double?;

      double? effectiveAngle;
      if (angle1 != null && angle2 != null) {
        effectiveAngle = (angle1 + angle2) / 2;
        final angleDiff = (angle1 - angle2).abs();
        isGoodForm = angleDiff <= angleDiffThreshold!;
      } else if (angle1 != null) {
        effectiveAngle = angle1;
      } else if (angle2 != null) {
        effectiveAngle = angle2;
      }

      if (effectiveAngle != null) {
        if (!_isDown && effectiveAngle < downThreshold!) {
          _isDown = true;
          feedback = 'Going down...';
          formFeedback = isGoodForm ? 'Good form!' : 'Keep joints aligned';
        } else if (_isDown && effectiveAngle > upThreshold!) {
          _isDown = false;
          _repCount++;
          if (isGoodForm) {
            _goodReps++;
            feedback = 'Good rep!';
          } else {
            _badReps++;
            feedback = 'Rep counted, adjust form';
          }
          formFeedback = isGoodForm ? 'Great!' : 'Align joints';
        } else {
          feedback = _isDown ? 'Push up!' : 'Go down!';
          formFeedback = isGoodForm ? '' : 'Align joints';
        }
      } else {
        feedback = 'Position joints in frame';
        formFeedback = 'Ensure all joints are visible';
      }

      return AnalysisResult(
        feedback: feedback,
        formFeedback: formFeedback,
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: isGoodForm,
        durationSeconds: _durationSeconds,
      );
    } else {
      final alignmentDeviation = _calculateAlignment(pose, landmarks);
      isGoodForm = alignmentDeviation <= (thresholds['alignmentThreshold'] as double);
      if (alignmentDeviation < (thresholds['alignmentThreshold'] as double)) {
        if (!_isPoseHeld) {
          _isPoseHeld = true;
          feedback = 'Holding pose...';
        } else {
          feedback = 'Keep holding!';
        }
        formFeedback = isGoodForm ? 'Good form!' : 'Adjust alignment';
      } else {
        _isPoseHeld = false;
        feedback = 'Align body correctly';
        formFeedback = 'Ensure straight line or proper pose';
      }

      return AnalysisResult(
        feedback: feedback,
        formFeedback: formFeedback,
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _durationSeconds >= _targetDuration,
        isGoodForm: isGoodForm,
        durationSeconds: _durationSeconds,
      );
    }
  }

  void reset() {
    _repCount = 0;
    _goodReps = 0;
    _badReps = 0;
    _isDown = false;
    _durationSeconds = 0.0;
    _isPoseHeld = false;
  }
}