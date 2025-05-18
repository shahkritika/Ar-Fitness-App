import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class LandmarkPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize; // From CameraImage
  final Size widgetSize; // From Preview Widget
  final bool isFrontCamera;

  LandmarkPainter(this.pose, this.imageSize, this.widgetSize, this.isFrontCamera);

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) {
      print('No pose detected for rendering');
      return;
    }

    // Paint styles
    final dotPaint = Paint()
      ..color = const Color(0xFF00FF00) // Neon green
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF00FFFF) // Cyan
      ..strokeWidth = 3.0;

    final angleTextStyle = TextStyle(
      color: const Color(0xFFFF4444), // Neon red
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    );

    // Scaling and translation
    double scaleX = widgetSize.width / imageSize.width;
    double scaleY = widgetSize.height / imageSize.height;

    Offset translate(Offset point) {
      double x = point.dx * scaleX;
      double y = point.dy * scaleY;

      if (isFrontCamera) {
        x = widgetSize.width - x; // Mirror for front camera
      }

      print('Translating point (${point.dx}, ${point.dy}) to ($x, $y)');
      return Offset(x, y);
    }

    final landmarks = pose!.landmarks;

    // Helper to draw a landmark point
    void drawPoint(PoseLandmarkType type) {
      final landmark = landmarks[type];
      if (landmark != null && landmark.likelihood > 0.5) {
        final offset = translate(Offset(landmark.x, landmark.y));
        canvas.drawCircle(offset, 6.0, dotPaint);
        print('Drawing $type at $offset, likelihood=${landmark.likelihood}');
      } else {
        print('Skipping $type: likelihood=${landmark?.likelihood}');
      }
    }

    // Helper to draw a line between two landmarks
    void drawLine(PoseLandmarkType a, PoseLandmarkType b) {
      final start = landmarks[a];
      final end = landmarks[b];
      if (start != null && end != null && start.likelihood > 0.5 && end.likelihood > 0.5) {
        final startOffset = translate(Offset(start.x, start.y));
        final endOffset = translate(Offset(end.x, end.y));
        canvas.drawLine(startOffset, endOffset, linePaint);
        print('Drawing line from $startOffset to $endOffset');
      }
    }

    // Helper to calculate angle between three points (in degrees)
    double calculateAngle(Point<double> a, Point<double> b, Point<double> c) {
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

    // Helper to draw angle text near a joint
    void drawAngle(PoseLandmarkType p1, PoseLandmarkType p2, PoseLandmarkType p3, String label) {
      final point1 = landmarks[p1];
      final point2 = landmarks[p2];
      final point3 = landmarks[p3];
      if (point1 != null && point2 != null && point3 != null &&
          point1.likelihood > 0.5 && point2.likelihood > 0.5 && point3.likelihood > 0.5) {
        final a = Point(point1.x, point1.y);
        final b = Point(point2.x, point2.y);
        final c = Point(point3.x, point3.y);
        final angle = calculateAngle(a, b, c);

        final offset = translate(Offset(point2.x, point2.y));
        final textSpan = TextSpan(
          text: '${angle.toStringAsFixed(0)}°',
          style: angleTextStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, offset.translate(15, -15)); // Adjusted offset
        print('$label angle: ${angle.toStringAsFixed(0)}° at $offset');
      }
    }

    // Draw all landmarks as points
    for (var type in PoseLandmarkType.values) {
      drawPoint(type);
    }

    // Head and face connections
    drawLine(PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner);
    drawLine(PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner);
    drawLine(PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye);
    drawLine(PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter);
    drawLine(PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye);
    drawLine(PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter);
    drawLine(PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEar);
    drawLine(PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar);

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

    // Draw joint angles
    drawAngle(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, "Left Knee");
    drawAngle(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, "Right Knee");
    drawAngle(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, "Left Elbow");
    drawAngle(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, "Right Elbow");
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}