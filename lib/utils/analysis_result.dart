// lib/utils/analysis_result.dart
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