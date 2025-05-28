import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../utils/exercise_analyzer.dart';
import '../../utils/exercise_data.dart';
import '../../widgets/landmark_painter.dart';
import '../../widgets/real_time_feedbacks_widget.dart';
import '../../widgets/workout_summary.dart';

class ARWorkoutPage extends StatefulWidget {
  final String workoutType;
  final String workoutCategory;
  final VoidCallback? onNextExercise;
  final int targetReps;
  final double targetDuration;
  final String? initialExercise;

  const ARWorkoutPage({
    Key? key,
    required this.workoutType,
    required this.workoutCategory,
    this.onNextExercise,
    this.targetReps = 10,
    this.targetDuration = 40.0,
    this.initialExercise,
  }) : super(key: key);

  @override
  State<ARWorkoutPage> createState() => _ARWorkoutPageState();
}

class _ARWorkoutPageState extends State<ARWorkoutPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isFrontCamera = true;
  bool _isSaving = false;
  bool _isCalibrated = false;

  Pose? _pose;
  late ExerciseAnalyzer _analyzer;
  late PoseDetector _poseDetector;

  String _feedback = 'Stand still to calibrate 😎';
  String _formFeedback = '';
  int _reps = 0;
  int _goodReps = 0;
  int _badReps = 0;
  double _durationSeconds = 0.0;
  bool _isExerciseComplete = false;
  bool _isRepBased = true;

  int _framesProcessed = 0;
  int _lastRepCount = 0;

  static const List<String> validWorkoutTypes = [
    'squat',
    'pushup',
    'deadlift',
    'bench_press',
    'lunge',
    'plank',
    'jumping_jacks',
    'mountain_climbers',
    'running_in_place',
    'high_knees',
  ];

  static const List<String> repBasedExercises = [
    'squat',
    'pushup',
    'deadlift',
    'bench_press',
    'lunge',
    'jumping_jacks',
    'mountain_climbers',
    'running_in_place',
    'high_knees',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    String normalizeWorkoutType(String input) {
      return input
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^\w_]'), '');
    }

    final rawExercise = widget.initialExercise ?? widget.workoutType;
    final workoutTypeLower = normalizeWorkoutType(rawExercise);
    print('ARWorkoutPage: Raw exercise: "$rawExercise", Normalized: "$workoutTypeLower", Category: "${widget.workoutCategory}"');

    final selectedWorkoutType = validWorkoutTypes.contains(workoutTypeLower)
        ? workoutTypeLower
        : 'squat';

    if (selectedWorkoutType != workoutTypeLower) {
      print('Invalid workoutType: "$rawExercise" (normalized: "$workoutTypeLower"). Defaulting to $selectedWorkoutType');
      print('Valid workout types: $validWorkoutTypes');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid exercise: "$rawExercise". Using squat.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      print('Selected workoutType: "$selectedWorkoutType"');
    }

    _isRepBased = repBasedExercises.contains(selectedWorkoutType);
    print('Rep-based: $_isRepBased');

    final exerciseData = ExerciseData.exercises[widget.workoutCategory]
            ?.firstWhere(
              (e) {
                final normalizedName = normalizeWorkoutType(e['name'] ?? '');
                print('Checking exercise: "${e['name']}", Normalized: "$normalizedName" vs "$selectedWorkoutType"');
                return normalizedName == selectedWorkoutType;
              },
              orElse: () {
                print('No matching exercise found for "$selectedWorkoutType" in category "${widget.workoutCategory}"');
                return {'targetReps': '10', 'duration': '40s'};
              },
            ) ??
        {'targetReps': '10', 'duration': '40s'};

    print('Exercise data: $exerciseData');

    final targetReps = int.tryParse(exerciseData['targetReps'].toString()) ?? widget.targetReps;
    final targetDuration = double.tryParse(exerciseData['duration'].toString().replaceAll('s', '')) ?? widget.targetDuration;

    print('Target reps: $targetReps, Target duration: $targetDuration');

    _analyzer = ExerciseAnalyzer(
      exerciseType: selectedWorkoutType,
      targetReps: targetReps,
      targetDuration: targetDuration,
    );
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.stream,
      ),
    );

    if (!kIsWeb) {
      _initializeCamera();
    }

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _isExerciseComplete) return false;
      setState(() {
        _durationSeconds += 0.1;
        if (!_isRepBased && _durationSeconds >= targetDuration) {
          _isExerciseComplete = true;
        }
      });
      return true;
    });
  }

  String _enhanceFeedback(String feedback, bool isGoodForm) {
    if (feedback.contains('calibrate')) return 'Stand still to calibrate 🚀';
    if (feedback.contains('No person') || feedback.contains('Position joints')) return 'Step into view! 😎';
    if (feedback.contains('Get in')) return 'Ready? Get set! 🚀';
    if (isGoodForm) {
      return 'Nailing it! $feedback 🔥';
    } else {
      return 'Adjust form: $feedback 😬';
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final selectedCamera = _isFrontCamera
          ? cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            )
          : cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        print('Camera initialized: ${_cameraController!.description.lensDirection}, PreviewSize=${_cameraController!.value.previewSize}');
      }

      if (_cameraController != null && _isCameraInitialized) {
        _cameraController!.startImageStream((CameraImage image) {
          if (_isProcessingFrame || !mounted) return;
          _isProcessingFrame = true;
          _processCameraImage(image);
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      if (mounted) {
        setState(() {
          _feedback = 'Camera error: ${e.toString()} 😢';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e. Try switching cameras.')),
        );
      }
    }
  }

  void _toggleCamera() async {
    if (_cameraController != null && _isCameraInitialized) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
      _cameraController = null;
    }
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCalibrated = false;
      _feedback = 'Stand still to calibrate 😎';
    });
    await _initializeCamera();
  }

  void _resetAnalyzer() {
    _analyzer.reset();
    setState(() {
      _reps = 0;
      _goodReps = 0;
      _badReps = 0;
      _durationSeconds = 0.0;
      _isExerciseComplete = false;
      _isCalibrated = false;
      _feedback = 'Stand still to calibrate 😎';
      _formFeedback = '';
      _pose = null;
      _lastRepCount = 0;
    });
    print('Exercise analyzer reset');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      _framesProcessed++;
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) {
        _pose = poses.first;
        if (!_isCalibrated) {
          _analyzer.calibrate(_pose!);
          setState(() {
            _feedback = 'Stand still to calibrate 😎';
            _formFeedback = '';
            _isCalibrated = _analyzer.isCalibrated; // Sync with analyzer
          });
          _isProcessingFrame = false;
          return;
        }
        final result = _analyzer.processPose(_pose!, _durationSeconds);
        setState(() {
          _feedback = _enhanceFeedback(result.feedback, result.isGoodForm);
          _formFeedback = result.formFeedback.isNotEmpty
              ? 'Form: ${result.formFeedback} ${result.isGoodForm ? "💯" : "😬"}'
              : '';
          _reps = result.reps;
          _goodReps = result.goodReps;
          _badReps = result.badReps;
          _durationSeconds = result.durationSeconds;
          _isExerciseComplete = result.isComplete;
          _lastRepCount = _reps;
        });
      } else {
        setState(() {
          _feedback = 'Step into view! 😎';
          _formFeedback = '';
          _pose = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Pose detection error: $e");
      debugPrint("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _feedback = 'Error analyzing pose: ${e.toString()} 😢';
        });
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      if (Platform.isAndroid) {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else if (Platform.isIOS) {
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error converting camera image: $e");
    }
    return null;
  }

  // Save workout summary to Hive
  Future<void> _saveWorkoutSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, cannot save workout summary');
      return;
    }

    try {
      final box = await Hive.openBox('workouts_${user.uid}');
      final summary = {
        'exerciseName': _analyzer.exerciseType, // Use normalized exercise type (e.g., "squat")
        'date': DateTime.now().toIso8601String(),
        'totalReps': _reps,
        'goodReps': _goodReps,
        'badReps': _badReps,
        'durationSeconds': _durationSeconds,
        'mode': 'AR',
        'isRepBased': _isRepBased,
        'isGoodForm': _goodReps >= _badReps, // Simplified form assessment
      };
      await box.add(summary);
      print('Saved workout summary: $summary');
    } catch (e) {
      print('Error saving workout summary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save workout: $e')),
        );
      }
    }
  }

  Future<void> _endWorkout() async {
    print('Finish button tapped at ${DateTime.now()}');
    if (_isSaving) {
      print('Debouncing: Finish button tap ignored');
      return;
    }
    _isSaving = true;
    try {
      if (!kIsWeb && _cameraController != null && _isCameraInitialized) {
        try {
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
            print('Camera image stream stopped');
          }
          await _cameraController!.dispose();
          print('Camera controller disposed');
        } catch (e) {
          print('Error stopping/disposing camera: $e');
        }
        _cameraController = null;
        _isCameraInitialized = false;
      }

      // Save the workout summary before navigating
      await _saveWorkoutSummary();

      if (!mounted) {
        print('Widget not mounted, cannot navigate');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading summary... 🚀'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFFB39DDB),
        ),
      );

      print('Navigating to WorkoutSummary with reps: $_reps, duration: $_durationSeconds');
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            print('Building WorkoutSummary');
            return WorkoutSummary(
              totalReps: _reps,
              goodReps: _goodReps,
              badReps: _badReps,
              durationSeconds: _durationSeconds.toInt(),
              exerciseType: _analyzer.exerciseType,
              workoutType: widget.workoutCategory,
              mode: 'AR',
              onDone: () {
                print('WorkoutSummary onDone called');
                Navigator.pushNamed(context, '/dashboard');
              },
            );
          },
        ),
      );
      print('Navigation to WorkoutSummary completed');
    } catch (e, stackTrace) {
      print('Error in _endWorkout: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e 😢')),
        );
      }
    } finally {
      _isSaving = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb && _cameraController != null && _isCameraInitialized) {
      _cameraController!.stopImageStream().catchError((e) {
        print('Error stopping image stream in dispose: $e');
      });
      _cameraController!.dispose().then((_) {
        print('Camera controller disposed in dispose');
      });
      _cameraController = null;
      _isCameraInitialized = false;
    }
    _poseDetector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_isCameraInitialized) return;
    if (state == AppLifecycleState.paused) {
      _cameraController!.stopImageStream().catchError((e) {
        print('Error stopping image stream in lifecycle: $e');
      });
    } else if (state == AppLifecycleState.resumed && !_isExerciseComplete) {
      _cameraController!.startImageStream(_processCameraImage).catchError((e) {
        print('Error starting image stream in lifecycle: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Center(
          child: Text(
            'Camera stream not supported on web. Use a mobile device! 📱',
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Color(0xFFB39DDB).withOpacity(0.2),
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    print('Building UI: PreviewSize=${_cameraController?.value.previewSize}, ScreenSize=${MediaQuery.of(context).size}');

    return Scaffold(
      body: _isCameraInitialized && _cameraController != null
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Color(0xFFB39DDB)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize!.height,
                        height: _cameraController!.value.previewSize!.width,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  ),
                  if (_pose != null)
                    CustomPaint(
                      painter: LandmarkPainter(
                        _pose!,
                        Size(
                          _cameraController!.value.previewSize!.height,
                          _cameraController!.value.previewSize!.width,
                        ),
                        MediaQuery.of(context).size,
                        _isFrontCamera,
                      ),
                      size: Size.infinite,
                    ),
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: ShakeX(
                      animate: _reps > _lastRepCount,
                      duration: const Duration(milliseconds: 300),
                      child: ZoomIn(
                        key: ValueKey(_reps),
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Color(0xFFB39DDB).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xFFB39DDB).withOpacity(0.5)),
                          ),
                          child: Text(
                            _isRepBased
                                ? 'Reps: $_reps (Good: $_goodReps, Bad: $_badReps) 💪'
                                : 'Time: ${_durationSeconds.toStringAsFixed(1)}s ⏱️',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Color(0xFFB39DDB).withOpacity(0.2),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 40),
                        child: RealTimeFeedbackWidget(
                          workoutType: _analyzer.exerciseType,
                          feedback: _feedback,
                          formFeedback: _formFeedback,
                          reps: _reps,
                          goodReps: _goodReps,
                          badReps: _badReps,
                          isExerciseComplete: _isExerciseComplete,
                          durationSeconds: _durationSeconds,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 20,
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 800),
                      child: FloatingActionButton(
                        onPressed: _toggleCamera,
                        backgroundColor: Color(0xFFB39DDB),
                        child: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 200,
                    left: 20,
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 800),
                      child: FloatingActionButton(
                        onPressed: _resetAnalyzer,
                        backgroundColor: Color(0xFFB39DDB),
                        tooltip: 'Reset Reps',
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 1000),
                      child: ElevatedButton(
                        onPressed: _endWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFB39DDB),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Slay It! Finish ✨',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Text(
                'Loading vibes... 🚀',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Color(0xFFB39DDB).withOpacity(0.2),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}