import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class LandmarkPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize; // From CameraImage
  final Size widgetSize; // From Preview Widget
  final bool isFrontCamera;

  LandmarkPainter(this.pose, this.imageSize, this.widgetSize, this.isFrontCamera);

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final dotPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;

    double scaleX = widgetSize.width / imageSize.width;
    double scaleY = widgetSize.height / imageSize.height;

    Offset translate(Offset point) {
      double x = point.dx * scaleX;
      double y = point.dy * scaleY;

      if (isFrontCamera) {
        x = widgetSize.width - x;
      }

      return Offset(x, y);
    }

    final landmarks = pose!.landmarks;

    void drawPoint(PoseLandmarkType type) {
      final landmark = landmarks[type];
      if (landmark != null) {
        final offset = translate(Offset(landmark.x, landmark.y));
        canvas.drawCircle(offset, 4.0, dotPaint);
      }
    }

    void drawLine(PoseLandmarkType a, PoseLandmarkType b) {
      final start = landmarks[a];
      final end = landmarks[b];
      if (start != null && end != null) {
        canvas.drawLine(
          translate(Offset(start.x, start.y)),
          translate(Offset(end.x, end.y)),
          linePaint,
        );
      }
    }

    // Draw all points
    for (var landmark in landmarks.values) {
      final offset = translate(Offset(landmark.x, landmark.y));
      canvas.drawCircle(offset, 4.0, dotPaint);
    }

    // Torso
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

    // Arms
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Hands
    drawLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb);
    drawLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex);
    drawLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky);

    drawLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb);
    drawLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex);
    drawLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky);

    // Legs
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // Feet
    drawLine(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel);
    drawLine(PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex);

    drawLine(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel);
    drawLine(PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
