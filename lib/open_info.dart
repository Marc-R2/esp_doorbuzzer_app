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
          if (state == BuzzerState.unknown) {
            return const Text('Buzzer is in unknown state');
          }
          const size = 64.0;

          final show =
              state == BuzzerState.finished || state == BuzzerState.idle;

          return IgnorePointer(
            ignoring: state != BuzzerState.idle,
            child: InkWell(
              onTap: () {
                if (state == BuzzerState.idle) esp.openDoor();
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: size + size / 8,
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
                            child: SizedBox(
                              height: size,
                              width: size,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 256),
                                curve: Curves.easeInOut,
                                opacity: show ? 0 : 1,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.blue.shade100,
                                    // drop shadow
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              StateIcon(
                                esp: esp,
                                state: BuzzerState.firstBuzz,
                                size: size,
                              ),
                              StateIcon(
                                esp: esp,
                                state: BuzzerState.wait,
                                size: size,
                              ),
                              StateIcon(
                                esp: esp,
                                state: BuzzerState.secondBuzz,
                                size: size,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to open door',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
