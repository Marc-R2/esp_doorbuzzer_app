import 'package:esp_doorbuzzer_app/buzzer_state.dart';
import 'package:flutter/material.dart';

class StateIcon extends StatelessWidget {
  const StateIcon({
    super.key,
    required this.size,
    required this.state,
  });

  final double size;

  final BuzzerState state;

  @override
  Widget build(BuildContext context) {
    final icon = state == BuzzerState.firstBuzz
        ? Icons.volume_up
        : state == BuzzerState.wait
            ? Icons.timer
            : state == BuzzerState.secondBuzz
                ? Icons.volume_up
                : state == BuzzerState.finished
                    ? Icons.check
                    : null;

    return SizedBox(
      height: size,
      width: size,
      child: icon != null ? Center(child: Icon(icon)) : null,
    );
  }
}
