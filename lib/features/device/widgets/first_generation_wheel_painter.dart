import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Outlines the four outer buttons of a first-generation-style wheel.
/// Painting only: the existing tap and rotation hit targets stay unchanged.
class FirstGenerationWheelPainter extends CustomPainter {
  const FirstGenerationWheelPainter(this.color, {this.raised = false});

  final Color color;
  final bool raised;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final lineColor = color.computeLuminance() > 0.35
        ? const Color(0x66505050)
        : const Color(0x88FFFFFF);
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    if (raised) {
      final shadow = Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(center + const Offset(0, 1), radius * 0.66, shadow);
    }
    canvas.drawCircle(center, radius * 0.66, paint);
    canvas.drawCircle(center, radius - 0.7, paint);
    for (final angle in [
      math.pi / 4,
      3 * math.pi / 4,
      5 * math.pi / 4,
      7 * math.pi / 4,
    ]) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * radius * 0.66,
        center + direction * (radius - 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FirstGenerationWheelPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.raised != raised;
}
