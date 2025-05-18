import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/pose_detector_service.dart';
import '../../utils/exercise_analyzer.dart';
import '../../widgets/landmark_painter.dart';
import '../../widgets/real_time_feedbacks_widget.dart';
import '../../widgets/workout_summary.dart';
import '../../utils/database_helper.dart'; // Added import

class ARWorkoutPage extends StatefulWidget {
  final String workoutType;
  final String workoutCategory;
  final VoidCallback? onNextExercise;
  final int targetReps;

  const ARWorkoutPage({
    Key? key,
    required this.workoutType,
    required this.workoutCategory,
    this.onNextExercise,
    this.targetReps = 10,
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

  Pose? _pose;
  late final PoseDetectorService _poseDetectorService;

  String _feedback = 'Get in starting position 😎';
  String _formFeedback = '';
  int _reps = 0;
  int _goodReps = 0;
  int _badReps = 0;
  double _durationSeconds = 0.0;
  bool _isExerciseComplete = false;
  bool _isRepBased = true;

  int _framesProcessed = 0;
  int _lastRepCount = 0;

  final List<String> validWorkoutTypes = [
    'squat', 'pushup', 'deadlift', 'bench_press', 'lunge', 'plank',
    'jumping_jacks', 'mountain_climbers', 'running_in_place', 'skaters',
    'butt_kicks', 'jump_rope', 'downward_dog', 'tree_pose', 'warrior_ii',
    'child_pose', 'bridge_pose', 'seated_forward_bend', 'burpees',
    'high_knees', 'jump_squats', 'lunges_with_jumps', 'plank_to_pushup',
  ];

  final List<String> repBasedExercises = [
    'squat', 'pushup', 'deadlift', 'bench_press', 'lunge',
    'jumping_jacks', 'mountain_climbers', 'running_in_place', 'skaters',
    'butt_kicks', 'jump_rope', 'burpees', 'high_knees', 'jump_squats',
    'lunges_with_jumps', 'plank_to_pushup',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final workoutTypeLower = widget.workoutType.toLowerCase();
    final selectedWorkoutType = validWorkoutTypes.contains(workoutTypeLower)
        ? workoutTypeLower
        : 'squat';
    if (selectedWorkoutType != workoutTypeLower) {
      print('Invalid workoutType: ${widget.workoutType}. Defaulting to $selectedWorkoutType');
    }
    _isRepBased = repBasedExercises.contains(selectedWorkoutType);
    _poseDetectorService = PoseDetectorService(
      onAnalysisComplete: (AnalysisResult analysis, Pose? pose) {
        if (mounted) {
          setState(() {
            _pose = pose;
            _feedback = _enhanceFeedback(analysis.feedback, analysis.isGoodForm);
            _formFeedback = analysis.formFeedback.isNotEmpty
                ? 'Form: ${analysis.formFeedback} ${analysis.isGoodForm ? "💯" : "😬"}'
                : '';
            if (pose != null && !analysis.feedback.contains('No person')) {
              _reps = analysis.reps;
              _goodReps = analysis.goodReps;
              _badReps = analysis.badReps;
              _durationSeconds = analysis.durationSeconds;
              _isExerciseComplete = analysis.isComplete;
              _lastRepCount = _reps;
            } else {
              _feedback = 'Yo, where you at? 😎';
              _formFeedback = '';
            }
            print('UI updated: Pose=${pose != null}, Reps=$_reps, Good=$_goodReps, Bad=$_badReps, Duration=$_durationSeconds, Feedback=$_feedback');
            if (_pose != null) {
              _pose!.landmarks.forEach((type, landmark) {
                print('Landmark $type: x=${landmark.x}, y=${landmark.y}, likelihood=${landmark.likelihood}');
              });
            }
          });
        }
      },
    );
    _poseDetectorService.setCurrentExercise(selectedWorkoutType);
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  String _enhanceFeedback(String feedback, bool isGoodForm) {
    if (feedback.contains('No person')) return 'Yo, where you at? 😎';
    if (feedback.contains('Get in')) return 'Let’s vibe, get in position! 🚀';
    if (isGoodForm) {
      return 'Slayin’ it! $feedback 🔥';
    } else {
      return 'Oops, tweak it! $feedback 😬';
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
        ResolutionPreset.high,
        enableAudio: false,
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
      }
    }
  }

  void _toggleCamera() async {
    if (_cameraController != null && _isCameraInitialized) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
      _cameraController = null;
    }
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _initializeCamera();
  }

  void _resetAnalyzer() {
    _poseDetectorService.reset();
    setState(() {
      _reps = 0;
      _goodReps = 0;
      _badReps = 0;
      _durationSeconds = 0.0;
      _isExerciseComplete = false;
      _feedback = 'Get in starting position 😎';
      _formFeedback = '';
      _pose = null;
      _lastRepCount = 0;
    });
    print('Exercise analyzer reset');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      _framesProcessed++;
      if (_framesProcessed % 4 != 0) {
        _isProcessingFrame = false;
        return;
      }

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      await _poseDetectorService.processImage(inputImage);

      if (_isExerciseComplete) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exercise complete! ${_isRepBased ? "You crushed $_reps ${widget.workoutType}s! 🔥" : "Great job! 🔥"}'),
              duration: const Duration(seconds: 3),
              backgroundColor: const Color(0xFF6B48FF),
            ),
          );
        }
        if (widget.onNextExercise != null) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) widget.onNextExercise!();
          });
        }
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

  Future<void> _endWorkout() async {
    print('Finish button tapped at ${DateTime.now()}');
    if (_isSaving) {
      print('Debouncing: Finish button tap ignored');
      return;
    }
    _isSaving = true;
    try {
      // Stop and dispose camera only if initialized
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

      // Save workout data using DatabaseHelper
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save workout data 😢'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushNamed(context, '/login');
        }
        return;
      }

      final workoutData = {
        'date': DateTime.now().toIso8601String(),
        'category': widget.workoutCategory,
        'duration': _durationSeconds.toInt(),
      };

      final exerciseData = {
        'exercise_name': widget.workoutType,
        'reps': _reps,
        'good_reps': _goodReps,
        'bad_reps': _badReps,
        'duration': _durationSeconds.toInt(),
        'mode': 'AR',
      };

      bool saved = false;
      try {
        final dbHelper = DatabaseHelper.instance;
        final workoutId = await dbHelper.insertWorkout(workoutData);
        exerciseData['workout_id'] = workoutId;
        await dbHelper.insertExercise(exerciseData);
        await dbHelper.syncLocalWithFirestore(); // Ensure sync for mobile
        saved = true;
        print('Workout saved: WorkoutID=$workoutId, Data=$workoutData, Exercise=$exerciseData');
      } catch (e) {
        print('Error saving workout with DatabaseHelper: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout queued offline. Sync when online. 📴'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (!mounted) {
        print('Widget not mounted, cannot navigate');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved
              ? 'Workout saved! Loading summary... 🚀'
              : 'Workout queued offline! Loading summary... 📴'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF6B48FF),
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
              exerciseType: widget.workoutType,
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
    _poseDetectorService.dispose();
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
            style: GoogleFonts.orbitron(
              fontSize: 20,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.3),
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
                  colors: [
                    Color(0xFF6B48FF),
                    Color(0xFFA78BFA),
                  ],
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
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            _isRepBased
                                ? 'Reps: $_reps (Good: $_goodReps, Bad: $_badReps) 💪'
                                : 'Time: ${_durationSeconds.toStringAsFixed(1)}s ⏱️',
                            style: GoogleFonts.orbitron(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Color(0xFF6B48FF).withOpacity(0.5),
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
                          workoutType: widget.workoutType,
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
                        backgroundColor: Colors.transparent,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6B48FF), Color(0xFFA78BFA)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cameraswitch,
                            color: Colors.white,
                            size: 48,
                          ),
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
                        backgroundColor: Colors.transparent,
                        tooltip: 'Reset Reps',
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6B48FF), Color(0xFFA78BFA)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 30,
                          ),
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
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6B48FF), Color(0xFFA78BFA)],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Slay It! Finish ✨',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Color(0xFF6B48FF).withOpacity(0.5),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}