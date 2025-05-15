import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class AnalysisResult {
  final String feedback;
  final String formFeedback;
  final int reps;
  final int goodReps;
  final int badReps;
  final bool isComplete;

  AnalysisResult({
    required this.feedback,
    required this.formFeedback,
    required this.reps,
    required this.goodReps,
    required this.badReps,
    required this.isComplete,
  });
}

class ExerciseAnalyzer {
  final String exerciseType;
  int _repCount = 0;
  int _goodReps = 0;
  int _badReps = 0;
  bool _isDown = false;
  final int _targetReps;
  final Map<String, Map<String, dynamic>> _thresholds = {
    'squat': {
      'downThreshold': 110.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
    },
    'pushup': {
      'downThreshold': 100.0,
      'upThreshold': 130.0,
      'angleDiffThreshold': 15.0,
    },
  };

  ExerciseAnalyzer({
    required this.exerciseType,
    int targetReps = 10,
  }) : _targetReps = targetReps {
    if (!_thresholds.containsKey(exerciseType)) {
      print('Warning: Unsupported exercise type: $exerciseType. Supported types: ${_thresholds.keys}');
    }
  }

  double _calculateAngle(Point<double> a, Point<double> b, Point<double> c) {
    double abX = a.x - b.x;
    double abY = a.y - b.y;
    double bcX = c.x - b.x;
    double bcY = c.y - b.y;

    double dotProduct = abX * bcX + abY * bcY;
    double magnitudeAB = sqrt(abX * abX + abY * abY);
    double magnitudeBC = sqrt(bcX * bcX + bcY * bcY);

    double cosineAngle = dotProduct / (magnitudeAB * magnitudeBC);
    cosineAngle = cosineAngle.clamp(-1.0, 1.0);
    return acos(cosineAngle) * 180 / pi;
  }

