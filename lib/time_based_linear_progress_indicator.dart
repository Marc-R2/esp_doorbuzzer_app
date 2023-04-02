import 'dart:math' as math;

import 'package:flutter/material.dart';

class TimeBasedLinearProgressIndicator extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final Animation<Color?>? valueColor;
  final Color? backgroundColor;

  const TimeBasedLinearProgressIndicator({
    super.key,
    required this.startTime,
    required this.endTime,
    this.backgroundColor,
    this.valueColor,
  });

  @override
  State createState() => _TimeBasedLinearProgressIndicatorState();
}

class _TimeBasedLinearProgressIndicatorState
    extends State<TimeBasedLinearProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late DateTime startTime;
  late DateTime endTime;

  @override
  void initState() {
    super.initState();
    buildController();
  }

  void buildController() {
    assert(widget.startTime.isBefore(widget.endTime));

    var duration = widget.endTime.difference(DateTime.now());

    if (duration.inMilliseconds <= 0) {
      duration = const Duration(milliseconds: 1);
    }

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimeBasedLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime ||
        widget.endTime != oldWidget.endTime) {
      _controller.dispose();

      startTime = widget.startTime;
      endTime = widget.endTime;

      buildController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final now = DateTime.now();

        final value = math.max(
          0.0,
          math.min(
            1.0,
            now.difference(widget.startTime).inMilliseconds /
                widget.endTime.difference(widget.startTime).inMilliseconds,
          ),
        );

        return LinearProgressIndicator(
          value: value,
          valueColor: widget.valueColor,
          backgroundColor: widget.backgroundColor,
        );
      },
    );
  }
}
