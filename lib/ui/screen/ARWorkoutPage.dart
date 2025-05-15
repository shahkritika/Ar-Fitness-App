import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../widgets/landmark_painter.dart';
import '../../utils/exercise_analyzer.dart';
import '../../widgets/real_time_feedbacks_widget.dart';
import '../../widgets/workout_summary.dart';

class ARWorkoutPage extends StatefulWidget {
  final String workoutType;
  final VoidCallback? onNextExercise;
  final int targetReps;

  const ARWorkoutPage({
    Key? key,
    required this.workoutType,
    this.onNextExercise,
    this.targetReps = 10,
  }) : super(key: key);

  @override
  State<ARWorkoutPage> createState() => _ARWorkoutPageState();
}

class _ARWorkoutPageState extends State<ARWorkoutPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isFrontCamera = true;

  Pose? _pose;
  late final PoseDetector _poseDetector;

  late final ExerciseAnalyzer _exerciseAnalyzer;
  String _feedback = 'Get in starting position';
  String _formFeedback = '';
  int _reps = 0;
  int _goodReps = 0;
  int _badReps = 0;
  bool _isExerciseComplete = false;

  Timer? _timer;
  int _secondsElapsed = 0;
  int _framesProcessed = 0;

  @override
  void initState() {
    super.initState();
    // Default to 'squat' if workoutType is invalid
    final validWorkoutType = ['squat', 'pushup'].contains(widget.workoutType.toLowerCase())
        ? widget.workoutType.toLowerCase()
        : 'squat';
    if (validWorkoutType != widget.workoutType.toLowerCase()) {
      print('Invalid workoutType: ${widget.workoutType}. Defaulting to $validWorkoutType');
    }
    _exerciseAnalyzer = ExerciseAnalyzer(
      exerciseType: validWorkoutType,
      targetReps: widget.targetReps,
    );
    if (!kIsWeb) {
      _initializeCamera();
    }
    _startTimer();

    final options = PoseDetectorOptions();
    _poseDetector = PoseDetector(options: options);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final selectedCamera = _isFrontCamera
          ? cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front)
          : cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        print('Camera initialized: ${_cameraController.description.lensDirection}');
      }

      _cameraController.startImageStream((CameraImage image) {
        if (_isProcessingFrame || !mounted) return;
        _isProcessingFrame = true;
        _processCameraImage(image);
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      if (mounted) {
        setState(() {
          _feedback = 'Camera error: ${e.toString()}';
        });
      }
    }
  }

  void _toggleCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _cameraController.stopImageStream();
    await _cameraController.dispose();
    _initializeCamera();
  }

  void _resetAnalyzer() {
    _exerciseAnalyzer.reset();
    setState(() {
      _reps = 0;
      _goodReps = 0;
      _badReps = 0;
      _isExerciseComplete = false;
      _feedback = 'Get in starting position';
      _formFeedback = '';
    });
    print('Exercise analyzer reset');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      _framesProcessed++;
      
      if (_framesProcessed % 2 != 0) {
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

      final poses = await _poseDetector.processImage(inputImage);
      print('Poses detected: ${poses.length}');

      if (poses.isNotEmpty) {
        final pose = poses.first;
        print('Landmarks: ${pose.landmarks.keys}');
        final analysis = _exerciseAnalyzer.processPose(pose);
        
        if (mounted) {
          setState(() {
            _pose = pose;
            _feedback = analysis.feedback;
            _formFeedback = analysis.formFeedback;
            _reps = analysis.reps;
            _goodReps = analysis.goodReps;
            _badReps = analysis.badReps;
            _isExerciseComplete = analysis.isComplete;
            print('UI updated: Reps=$_reps, Good=$_goodReps, Bad=$_badReps, Feedback=$_feedback');
          });
        }

        if (_isExerciseComplete && widget.onNextExercise != null) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) widget.onNextExercise!();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pose = null;
            _feedback = 'No person detected. Stand in frame.';
            print('No person detected');
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Pose detection error: $e");
      debugPrint("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _feedback = 'Error analyzing pose: ${e.toString()}';
        });
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _endWorkout() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSummary(
          totalReps: _reps,
          goodReps: _goodReps,
          badReps: _badReps,
          durationSeconds: _secondsElapsed,
          exerciseType: widget.workoutType,
          onDone: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!kIsWeb) {
      _cameraController.dispose();
      _poseDetector.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Center(
          child: Text(
            'Camera stream is not supported on Web.\nUse a mobile device.',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController.value.previewSize!.height,
                      height: _cameraController.value.previewSize!.width,
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                ),

                if (_pose != null)
                  CustomPaint(
                    painter: LandmarkPainter(
                      _pose!,
                      Size(
                        _cameraController.value.previewSize!.height, 
                        _cameraController.value.previewSize!.width
                      ),
                      MediaQuery.of(context).size,
                      _isFrontCamera,
                    ),
                    size: Size.infinite,
                  ),

                if (!kIsWeb)
                  RealTimeFeedbackWidget(
                    workoutType: widget.workoutType,
                    feedback: _feedback,
                    formFeedback: _formFeedback,
                    reps: _reps,
                    goodReps: _goodReps,
                    badReps: _badReps,
                    isExerciseComplete: _isExerciseComplete,
                    pose: _pose,
                  ),
                
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: FloatingActionButton(
                    onPressed: _toggleCamera,
                    child: const Icon(Icons.cameraswitch),
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),

                Positioned(
                  bottom: 40,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _endWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      "END WORKOUT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 100,
                  left: 20,
                  child: FloatingActionButton(
                    onPressed: _resetAnalyzer,
                    child: const Icon(Icons.refresh),
                    backgroundColor: Colors.blue.withOpacity(0.5),
                    tooltip: 'Reset Reps',
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black.withOpacity(0.5),
                    child: Text(
                      'Reps: $_reps (Good: $_goodReps, Bad: $_badReps)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (_isExerciseComplete)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'EXERCISE COMPLETE!',
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'You completed $_reps ${widget.workoutType.toLowerCase()}s!',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            if (widget.onNextExercise != null) ...[
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: widget.onNextExercise,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                ),
                                child: const Text(
                                  'NEXT EXERCISE',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}