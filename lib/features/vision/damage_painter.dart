import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'vision_controller.dart';

class DamagePainter extends CustomPainter {
  final List<DetectionResult> results;

  DamagePainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) {
      _drawStaticCrosshair(canvas, size);
      return;
    }

    for (var result in results) {
      _drawDetectionBox(canvas, size, result);
    }
  }

  void _drawStaticCrosshair(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 50, centerY),
      Offset(centerX + 50, centerY),
      paint,
    );

    canvas.drawLine(
      Offset(centerX, centerY - 50),
      Offset(centerX, centerY + 50),
      paint,
    );

    canvas.drawCircle(
      Offset(centerX, centerY),
      30,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    _drawLabel(
      canvas,
      Rect.fromCircle(center: Offset(centerX, centerY), radius: 30),
      "Searching for Road Damage...",
      1.0,
    );
  }

  void _drawDetectionBox(Canvas canvas, Size size, DetectionResult result) {
    final box = Rect.fromLTWH(
      result.box.left * size.width,
      result.box.top * size.height,
      result.box.width * size.width,
      result.box.height * size.height,
    );

    final boxColor = _getColorForDamage(result.label);

    final paint = Paint()
      ..color = boxColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(box, paint);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

    canvas.drawRect(box, shadowPaint);

    canvas.drawRect(box, paint);

    _drawLabel(canvas, box, result.label, result.score);
  }

  void _drawLabel(Canvas canvas, Rect box, String label, double score) {
    final textSpan = TextSpan(
      text: ' $label - ${(score * 100).toInt()}% ',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    double labelY = box.top - 25;

    if (labelY < 0) {
      labelY = box.bottom + 5;
    }

    final shadowSpan = TextSpan(
      text: ' $label - ${(score * 100).toInt()}% ',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final shadowPainter = TextPainter(
      text: shadowSpan,
      textDirection: TextDirection.ltr,
    );

    shadowPainter.layout();

    shadowPainter.paint(canvas, Offset(box.left + 2, labelY + 2));

    textPainter.paint(canvas, Offset(box.left, labelY));
  }

  Color _getColorForDamage(String label) {
    if (label.contains('D40')) return Colors.red;
    if (label.contains('D20')) return Colors.orange;
    if (label.contains('D10')) return Colors.yellow;
    return Colors.green;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
