import 'dart:math' as math;

/// Converts movement on the wheel ring into discrete, reversible detents.
/// No timer keeps scrolling after release, so a centre press stays predictable.
class WheelMotion {
  double? _angle;
  double _remainder = 0;
  int? _time;

  void reset() {
    _angle = null;
    _remainder = 0;
    _time = null;
  }

  int update({
    required double x,
    required double y,
    required double radius,
    required int milliseconds,
    required double radiansPerStep,
    bool accelerate = true,
  }) {
    final distance = math.sqrt(x * x + y * y);
    if (radius <= 0 || distance < radius * .38 || distance > radius * 1.12) {
      reset();
      return 0;
    }
    final angle = math.atan2(y, x);
    final previous = _angle;
    final previousTime = _time;
    _angle = angle;
    _time = milliseconds;
    if (previous == null || previousTime == null) return 0;
    var delta = angle - previous;
    if (delta > math.pi) delta -= math.pi * 2;
    if (delta < -math.pi) delta += math.pi * 2;
    final elapsed = math.max(1, milliseconds - previousTime);
    // A large jump or suspended gesture is a new touch, not a fast spin.
    if (delta.abs() > math.pi / 2 || elapsed <= 0 || elapsed > 150) {
      _remainder = 0;
      return 0;
    }
    if (_remainder * delta < 0) _remainder = 0;
    final speed = delta.abs() * 1000 / elapsed;
    final gain = accelerate ? (1 + (speed - 3).clamp(0, 5) * .25) : 1.0;
    _remainder += delta * gain;
    final steps = (_remainder / radiansPerStep).truncate().clamp(-8, 8);
    _remainder -= steps * radiansPerStep;
    return steps;
  }
}
