import 'package:com_flutter_client/com_flutter_client.dart';
import 'package:esp_doorbuzzer_app/buzzer_state.dart';
import 'package:esp_doorbuzzer_app/esp_controller.dart';
import 'package:esp_doorbuzzer_app/time_based_linear_progress_indicator.dart';
import 'package:flutter/material.dart';

class StateIcon extends StatelessWidget {
  const StateIcon({
    super.key,
    required this.size,
    required this.state,
    required this.esp,
  });

  final double size;

  final BuzzerState state;

  final EspController esp;

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
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Expanded(
                child: Center(
                  child: Icon(
                    icon,
                    size: size / 2,
                  ),
                ),
              ),
            DataBuilder(
              data: esp.state,
              builder: (context, state) {
                final startTime = esp.getStartTimeByState(this.state);
                final endTime = esp.getEndTimeByState(this.state);

                if (!startTime.isBefore(endTime)) return const SizedBox();

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 256),
                  height: this.state == state ? size / 8 : 0,
                  child: TimeBasedLinearProgressIndicator(
                    startTime: startTime,
                    endTime: endTime,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
