import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;

/// This class handles analyzing poses, counting reps, and giving feedback.
class ExerciseAnalyzer {
  int reps = 0;
  bool _isDown = false;
  bool _isUp = true;
  String feedback = 'Start exercising...';

  /// Call this method on every new pose detected
  String analyzePose(Pose pose, String workoutType) {
    switch (workoutType.toLowerCase()) {
      case 'bicep curl':
        return _analyzeBicepCurl(pose);
      case 'squat':
        return _analyzeSquat(pose);
      default:
        return 'Unsupported workout';
    }
  }

  /// Analyze bicep curl exercise using elbow angle
  String _analyzeBicepCurl(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (shoulder == null || elbow == null || wrist == null) return 'Position not detected';

    final angle = _calculateAngle(
      Offset(shoulder.x, shoulder.y),
      Offset(elbow.x, elbow.y),
      Offset(wrist.x, wrist.y),
    );

    if (angle > 160) {
      _isUp = true;
      if (_isDown) {
        reps++;
        _isDown = false;
        feedback = 'Good job! Reps: $reps';
      }
    }

    if (angle < 60) {
      _isDown = true;
      feedback = 'Curl up!';
    }

    return feedback;
  }

  /// Analyze squat using knee angle
  String _analyzeSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (hip == null || knee == null || ankle == null) return 'Position not detected';

    final angle = _calculateAngle(
      Offset(hip.x, hip.y),
      Offset(knee.x, knee.y),
      Offset(ankle.x, ankle.y),
    );

    if (angle > 160) {
      _isUp = true;
      if (_isDown) {
        reps++;
        _isDown = false;
        feedback = 'Nice! Reps: $reps';
      }
    }

    if (angle < 100) {
      _isDown = true;
      feedback = 'Go lower!';
    }

    return feedback;
  }

  /// Calculates angle between three points
  double _calculateAngle(Offset a, Offset b, Offset c) {
    final ab = vector.Vector2(a.dx - b.dx, a.dy - b.dy);
    final cb = vector.Vector2(c.dx - b.dx, c.dy - b.dy);

    final angle = vector.degrees(vector.acos(ab.dot(cb) / (ab.length * cb.length)));
    return angle;
  }
}
