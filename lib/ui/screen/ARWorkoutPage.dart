import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitness_app/widgets/landmark_painter.dart';
import 'package:fitness_app/widgets/workout_summary.dart';

class ARWorkoutPage extends StatefulWidget {
  final String workoutType;
  final VoidCallback? onNextExercise;

  const ARWorkoutPage({
    Key? key,
    required this.workoutType,
    this.onNextExercise,
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

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
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
    setState(() => _isCameraInitialized = true);

    _cameraController.startImageStream((CameraImage image) {
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;
      _processCameraImage(image);
    });
  }

  void _toggleCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _cameraController.stopImageStream();
    await _cameraController.dispose();
    _initializeCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final camera = _cameraController.description;
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        setState(() => _pose = poses.first);
      } else {
        setState(() => _pose = null);
      }
    } catch (e) {
      debugPrint("Pose detection error: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _endWorkout() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummary(
          duration: _secondsElapsed,
          workoutType: widget.workoutType,
          reps: 0, // Replace with actual repetition counter later
          onOk: () => Navigator.pop(context),
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
            style: TextStyle(fontSize: 18),
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
                // Fullscreen Camera Preview
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

                // Pose Landmark Overlay
                if (_pose != null)
                  CustomPaint(
                    painter: LandmarkPainter(_pose),
                    size: Size.infinite,
                  ),

                // Workout Info
                Positioned(
                  top: 40,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workoutType,
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Time: $_secondsElapsed s',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Toggle Camera Button
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: _toggleCamera,
                    child: const Icon(Icons.cameraswitch),
                  ),
                ),

                // End Workout Button
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _endWorkout,
                    child: const Text("End Exercise"),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
