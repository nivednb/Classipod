import 'dart:math' as math;

import 'package:classipod/features/device/models/wheel_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('angular wheel detents', () {
    late WheelMotion wheel;
    setUp(() => wheel = WheelMotion());
    int move(double angle, int time, {bool accelerate = false}) => wheel.update(
      x: math.cos(angle) * 80,
      y: math.sin(angle) * 80,
      radius: 100,
      milliseconds: time,
      radiansPerStep: .1,
      accelerate: accelerate,
    );

    test('accumulates slow motion without a minimum flick velocity', () {
      expect(move(0, 0), 0);
      expect(move(.04, 40), 0);
      expect(move(.08, 80), 0);
      expect(move(.12, 120), 1);
    });
    test('crosses atan2 seam without a jump or reversal', () {
      move(math.pi - .08, 0);
      expect(move(-math.pi + .08, 20), 1);
    });
    test('reverse takes effect without paying off old momentum', () {
      move(0, 0);
      move(.09, 20);
      expect(move(-.02, 40), -1);
    });
    test('centre and release discard residual movement', () {
      move(0, 0);
      move(.09, 20);
      expect(
        wheel.update(
          x: 0,
          y: 0,
          radius: 100,
          milliseconds: 40,
          radiansPerStep: .1,
        ),
        0,
      );
      expect(move(.8, 60), 0);
      wheel.reset();
      expect(move(1.5, 80), 0);
    });
    test('fast spin gains detents but stale gestures do not jump', () {
      move(0, 0);
      expect(move(.4, 20, accelerate: true), greaterThan(4));
      expect(move(.8, 300), 0);
      expect(move(2.6, 320), 0);
    });
  });
}
