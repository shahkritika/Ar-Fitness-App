import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Callback with detected pose and calculated angles.
typedef PoseWithAnglesCallback = void Function(Pose? pose, Map<String, double> angles);

/// Service to detect body poses using ML Kit.
class PoseDetectorService {
  final PoseDetector _poseDetector;
  final PoseWithAnglesCallback onPoseDetected;

  /// Constructor initializes pose detector and sets callback
  PoseDetectorService({required this.onPoseDetected})
      : _poseDetector = PoseDetector(options: PoseDetectorOptions());

  /// Processes image and returns pose and joint angles
  Future<void> processImage(InputImage inputImage) async {
    try {
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        final Pose pose = poses.first;
        final Map<String, double> angles = _calculateJointAngles(pose);
        onPoseDetected(pose, angles);
      } else {
        onPoseDetected(null, {});
      }
    } catch (e) {
      debugPrint("Pose detection failed: $e");
      onPoseDetected(null, {});
    }
  }

  /// Calculate joint angles from landmarks using vector math
  Map<String, double> _calculateJointAngles(Pose pose) {
    double? angle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
      if (a == null || b == null || c == null) return null;

      final baX = a.x - b.x;
      final baY = a.y - b.y;
      final bcX = c.x - b.x;
      final bcY = c.y - b.y;

      final dotProduct = baX * bcX + baY * bcY;
      final magnitudeBA = sqrt(baX * baX + baY * baY);
      final magnitudeBC = sqrt(bcX * bcX + bcY * bcY);

      final cosineAngle = dotProduct / (magnitudeBA * magnitudeBC);
      final radians = acos(cosineAngle.clamp(-1.0, 1.0)); // Clamp avoids NaN
      return radians * (180 / pi);
    }

    final landmarks = pose.landmarks;

    return {
      // Arm joints
      'left_elbow': angle(
        landmarks[PoseLandmarkType.leftShoulder],
        landmarks[PoseLandmarkType.leftElbow],
        landmarks[PoseLandmarkType.leftWrist],
      ) ?? 0.0,
      'right_elbow': angle(
        landmarks[PoseLandmarkType.rightShoulder],
        landmarks[PoseLandmarkType.rightElbow],
        landmarks[PoseLandmarkType.rightWrist],
      ) ?? 0.0,

      // Leg joints
      'left_knee': angle(
        landmarks[PoseLandmarkType.leftHip],
        landmarks[PoseLandmarkType.leftKnee],
        landmarks[PoseLandmarkType.leftAnkle],
      ) ?? 0.0,
      'right_knee': angle(
        landmarks[PoseLandmarkType.rightHip],
        landmarks[PoseLandmarkType.rightKnee],
        landmarks[PoseLandmarkType.rightAnkle],
      ) ?? 0.0,

      // Shoulder joints (for posture/jumping jack detection)
      'left_shoulder': angle(
        landmarks[PoseLandmarkType.leftElbow],
        landmarks[PoseLandmarkType.leftShoulder],
        landmarks[PoseLandmarkType.leftHip],
      ) ?? 0.0,
      'right_shoulder': angle(
        landmarks[PoseLandmarkType.rightElbow],
        landmarks[PoseLandmarkType.rightShoulder],
        landmarks[PoseLandmarkType.rightHip],
      ) ?? 0.0,
    };
  }

  /// Close the detector when not needed
  void dispose() {
    _poseDetector.close();
  }
}
