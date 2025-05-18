// exercise_feedback.dart
Map<String, dynamic> exerciseFeedback = {
  'Squats': (Map<String, double> poseData) {
    if (!(poseData['backStraight'] ?? true)) {
      return 'Straighten your back.';
    } else if (poseData['kneeAngle'] != null && poseData['kneeAngle'] < 80) {
      return 'Bend your knees deeper.';
    } else {
      return 'Good job! Keep going.';
    }
  },
  'Pushups': (Map<String, double> poseData) {
    if (poseData['elbowAngle'] != null && poseData['elbowAngle'] < 90) {
      return 'Lower your body further.';
    } else {
      return 'Great form! Keep pushing.';
    }
  },
  'Plank': (Map<String, double> poseData) {
    if (poseData['bodyAlignment'] != null && poseData['bodyAlignment'] < 0.9) {
      return 'Straighten your back!';
    } else {
      return 'Nice! Keep holding.';
    }
  },
  // Add more exercises as needed
};
