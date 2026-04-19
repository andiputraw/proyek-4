import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/vision/image_processing.dart';

class ProcessingStep {
  final String label;
  final Uint8List bytes;

  const ProcessingStep({required this.label, required this.bytes});

  ProcessingStep copyWith({String? label, File? file, Uint8List? bytes}) =>
      ProcessingStep(label: label ?? this.label, bytes: bytes ?? this.bytes);
}

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;

  bool isInitialized = false;
  String? errorMessage;

  List<DetectionResult> currentDetections = [];
  Timer? _mockDetectionTimer;

  bool isFlashlightOn = false;
  bool isOverlayVisible = true;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        errorMessage = 'No camera detected on device.';
        notifyListeners();
        return;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to initialize camera: $e';
    }

    notifyListeners();
  }

  Future<XFile?> takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return null;

    try {
      await controller!.pausePreview();
      await Future.delayed(const Duration(milliseconds: 100));
      final image = await controller!.takePicture();
      await controller!.resumePreview();
      return image;
    } catch (e) {
      errorMessage = 'Failed to capture photo: $e';
      notifyListeners();
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = controller;
    if (cam == null || !cam.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  Future<void> toggleFlashlight() async {
    print("toggleFlashlight called, isFlashlightOn: $isFlashlightOn");
    if (controller == null || !controller!.value.isInitialized) return;
    isFlashlightOn = !isFlashlightOn;
    try {
      await controller!.setFlashMode(
        isFlashlightOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      errorMessage = 'Failed to toggle flashlight: $e';
      print("toggleFlashlight failed: $e");
    }
    notifyListeners();
    print("toggleFlashlight executed, isFlashlightOn: $isFlashlightOn");
  }

  void toggleOverlay() {
    isOverlayVisible = !isOverlayVisible;
    notifyListeners();
  }

  void startMockDetection() {
    _mockDetectionTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _generateMockDetection(),
    );
  }

  void _generateMockDetection() {
    final rng = Random();
    final x = rng.nextDouble() * 0.8 + 0.1;
    final y = rng.nextDouble() * 0.8 + 0.1;
    final w = 0.2 + rng.nextDouble() * 0.2;
    final h = 0.1 + rng.nextDouble() * 0.1;

    currentDetections = [
      DetectionResult(
        box: Rect.fromLTWH(x, y, w, h),
        label: _randomDamageLabel(),
        score: 0.85 + rng.nextDouble() * 0.14,
      ),
    ];
    notifyListeners();
  }

  String _randomDamageLabel() {
    const types = ['D00', 'D10', 'D20', 'D40'];
    const labels = {
      'D00': 'Longitudinal Crack',
      'D10': 'Transverse Crack',
      'D20': 'Alligator Crack',
      'D40': 'Pothole',
    };
    final type = types[Random().nextInt(types.length)];
    return ' [$type] ${labels[type]!}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mockDetectionTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }
}

class ProcessingPipelineController extends VisionController {
  XFile? capturedPhoto;

  final List<ProcessingStep> pipeline = [];

  Future<void> captureAndReset() async {
    final image = await takePhoto();
    if (image == null) return;

    capturedPhoto = image;
    pipeline.clear();
    addStep("Grayscale", await ImageProcessing.grayscaleImage(image));
    addStep("Lowpass Filter", await ImageProcessing.lowpassFilter(image));
    addStep("Highpass Filter", await ImageProcessing.highpassFilter(image));
    addStep("Bandpass Filter", await ImageProcessing.bandpassFilter(image));
    addStep("Median Filter", await ImageProcessing.medianFilter(image));
    addStep(
      "Equalize Histogram",
      await ImageProcessing.equalizeHistogram(image),
    );
    addStep("Gamma Correction", await ImageProcessing.gammaCorrection(image));

    notifyListeners();
  }

  void addStep(String label, Uint8List imageBytes) {
    pipeline.add(ProcessingStep(label: label, bytes: imageBytes));
    notifyListeners();
  }

  void updateStep(int index, File file) {
    if (index < 0 || index >= pipeline.length) return;
    pipeline[index] = pipeline[index].copyWith(file: file);
    notifyListeners();
  }

  void removeStep(int index) {
    if (index < 0 || index >= pipeline.length) return;
    pipeline.removeAt(index);
    notifyListeners();
  }

  void clearPipeline() {
    capturedPhoto = null;
    pipeline.clear();
    notifyListeners();
  }

  bool get hasCapture => capturedPhoto != null;

  int get stepCount => pipeline.length + (hasCapture ? 1 : 0);
}

class DetectionResult {
  final Rect box;
  final String label;
  final double score;

  const DetectionResult({
    required this.box,
    required this.label,
    required this.score,
  });
}
