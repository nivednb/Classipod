import 'package:classipod/features/music/cover_flow/cover_flow_wheel_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'coalesces rapid steps, handles reversal, and cancels pending work',
    (tester) async {
      final pages = PageController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PageView.builder(
            controller: pages,
            itemCount: 10,
            itemBuilder: (_, index) => Text('$index'),
          ),
        ),
      );
      final wheel = CoverFlowWheelController(
        pageController: pages,
        vsync: tester,
      );
      for (var i = 0; i < 7; i++) {
        wheel.step(1, 10);
      }
      wheel.step(-1, 10);
      expect(wheel.target, 6);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(pages.page, closeTo(6, 0.01));

      wheel.step(1, 10);
      expect(wheel.target, 7);
      wheel.stop();
      expect(wheel.target, isNull);
      await tester.pump();
      expect(pages.page, closeTo(6, 0.01));
      wheel.dispose();
      await tester.pumpWidget(const SizedBox());
      pages.dispose();
    },
  );
}
