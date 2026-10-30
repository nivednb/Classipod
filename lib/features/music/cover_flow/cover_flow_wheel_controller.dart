import 'dart:async';

import 'package:classipod/features/music/cover_flow/cover_flow_motion.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class CoverFlowWheelController {
  CoverFlowWheelController({
    required this.pageController,
    required TickerProvider vsync,
  }) : _animation = AnimationController.unbounded(vsync: vsync) {
    _animation.addListener(_updatePage);
  }

  final PageController pageController;
  final AnimationController _animation;
  int _target = 0;
  int? _pendingTarget;
  int? _frameCallback;

  int? get target =>
      _pendingTarget ?? (_animation.isAnimating ? _target : null);

  void step(int direction, int itemCount) {
    if (!pageController.hasClients || itemCount == 0) return;
    final page = pageController.page!;
    final next = ((target ?? page.round()) + direction).clamp(0, itemCount - 1);
    if (next == target || (target == null && next == page)) return;
    _pendingTarget = next;
    _frameCallback ??= SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameCallback = null;
      final destination = _pendingTarget;
      _pendingTarget = null;
      if (destination == null || !pageController.hasClients) return;
      final currentPage = pageController.page!;
      final velocity = _animation.isAnimating ? _animation.velocity : 0.0;
      _target = destination;
      _animation.value = currentPage;
      unawaited(
        _animation.animateWith(
          ScrollSpringSimulation(
            CoverFlowMotion.spring,
            currentPage,
            destination.toDouble(),
            velocity,
          ),
        ),
      );
    });
  }

  void _updatePage() {
    if (!pageController.hasClients) return;
    final position = pageController.position;
    final pixels =
        pageController.offset +
        (_animation.value - pageController.page!) *
            position.viewportDimension *
            pageController.viewportFraction;
    pageController.jumpTo(
      pixels.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  void stop() {
    if (_frameCallback case final callback?) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(callback);
      _frameCallback = null;
    }
    _pendingTarget = null;
    _animation.stop();
  }

  void dispose() {
    stop();
    _animation.dispose();
  }
}
