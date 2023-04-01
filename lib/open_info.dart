import 'package:com_flutter_client/com_flutter_client.dart';
import 'package:esp_doorbuzzer_app/esp_controller.dart';
import 'package:esp_doorbuzzer_app/state_icon.dart';
import 'package:flutter/material.dart';

import 'buzzer_state.dart';

class OpenInfo extends StatelessWidget {
  OpenInfo({super.key, required this.esp});

  final EspController esp;

  @override
  Widget build(BuildContext context) {
    esp.isAvailable();
    return Center(
      child: DataBuilder(
        data: esp.state,
        builder: (context, state) {
          if (state == BuzzerState.unavailable) {
            return const Text('Buzzer is unavailable');
          }
          const size = 48.0;
          return IgnorePointer(
            ignoring: state != BuzzerState.idle,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: esp.openDoor,
                  child: const Text('Open door'),
                ),
                const SizedBox(height: 16),
                // Row with icons for the states and a animated positioned in stack to show the current state
                SizedBox(
                  height: size,
                  width: size * 3,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 256),
                        curve: Curves.easeInOut,
                        left: state == BuzzerState.firstBuzz
                            ? 0
                            : state == BuzzerState.wait
                                ? size
                                : state == BuzzerState.secondBuzz
                                    ? size * 2
                                    : state == BuzzerState.finished
                                        ? size * 3
                                        : size * -1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 256),
                          color: state == BuzzerState.finished ||
                                  state == BuzzerState.idle
                              ? Colors.transparent
                              : Colors.blue,
                          height: size,
                          width: size,
                        ),
                      ),
                      Row(
                        children: const [
                          StateIcon(state: BuzzerState.firstBuzz, size: size),
                          StateIcon(state: BuzzerState.wait, size: size),
                          StateIcon(state: BuzzerState.secondBuzz, size: size),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