  AnalysisResult processPose(Pose pose) {
    if (!_thresholds.containsKey(exerciseType)) {
      return AnalysisResult(
        feedback: 'Unsupported exercise: $exerciseType',
        formFeedback: 'Please select squat or pushup',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
      );
    }

    final landmarks = pose.landmarks;
    double? angle1, angle2;
    String feedback = 'Get in starting position';
    String formFeedback = '';

    print('Processing pose for $exerciseType. Landmarks detected: ${landmarks.keys}');

    if (exerciseType == 'squat') {
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final leftKnee = landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
      if (leftHip != null && leftKnee != null && leftAnkle != null &&
          leftHip.likelihood > 0.5 && leftKnee.likelihood > 0.5 && leftAnkle.likelihood > 0.5) {
        angle1 = _calculateAngle(
          Point(leftHip.x, leftHip.y),
          Point(leftKnee.x, leftKnee.y),
          Point(leftAnkle.x, leftAnkle.y),
        );
        print('Left knee angle: ${angle1.toStringAsFixed(0)}°');
      } else {
        print('Left knee landmarks missing or low confidence: '
            'Hip: ${leftHip?.likelihood}, Knee: ${leftKnee?.likelihood}, Ankle: ${leftAnkle?.likelihood}');
      }

      final rightHip = landmarks[PoseLandmarkType.rightHip];
      final rightKnee = landmarks[PoseLandmarkType.rightKnee];
      final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
      if (rightHip != null && rightKnee != null && rightAnkle != null &&
          rightHip.likelihood > 0.5 && rightKnee.likelihood > 0.5 && rightAnkle.likelihood > 0.5) {
        angle2 = _calculateAngle(
          Point(rightHip.x, rightHip.y),
          Point(rightKnee.x, rightKnee.y),
          Point(rightAnkle.x, rightAnkle.y),
        );
        print('Right knee angle: ${angle2.toStringAsFixed(0)}°');
      } else {
        print('Right knee landmarks missing or low confidence: '
            'Hip: ${rightHip?.likelihood}, Knee: ${rightKnee?.likelihood}, Ankle: ${rightAnkle?.likelihood}');
      }
    } else if (exerciseType == 'pushup') {
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final leftElbow = landmarks[PoseLandmarkType.leftElbow];
      final leftWrist = landmarks[PoseLandmarkType.leftWrist];
      if (leftShoulder != null && leftElbow != null && leftWrist != null &&
          leftShoulder.likelihood > 0.5 && leftElbow.likelihood > 0.5 && leftWrist.likelihood > 0.5) {
        angle1 = _calculateAngle(
          Point(leftShoulder.x, leftShoulder.y),
          Point(leftElbow.x, leftElbow.y),
          Point(leftWrist.x, leftWrist.y),
        );
        print('Left elbow angle: ${angle1.toStringAsFixed(0)}°');
      } else {
        print('Left elbow landmarks missing or low confidence: '
            'Shoulder: ${leftShoulder?.likelihood}, Elbow: ${leftElbow?.likelihood}, Wrist: ${leftWrist?.likelihood}');
      }

      final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
      final rightElbow = landmarks[PoseLandmarkType.rightElbow];
      final rightWrist = landmarks[PoseLandmarkType.rightWrist];
      if (rightShoulder != null && rightElbow != null && rightWrist != null &&
          rightShoulder.likelihood > 0.5 && rightElbow.likelihood > 0.5 && rightWrist.likelihood > 0.5) {
        angle2 = _calculateAngle(
          Point(rightShoulder.x, rightShoulder.y),
          Point(rightElbow.x, rightElbow.y),
          Point(rightWrist.x, rightWrist.y),
        );
        print('Right elbow angle: ${angle2.toStringAsFixed(0)}°');
      } else {
        print('Right elbow landmarks missing or low confidence: '
            'Shoulder: ${rightShoulder?.likelihood}, Elbow: ${rightElbow?.likelihood}, Wrist: ${rightWrist?.likelihood}');
      }
    }

    final thresholds = _thresholds[exerciseType];
    if (thresholds == null) {
      return AnalysisResult(
        feedback: 'Invalid exercise type',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
      );
    }

    final downThreshold = thresholds['downThreshold']!;
    final upThreshold = thresholds['upThreshold']!;
    final angleDiffThreshold = thresholds['angleDiffThreshold']!;
    bool isGoodForm = true;

    double? effectiveAngle;
    if (angle1 != null && angle2 != null) {
      effectiveAngle = (angle1 + angle2) / 2;
      final angleDiff = (angle1 - angle2).abs();
      isGoodForm = angleDiff <= angleDiffThreshold;
      print('Angle difference: ${angleDiff.toStringAsFixed(0)}° (Good form: $isGoodForm)');
    } else if (angle1 != null) {
      effectiveAngle = angle1;
      isGoodForm = true;
    } else if (angle2 != null) {
      effectiveAngle = angle2;
      isGoodForm = true;
    }

    if (effectiveAngle != null) {
      if (!_isDown && effectiveAngle < downThreshold) {
        _isDown = true;
        feedback = 'Going down...';
        formFeedback = isGoodForm ? 'Good form!' : 'Keep joints aligned';
        print('$exerciseType: Down detected (Effective: ${effectiveAngle.toStringAsFixed(0)}°)');
      } else if (_isDown && effectiveAngle > upThreshold) {
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
        print('$exerciseType: Rep counted! Total: $_repCount (Effective: ${effectiveAngle.toStringAsFixed(0)}°)');
      } else {
        feedback = _isDown ? 'Push up!' : 'Go down!';
        formFeedback = isGoodForm ? '' : 'Align joints';
      }
    } else {
      feedback = 'Position joints in frame';
      formFeedback = 'Ensure all joints are visible';
    }

    bool isComplete = _repCount >= _targetReps;

    return AnalysisResult(
      feedback: feedback,
      formFeedback: formFeedback,
      reps: _repCount,
      goodReps: _goodReps,
      badReps: _badReps,
      isComplete: isComplete,
    );
  }

  void reset() {
    _repCount = 0;
    _goodReps = 0;
    _badReps = 0;
    _isDown = false;
  }
}