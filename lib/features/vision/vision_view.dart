import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'vision_controller.dart';
import 'damage_painter.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late final ProcessingPipelineController _ctrl;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = ProcessingPipelineController();
    _ctrl.startMockDetection();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onCaptureTapped() async {
    print("Capturing...");
    await _ctrl.captureAndReset();
    if (_ctrl.hasCapture && mounted) {
      _pageController.jumpToPage(0);
      setState(() => _currentPage = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo saved: ${_ctrl.capturedPhoto!.path}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) => Column(
          children: [
            _buildCameraSection(),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            Expanded(child: _buildPipelineSection()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCaptureTapped,
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: Colors.black,
        tooltip: 'Capture Photo',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111111),
      foregroundColor: Colors.white,
      title: const Text(
        'Smart-Patrol Vision',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        // Wrap the actions in a ListenableBuilder
        ListenableBuilder(
          listenable: _ctrl, // This listens for your notifyListeners() calls
          builder: (context, child) {
            return Row(
              children: [
                IconButton(
                  icon: Icon(
                    _ctrl.isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                    color: _ctrl.isFlashlightOn
                        ? const Color(0xFF00E5FF)
                        : Colors.white54,
                  ),
                  onPressed: _ctrl.toggleFlashlight,
                  tooltip: 'Toggle Flashlight',
                ),
                IconButton(
                  icon: Icon(
                    _ctrl.isOverlayVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white54,
                  ),
                  onPressed: _ctrl.toggleOverlay,
                  tooltip: 'Toggle Overlay',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCameraSection() {
    return SizedBox(
      height: 240,
      child: _ctrl.isInitialized ? _buildCameraPreview() : _buildLoadingState(),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1 / _ctrl.controller!.value.aspectRatio,
            child: CameraPreview(_ctrl.controller!),
          ),
        ),
        if (_ctrl.isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(painter: DamagePainter(_ctrl.currentDetections)),
          ),
        Positioned(
          top: 8,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '● LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00E5FF)),
          const SizedBox(height: 12),
          const Text(
            'Menghubungkan ke Sensor Visual...',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (_ctrl.errorMessage != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _ctrl.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: openAppSettings,
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Color(0xFF00E5FF)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPipelineSection() {
    if (!_ctrl.hasCapture) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe, size: 40, color: Colors.white12),
            SizedBox(height: 12),
            Text(
              'Capture a photo to start\nthe processing pipeline',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white30,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _ctrl.capturedPhoto!.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
          );
        }

        final steps = <_StepData>[
          _StepData(
            label: 'Original',
            stepNumber: 0,
            imageBytes: snapshot.data!,
            accentColor: const Color(0xFF00E5FF),
            isOriginal: true,
          ),
          for (int i = 0; i < _ctrl.pipeline.length; i++)
            _StepData(
              label: _ctrl.pipeline[i].label,
              stepNumber: i + 1,
              imageBytes: _ctrl.pipeline[i].bytes,
              accentColor: _stepColor(i),
              isOriginal: false,
            ),
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < steps.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 16,
                        height: 1,
                        color: Colors.white12,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? steps[i].accentColor
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!steps[_currentPage].isOriginal) ...[
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: steps[_currentPage].accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${steps[_currentPage].stepNumber}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    steps[_currentPage].label.toUpperCase(),
                    style: TextStyle(
                      color: steps[_currentPage].accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentPage + 1} / ${steps.length}',
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _CarouselPage(data: steps[index]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
              child: TextButton.icon(
                onPressed: _ctrl.clearPipeline,
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text(
                  'Clear pipeline',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.white30),
              ),
            ),
          ],
        );
      },
    );
  }

  static Color _stepColor(int index) {
    const colors = [
      Color(0xFF76FF03),
      Color(0xFFFF9100),
      Color(0xFFE040FB),
      Color(0xFFFF5252),
      Color(0xFFFFD740),
      Color(0xFF40C4FF),
    ];
    return colors[index % colors.length];
  }
}

class _StepData {
  final String label;
  final int stepNumber;
  final Uint8List imageBytes;
  final Color accentColor;
  final bool isOriginal;

  const _StepData({
    required this.label,
    required this.stepNumber,
    required this.imageBytes,
    required this.accentColor,
    required this.isOriginal,
  });
}

class _CarouselPage extends StatelessWidget {
  const _CarouselPage({required this.data});
  final _StepData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(data.imageBytes, fit: BoxFit.cover),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 3, color: data.accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
