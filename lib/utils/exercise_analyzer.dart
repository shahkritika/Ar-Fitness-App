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
  final double durationSeconds;

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
  bool _isLeftLegForward = false;
  bool _hasReachedBottom = false;
  final int _targetReps;
  double _durationSeconds = 0.0;
  final double _targetDuration;
  double _heightScale = 1.0;
  bool _isCalibrated = false;
  double _lastStandingAngle = 175.0;

  bool get isCalibrated => _isCalibrated;

  final Map<String, Map<String, dynamic>> _thresholds = {
    'squat': {
      'downThreshold': 110.0,
      'upThreshold': 160.0,
      'fullDepthThreshold': 90.0,
      'angleDiffThreshold': 20.0,
      'hysteresis': 3.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'pushup': {
      'downThreshold': 100.0,
      'upThreshold': 150.0,
      'fullDepthThreshold': 90.0,
      'angleDiffThreshold': 15.0,
      'hysteresis': 3.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist'],
      'isRepBased': true,
    },
    'deadlift': {
      'downThreshold': 50.0,
      'upThreshold': 15.0,
      'backAlignmentThreshold': 15.0,
      'kneeAlignmentThreshold': 10.0,
      'hysteresis': 3.0,
      'landmarks': ['leftShoulder', 'leftHip', 'leftKnee', 'rightShoulder', 'rightHip', 'rightKnee'],
      'isRepBased': true,
    },
    'bench_press': {
      'downThreshold': 100.0,
      'upThreshold': 150.0,
      'wristAlignmentThreshold': 20.0,
      'hysteresis': 3.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist'],
      'isRepBased': true,
    },
    'lunge': {
      'downThreshold': 100.0,
      'upThreshold': 150.0,
      'kneeOverAnkleThreshold': 20.0,
      'hysteresis': 3.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'plank': {
      'targetDuration': 40.0,
      'alignmentThreshold': 10.0,
      'hipStabilityThreshold': 15.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftHip', 'rightShoulder', 'rightElbow', 'rightHip'],
      'isRepBased': false,
    },
    'jumping_jacks': {
      'downThreshold': 100.0,
      'upThreshold': 140.0,
      'hipDistanceThreshold': 0.3,
      'hysteresis': 3.0,
      'landmarks': ['leftShoulder', 'leftElbow', 'leftWrist', 'rightShoulder', 'rightElbow', 'rightWrist', 'leftHip', 'rightHip'],
      'isRepBased': true,
    },
    'mountain_climbers': {
      'downThreshold': 100.0,
      'upThreshold': 120.0,
      'hipStabilityThreshold': 15.0,
      'hysteresis': 3.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'running_in_place': {
      'downThreshold': 100.0,
      'upThreshold': 120.0,
      'kneeHeightThreshold': 0.3,
      'hysteresis': 3.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
    'high_knees': {
      'downThreshold': 100.0,
      'upThreshold': 120.0,
      'kneeHeightThreshold': 0.4,
      'hysteresis': 3.0,
      'landmarks': ['leftHip', 'leftKnee', 'leftAnkle', 'rightHip', 'rightKnee', 'rightAnkle'],
      'isRepBased': true,
    },
  };

  ExerciseAnalyzer({
    required this.exerciseType,
    int targetReps = 10,
    double targetDuration = 40.0,
  })  : _targetReps = targetReps,
        _targetDuration = targetDuration {
    if (!_thresholds.containsKey(exerciseType.toLowerCase())) {
      print('Warning: Unsupported exercise type: $exerciseType. Supported types: ${_thresholds.keys}');
    }
  }

  void calibrate(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (leftShoulder != null && leftAnkle != null && 
        leftShoulder.likelihood > 0.7 && leftAnkle.likelihood > 0.7) {
      _heightScale = (leftShoulder.y - leftAnkle.y).abs();
      _isCalibrated = true;
      print('Calibration complete: heightScale=$_heightScale');
    }
  }

  double _calculateAngle(Point a, Point b, Point c) {
    final ab = Point(a.x - b.x, a.y - b.y);
    final cb = Point(c.x - b.x, c.y - b.y);
    final dot = ab.x * cb.x + ab.y * cb.y;
    final magAB = sqrt(ab.x * ab.x + ab.y * ab.y);
    final magCB = sqrt(cb.x * cb.x + cb.y * cb.y);
    if (magAB == 0 || magCB == 0) return 0.0;
    final cosTheta = dot / (magAB * magCB);
    return acos(cosTheta.clamp(-1.0, 1.0)) * 180 / pi;
  }

  double _calculateDistance(Point a, Point b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  AnalysisResult _analyzeSquat(Pose pose) {
    final thresholds = _thresholds['squat']!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null || 
        rightHip == null || rightKnee == null || rightAnkle == null ||
        leftHip.likelihood < 0.7 || leftKnee.likelihood < 0.7 || leftAnkle.likelihood < 0.7 ||
        rightHip.likelihood < 0.7 || rightKnee.likelihood < 0.7 || rightAnkle.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep knees visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftAngle = _calculateAngle(
      Point(leftHip.x, leftHip.y),
      Point(leftKnee.x, leftKnee.y),
      Point(leftAnkle.x, leftAnkle.y),
    );
    final rightAngle = _calculateAngle(
      Point(rightHip.x, rightHip.y),
      Point(rightKnee.x, rightKnee.y),
      Point(rightAnkle.x, rightAnkle.y),
    );

    final avgAngle = (leftAngle + rightAngle) / 2;
    final angleDiff = (leftAngle - rightAngle).abs();
    final isGoodForm = angleDiff <= thresholds['angleDiffThreshold'];

    print('Squat: leftAngle=$leftAngle, rightAngle=$rightAngle, avgAngle=$avgAngle, isDown=$_isDown, hasReachedBottom=$_hasReachedBottom');

    String feedback;
    String formFeedback;

    if (!_isDown && avgAngle < (thresholds['downThreshold'] - thresholds['hysteresis'])) {
      _isDown = true;
      feedback = 'Lowering down...';
      if (avgAngle <= thresholds['fullDepthThreshold']) {
        _hasReachedBottom = true;
        formFeedback = isGoodForm ? 'Good depth!' : 'Go deeper';
      } else {
        formFeedback = isGoodForm ? 'Keep going' : 'Knees uneven';
      }
    } else if (_isDown && avgAngle > (thresholds['upThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      if (_hasReachedBottom) {
        _repCount++;
        if (isGoodForm) {
          _goodReps++;
          feedback = 'Good squat!';
        } else {
          _badReps++;
          feedback = 'Rep counted - fix form';
        }
        print('Squat rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      } else {
        feedback = 'Incomplete rep - go deeper';
      }
      _hasReachedBottom = false;
      formFeedback = isGoodForm ? 'Ready for next' : 'Align knees';
    } else if (_isDown) {
      if (avgAngle <= thresholds['fullDepthThreshold']) {
        _hasReachedBottom = true;
        feedback = 'Push up!';
        formFeedback = isGoodForm ? 'Good depth' : 'Knees uneven';
      } else {
        feedback = 'Go deeper';
        formFeedback = isGoodForm ? 'Lower slowly' : 'Keep knees aligned';
      }
    } else {
      feedback = 'Ready to squat';
      formFeedback = isGoodForm ? 'Good stance' : 'Feet shoulder-width';
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
  }

  AnalysisResult _analyzePushup(Pose pose) {
    final thresholds = _thresholds['pushup']!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || leftElbow == null || leftWrist == null || 
        rightShoulder == null || rightElbow == null || rightWrist == null ||
        leftShoulder.likelihood < 0.7 || leftElbow.likelihood < 0.7 || leftWrist.likelihood < 0.7 ||
        rightShoulder.likelihood < 0.7 || rightElbow.likelihood < 0.7 || rightWrist.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep arms visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftAngle = _calculateAngle(
      Point(leftShoulder.x, leftShoulder.y),
      Point(leftElbow.x, leftElbow.y),
      Point(leftWrist.x, leftWrist.y),
    );
    final rightAngle = _calculateAngle(
      Point(rightShoulder.x, rightShoulder.y),
      Point(rightElbow.x, rightElbow.y),
      Point(rightWrist.x, rightWrist.y),
    );

    final avgAngle = (leftAngle + rightAngle) / 2;
    final angleDiff = (leftAngle - rightAngle).abs();
    final isGoodForm = angleDiff <= thresholds['angleDiffThreshold'];

    print('Pushup: leftAngle=$leftAngle, rightAngle=$rightAngle, avgAngle=$avgAngle, isDown=$_isDown, hasReachedBottom=$_hasReachedBottom');

    String feedback;
    String formFeedback;

    if (!_isDown && avgAngle < (thresholds['downThreshold'] - thresholds['hysteresis'])) {
      _isDown = true;
      feedback = 'Lowering down...';
      if (avgAngle <= thresholds['fullDepthThreshold']) {
        _hasReachedBottom = true;
        formFeedback = isGoodForm ? 'Good depth!' : 'Go deeper';
      } else {
        formFeedback = isGoodForm ? 'Keep going' : 'Arms uneven';
      }
    } else if (_isDown && avgAngle > (thresholds['upThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      if (_hasReachedBottom) {
        _repCount++;
        if (isGoodForm) {
          _goodReps++;
          feedback = 'Good pushup!';
        } else {
          _badReps++;
          feedback = 'Rep counted - fix form';
        }
        print('Pushup rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      } else {
        feedback = 'Incomplete rep - go deeper';
      }
      _hasReachedBottom = false;
      formFeedback = isGoodForm ? 'Ready for next' : 'Align arms';
    } else if (_isDown) {
      if (avgAngle <= thresholds['fullDepthThreshold']) {
        _hasReachedBottom = true;
        feedback = 'Push up!';
        formFeedback = isGoodForm ? 'Good depth' : 'Arms uneven';
      } else {
        feedback = 'Go deeper';
        formFeedback = isGoodForm ? 'Lower slowly' : 'Keep arms aligned';
      }
    } else {
      feedback = 'Ready to pushup';
      formFeedback = isGoodForm ? 'Good form' : 'Keep body straight';
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
  }

  AnalysisResult _analyzeDeadlift(Pose pose) {
    final thresholds = _thresholds['deadlift']!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null || 
        rightShoulder == null || rightHip == null || rightKnee == null ||
        leftShoulder.likelihood < 0.7 || leftHip.likelihood < 0.7 || leftKnee.likelihood < 0.7 ||
        rightShoulder.likelihood < 0.7 || rightHip.likelihood < 0.7 || rightKnee.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep body visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftBackAngle = _calculateAngle(
      Point(leftShoulder.x, leftShoulder.y),
      Point(leftHip.x, leftHip.y),
      Point(leftKnee.x, leftKnee.y),
    );
    final rightBackAngle = _calculateAngle(
      Point(rightShoulder.x, rightShoulder.y),
      Point(rightHip.x, rightHip.y),
      Point(rightKnee.x, rightKnee.y),
    );

    final avgAngle = (leftBackAngle + rightBackAngle) / 2;
    final angleDiff = (leftBackAngle - rightBackAngle).abs();
    final isGoodForm = angleDiff <= thresholds['backAlignmentThreshold'] && 
                       (leftKnee.likelihood - rightKnee.likelihood).abs() < thresholds['kneeAlignmentThreshold'];

    print('Deadlift: leftBackAngle=$leftBackAngle, rightBackAngle=$rightBackAngle, avgAngle=$avgAngle, isDown=$_isDown, hasReachedBottom=$_hasReachedBottom');

    String feedback;
    String formFeedback;

    if (!_isDown && avgAngle > (thresholds['downThreshold'] + thresholds['hysteresis'])) {
      _isDown = true;
      feedback = 'Lowering down...';
      formFeedback = isGoodForm ? 'Good form' : 'Keep back straight';
    } else if (_isDown && avgAngle < (thresholds['upThreshold'] - thresholds['hysteresis'])) {
      _isDown = false;
      _repCount++;
      if (isGoodForm) {
        _goodReps++;
        feedback = 'Good deadlift!';
      } else {
        _badReps++;
        feedback = 'Rep counted - fix form';
      }
      print('Deadlift rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      formFeedback = isGoodForm ? 'Ready for next' : 'Align back and knees';
    } else if (_isDown) {
      feedback = 'Push up!';
      formFeedback = isGoodForm ? 'Good position' : 'Straighten back';
    } else {
      feedback = 'Ready to deadlift';
      formFeedback = isGoodForm ? 'Good stance' : 'Keep feet hip-width';
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
  }

  AnalysisResult _analyzeBenchPress(Pose pose) {
    final thresholds = _thresholds['bench_press']!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || leftElbow == null || leftWrist == null || 
        rightShoulder == null || rightElbow == null || rightWrist == null ||
        leftShoulder.likelihood < 0.7 || leftElbow.likelihood < 0.7 || leftWrist.likelihood < 0.7 ||
        rightShoulder.likelihood < 0.7 || rightElbow.likelihood < 0.7 || rightWrist.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep arms visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftAngle = _calculateAngle(
      Point(leftShoulder.x, leftShoulder.y),
      Point(leftElbow.x, leftElbow.y),
      Point(leftWrist.x, leftWrist.y),
    );
    final rightAngle = _calculateAngle(
      Point(rightShoulder.x, rightShoulder.y),
      Point(rightElbow.x, rightElbow.y),
      Point(rightWrist.x, rightWrist.y),
    );

    final wristDistance = _calculateDistance(
      Point(leftWrist.x, leftWrist.y),
      Point(rightWrist.x, rightWrist.y),
    ) / _heightScale;
    final isGoodForm = (leftAngle - rightAngle).abs() <= thresholds['wristAlignmentThreshold'];

    print('BenchPress: leftAngle=$leftAngle, rightAngle=$rightAngle, wristDistance=$wristDistance, isDown=$_isDown, hasReachedBottom=$_hasReachedBottom');

    String feedback;
    String formFeedback;

    if (!_isDown && leftAngle < (thresholds['downThreshold'] - thresholds['hysteresis']) &&
        rightAngle < (thresholds['downThreshold'] - thresholds['hysteresis'])) {
      _isDown = true;
      feedback = 'Lowering bar...';
      if (leftAngle <= thresholds['fullDepthThreshold'] && rightAngle <= thresholds['fullDepthThreshold']) {
        _hasReachedBottom = true;
        formFeedback = isGoodForm ? 'Good depth!' : 'Align wrists';
      } else {
        formFeedback = isGoodForm ? 'Keep going' : 'Keep wrists even';
      }
    } else if (_isDown && leftAngle > (thresholds['upThreshold'] + thresholds['hysteresis']) &&
               rightAngle > (thresholds['upThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      if (_hasReachedBottom) {
        _repCount++;
        if (isGoodForm) {
          _goodReps++;
          feedback = 'Good bench press!';
        } else {
          _badReps++;
          feedback = 'Rep counted - fix form';
        }
        print('BenchPress rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      } else {
        feedback = 'Incomplete rep - lower further';
      }
      _hasReachedBottom = false;
      formFeedback = isGoodForm ? 'Ready for next' : 'Align wrists';
    } else if (_isDown) {
      feedback = 'Push up!';
      formFeedback = isGoodForm ? 'Good position' : 'Keep wrists aligned';
    } else {
      feedback = 'Ready to press';
      formFeedback = isGoodForm ? 'Good form' : 'Grip bar evenly';
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
  }

  AnalysisResult _analyzeLunge(Pose pose) {
    final thresholds = _thresholds['lunge']!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null || 
        rightHip == null || rightKnee == null || rightAnkle == null ||
        leftHip.likelihood < 0.7 || leftKnee.likelihood < 0.7 || leftAnkle.likelihood < 0.7 ||
        rightHip.likelihood < 0.7 || rightKnee.likelihood < 0.7 || rightAnkle.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep legs visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final frontKnee = _isLeftLegForward ? leftKnee : rightKnee;
    final frontAnkle = _isLeftLegForward ? leftAnkle : rightAnkle;
    final backKnee = _isLeftLegForward ? rightKnee : leftKnee;
    final frontHip = _isLeftLegForward ? leftHip : rightHip;

    final frontAngle = _calculateAngle(
      Point(frontHip.x, frontHip.y),
      Point(frontKnee.x, frontKnee.y),
      Point(frontAnkle.x, frontAnkle.y),
    );
    final backAngle = _calculateAngle(
      Point(frontHip.x, frontHip.y),
      Point(backKnee.x, backKnee.y),
      Point(frontAnkle.x, frontAnkle.y),
    );

    final kneeOverAnkle = (frontKnee.x - frontAnkle.x).abs() / _heightScale;
    final isGoodForm = kneeOverAnkle <= thresholds['kneeOverAnkleThreshold'] && frontAngle <= thresholds['downThreshold'];

    print('Lunge: frontAngle=$frontAngle, backAngle=$backAngle, kneeOverAnkle=$kneeOverAnkle, isDown=$_isDown, isLeftLegForward=$_isLeftLegForward');

    String feedback;
    String formFeedback;

    if (!_isDown && frontAngle < (thresholds['downThreshold'] - thresholds['hysteresis'])) {
      _isDown = true;
      feedback = 'Lowering down...';
      formFeedback = isGoodForm ? 'Good lunge!' : 'Keep front knee over ankle';
    } else if (_isDown && frontAngle > (thresholds['upThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      _repCount++;
      if (isGoodForm) {
        _goodReps++;
        feedback = 'Good lunge!';
      } else {
        _badReps++;
        feedback = 'Rep counted - fix form';
      }
      _isLeftLegForward = !_isLeftLegForward; // Switch legs
      print('Lunge rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps, leg=${_isLeftLegForward ? 'left' : 'right'}');
      formFeedback = isGoodForm ? 'Switch legs' : 'Align knee';
    } else if (_isDown) {
      feedback = 'Push up!';
      formFeedback = isGoodForm ? 'Good depth' : 'Knee too far forward';
    } else {
      feedback = 'Ready to lunge';
      formFeedback = isGoodForm ? 'Good stance' : 'Step forward';
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
  }

  AnalysisResult _analyzePlank(Pose pose) {
    final thresholds = _thresholds['plank']!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || leftElbow == null || leftHip == null || 
        rightShoulder == null || rightElbow == null || rightHip == null ||
        leftShoulder.likelihood < 0.7 || leftElbow.likelihood < 0.7 || leftHip.likelihood < 0.7 ||
        rightShoulder.likelihood < 0.7 || rightElbow.likelihood < 0.7 || rightHip.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep body visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _durationSeconds >= thresholds['targetDuration'],
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftAlignment = _calculateAngle(
      Point(leftShoulder.x, leftShoulder.y),
      Point(leftElbow.x, leftElbow.y),
      Point(leftHip.x, leftHip.y),
    );
    final rightAlignment = _calculateAngle(
      Point(rightShoulder.x, rightShoulder.y),
      Point(rightElbow.x, rightElbow.y),
      Point(rightHip.x, rightHip.y),
    );

    final hipDeviation = (leftHip.y - rightHip.y).abs() / _heightScale;
    final isGoodForm = (leftAlignment - 180.0).abs() <= thresholds['alignmentThreshold'] &&
                       (rightAlignment - 180.0).abs() <= thresholds['alignmentThreshold'] &&
                       hipDeviation <= thresholds['hipStabilityThreshold'];

    print('Plank: leftAlignment=$leftAlignment, rightAlignment=$rightAlignment, hipDeviation=$hipDeviation, duration=$_durationSeconds');

    String feedback = _durationSeconds < thresholds['targetDuration']
        ? 'Hold position: ${_durationSeconds.toStringAsFixed(1)}s'
        : 'Plank complete!';
    String formFeedback = isGoodForm ? 'Great form!' : 'Keep body straight';

    return AnalysisResult(
      feedback: feedback,
      formFeedback: formFeedback,
      reps: _repCount,
      goodReps: _goodReps,
      badReps: _badReps,
      isComplete: _durationSeconds >= thresholds['targetDuration'],
      isGoodForm: isGoodForm,
      durationSeconds: _durationSeconds,
    );
  }

  AnalysisResult _analyzeJumpingJacks(Pose pose) {
    final thresholds = _thresholds['jumping_jacks']!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || leftElbow == null || leftWrist == null || 
        rightShoulder == null || rightElbow == null || rightWrist == null ||
        leftHip == null || rightHip == null ||
        leftShoulder.likelihood < 0.7 || leftElbow.likelihood < 0.7 || leftWrist.likelihood < 0.7 ||
        rightShoulder.likelihood < 0.7 || rightElbow.likelihood < 0.7 || rightWrist.likelihood < 0.7 ||
        leftHip.likelihood < 0.7 || rightHip.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep arms and hips visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftArmAngle = _calculateAngle(
      Point(leftShoulder.x, leftShoulder.y),
      Point(leftElbow.x, leftElbow.y),
      Point(leftWrist.x, leftWrist.y),
    );
    final rightArmAngle = _calculateAngle(
      Point(rightShoulder.x, rightShoulder.y),
      Point(rightElbow.x, rightElbow.y),
      Point(rightWrist.x, rightWrist.y),
    );

    final hipDistance = _calculateDistance(
      Point(leftHip.x, leftHip.y),
      Point(rightHip.x, rightHip.y),
    ) / _heightScale;

    final isGoodForm = hipDistance >= thresholds['hipDistanceThreshold'] &&
                       leftArmAngle >= thresholds['upThreshold'] &&
                       rightArmAngle >= thresholds['upThreshold'];

    print('JumpingJacks: leftArmAngle=$leftArmAngle, rightArmAngle=$rightArmAngle, hipDistance=$hipDistance, isDown=$_isDown');

    String feedback;
    String formFeedback;

    if (!_isDown && leftArmAngle > (thresholds['upThreshold'] - thresholds['hysteresis']) &&
        rightArmAngle > (thresholds['upThreshold'] - thresholds['hysteresis'])) {
      _isDown = true;
      feedback = 'Arms up!';
      formFeedback = isGoodForm ? 'Good jump!' : 'Spread legs wider';
    } else if (_isDown && leftArmAngle < (thresholds['downThreshold'] + thresholds['hysteresis']) &&
               rightArmAngle < (thresholds['downThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      _repCount++;
      if (isGoodForm) {
        _goodReps++;
        feedback = 'Good jumping jack!';
      } else {
        _badReps++;
        feedback = 'Rep counted - fix form';
      }
      print('JumpingJacks rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      formFeedback = isGoodForm ? 'Ready for next' : 'Raise arms higher';
    } else if (_isDown) {
      feedback = 'Close legs!';
      formFeedback = isGoodForm ? 'Good form' : 'Spread legs more';
    } else {
      feedback = 'Ready for jumping jack';
      formFeedback = isGoodForm ? 'Good stance' : 'Stand with feet together';
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
  }

  AnalysisResult _analyzeMountainClimbers(Pose pose) {
    final thresholds = _thresholds['mountain_climbers']!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null || 
        rightHip == null || rightKnee == null || rightAnkle == null ||
        leftHip.likelihood < 0.7 || leftKnee.likelihood < 0.7 || leftAnkle.likelihood < 0.7 ||
        rightHip.likelihood < 0.7 || rightKnee.likelihood < 0.7 || rightAnkle.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep legs visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftAngle = _calculateAngle(
      Point(leftHip.x, leftHip.y),
      Point(leftKnee.x, leftKnee.y),
      Point(leftAnkle.x, leftAnkle.y),
    );
    final rightAngle = _calculateAngle(
      Point(rightHip.x, rightHip.y),
      Point(rightKnee.x, rightKnee.y),
      Point(rightAnkle.x, rightAnkle.y),
    );

    final hipDeviation = (leftHip.y - rightHip.y).abs() / _heightScale;
    final isGoodForm = hipDeviation <= thresholds['hipStabilityThreshold'] &&
                       (leftAngle <= thresholds['downThreshold'] || rightAngle <= thresholds['downThreshold']);

    print('MountainClimbers: leftAngle=$leftAngle, rightAngle=$rightAngle, hipDeviation=$hipDeviation, isDown=$_isDown');

    String feedback;
    String formFeedback;

    if (!_isDown && (leftAngle < (thresholds['downThreshold'] - thresholds['hysteresis']) ||
                     rightAngle < (thresholds['downThreshold'] - thresholds['hysteresis']))) {
      _isDown = true;
      feedback = 'Knee up!';
      formFeedback = isGoodForm ? 'Good form!' : 'Keep hips stable';
    } else if (_isDown && leftAngle > (thresholds['upThreshold'] + thresholds['hysteresis']) &&
               rightAngle > (thresholds['upThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      _repCount++;
      if (isGoodForm) {
        _goodReps++;
        feedback = 'Good mountain climber!';
      } else {
        _badReps++;
        feedback = 'Rep counted - fix form';
      }
      print('MountainClimbers rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      formFeedback = isGoodForm ? 'Switch legs' : 'Stabilize hips';
    } else if (_isDown) {
      feedback = 'Switch legs!';
      formFeedback = isGoodForm ? 'Good pace' : 'Keep hips level';
    } else {
      feedback = 'Ready for mountain climbers';
      formFeedback = isGoodForm ? 'Good plank' : 'Get into plank';
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
  }

  AnalysisResult _analyzeRunningInPlace(Pose pose) {
    final thresholds = _thresholds['running_in_place']!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null || 
        rightHip == null || rightKnee == null || rightAnkle == null ||
        leftHip.likelihood < 0.7 || leftKnee.likelihood < 0.7 || leftAnkle.likelihood < 0.7 ||
        rightHip.likelihood < 0.7 || rightKnee.likelihood < 0.7 || rightAnkle.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep legs visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftAngle = _calculateAngle(
      Point(leftHip.x, leftHip.y),
      Point(leftKnee.x, leftKnee.y),
      Point(leftAnkle.x, leftAnkle.y),
    );
    final rightAngle = _calculateAngle(
      Point(rightHip.x, rightHip.y),
      Point(rightKnee.x, rightKnee.y),
      Point(rightAnkle.x, rightAnkle.y),
    );

    final leftKneeHeight = (_heightScale - (leftKnee.y - leftHip.y)) / _heightScale;
    final rightKneeHeight = (_heightScale - (rightKnee.y - rightHip.y)) / _heightScale;

    final isGoodForm = leftKneeHeight > thresholds['kneeHeightThreshold'] || 
                       rightKneeHeight > thresholds['kneeHeightThreshold'];

    print('RunningInPlace: leftAngle=$leftAngle, rightAngle=$rightAngle, leftKneeHeight=$leftKneeHeight, rightKneeHeight=$rightKneeHeight, isDown=$_isDown');

    String feedback;
    String formFeedback;

    if (!_isDown && (leftAngle < (thresholds['downThreshold'] - thresholds['hysteresis']) ||
                     rightAngle < (thresholds['downThreshold'] - thresholds['hysteresis']))) {
      _isDown = true;
      feedback = 'Knee up!';
      formFeedback = isGoodForm ? 'Good height!' : 'Lift knees higher';
    } else if (_isDown && leftAngle > (thresholds['upThreshold'] + thresholds['hysteresis']) &&
               rightAngle > (thresholds['upThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      _repCount++;
      if (isGoodForm) {
        _goodReps++;
        feedback = 'Good stride!';
      } else {
        _badReps++;
        feedback = 'Rep counted - lift higher';
      }
      print('RunningInPlace rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      formFeedback = isGoodForm ? 'Keep running' : 'Raise knees more';
    } else if (_isDown) {
      feedback = 'Switch legs!';
      formFeedback = isGoodForm ? 'Good pace' : 'Lift knees higher';
    } else {
      feedback = 'Ready to run';
      formFeedback = isGoodForm ? 'Good stance' : 'Stand upright';
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
  }

  AnalysisResult _analyzeHighKnees(Pose pose) {
    final thresholds = _thresholds['high_knees']!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null || 
        rightHip == null || rightKnee == null || rightAnkle == null ||
        leftHip.likelihood < 0.7 || leftKnee.likelihood < 0.7 || leftAnkle.likelihood < 0.7 ||
        rightHip.likelihood < 0.7 || rightKnee.likelihood < 0.7 || rightAnkle.likelihood < 0.7) {
      return AnalysisResult(
        feedback: 'Keep legs visible',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: _repCount >= _targetReps,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    final leftAngle = _calculateAngle(
      Point(leftHip.x, leftHip.y),
      Point(leftKnee.x, leftKnee.y),
      Point(leftAnkle.x, leftAnkle.y),
    );
    final rightAngle = _calculateAngle(
      Point(rightHip.x, rightHip.y),
      Point(rightKnee.x, rightKnee.y),
      Point(rightAnkle.x, rightAnkle.y),
    );

    final leftKneeHeight = (_heightScale - (leftKnee.y - leftHip.y)) / _heightScale;
    final rightKneeHeight = (_heightScale - (rightKnee.y - rightHip.y)) / _heightScale;

    final isGoodForm = leftKneeHeight > thresholds['kneeHeightThreshold'] || 
                       rightKneeHeight > thresholds['kneeHeightThreshold'];

    print('HighKnees: leftAngle=$leftAngle, rightAngle=$rightAngle, leftKneeHeight=$leftKneeHeight, rightKneeHeight=$rightKneeHeight, isDown=$_isDown');

    String feedback;
    String formFeedback;

    if (!_isDown && (leftAngle < (thresholds['downThreshold'] - thresholds['hysteresis']) || 
                     rightAngle < (thresholds['downThreshold'] - thresholds['hysteresis']))) {
      _isDown = true;
      feedback = 'Knee up!';
      formFeedback = isGoodForm ? 'Good height!' : 'Lift knees higher';
    } else if (_isDown && leftAngle > (thresholds['upThreshold'] + thresholds['hysteresis']) && 
               rightAngle > (thresholds['upThreshold'] + thresholds['hysteresis'])) {
      _isDown = false;
      _repCount++;
      if (isGoodForm) {
        _goodReps++;
        feedback = 'Good high knee!';
      } else {
        _badReps++;
        feedback = 'Rep counted - lift higher';
      }
      print('HighKnees rep counted: total=$_repCount, good=$_goodReps, bad=$_badReps');
      formFeedback = isGoodForm ? 'Keep it up' : 'Raise knees more';
    } else if (_isDown) {
      feedback = 'Switch legs!';
      formFeedback = isGoodForm ? 'Good pace' : 'Lift knees higher';
    } else {
      feedback = 'Ready for high knees';
      formFeedback = isGoodForm ? 'Good stance' : 'Stand upright';
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
  }

  AnalysisResult processPose(Pose pose, double elapsedSeconds) {
    if (!_thresholds.containsKey(exerciseType.toLowerCase())) {
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

    if (!_isCalibrated) {
      calibrate(pose);
      return AnalysisResult(
        feedback: 'Stand still to calibrate',
        formFeedback: '',
        reps: _repCount,
        goodReps: _goodReps,
        badReps: _badReps,
        isComplete: false,
        isGoodForm: false,
        durationSeconds: _durationSeconds,
      );
    }

    _durationSeconds = elapsedSeconds;

    switch (exerciseType.toLowerCase()) {
      case 'squat':
        return _analyzeSquat(pose);
      case 'pushup':
        return _analyzePushup(pose);
      case 'deadlift':
        return _analyzeDeadlift(pose);
      case 'bench_press':
        return _analyzeBenchPress(pose);
      case 'lunge':
        return _analyzeLunge(pose);
      case 'plank':
        return _analyzePlank(pose);
      case 'jumping_jacks':
        return _analyzeJumpingJacks(pose);
      case 'mountain_climbers':
        return _analyzeMountainClimbers(pose);
      case 'running_in_place':
        return _analyzeRunningInPlace(pose);
      case 'high_knees':
        return _analyzeHighKnees(pose);
      default:
        return AnalysisResult(
          feedback: 'Exercise analysis not implemented',
          formFeedback: '',
          reps: _repCount,
          goodReps: _goodReps,
          badReps: _badReps,
          isComplete: _repCount >= _targetReps,
          isGoodForm: false,
          durationSeconds: _durationSeconds,
        );
    }
  }

  void reset() {
    _repCount = 0;
    _goodReps = 0;
    _badReps = 0;
    _isDown = false;
    _hasReachedBottom = false;
    _isCalibrated = false;
    _durationSeconds = 0.0;
    _isLeftLegForward = false;
    print('Analyzer reset: reps=0, calibrated=false');
  }
}