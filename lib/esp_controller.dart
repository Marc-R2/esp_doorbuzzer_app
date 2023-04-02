import 'dart:convert';

import 'package:com_flutter_client/com_flutter_client.dart';
import 'package:esp_doorbuzzer_app/buzzer_state.dart';
import 'package:http/http.dart' as http;

class EspController {
  EspController({
    required this.auth,
    required this.ipAddress,
  });

  final String auth;

  final String ipAddress;

  int? _buzzerDuration;

  int? _buzzerDelay;

  Future<int> get buzzerDuration async {
    _buzzerDuration ??= int.parse(await getState('number', 'buzzer_duration'));
    return _buzzerDuration!;
  }

  Future<int> get buzzerDelay async {
    _buzzerDelay ??= int.parse(await getState('number', 'wait_duration'));
    return _buzzerDelay!;
  }

  final state = GlobalData.withoutKey(value: BuzzerState.unknown);

  Map<String, String> get headers => {
        'Authorization': 'Basic ${base64Encode(utf8.encode('admin:admin'))}',
        // Allow CORS
        'Access-Control-Allow-Origin': '*',
        // Allow all methods
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        // Allow all headers
        'Access-Control-Allow-Headers': '*',
      };

  Future<void> requestPost(String path) async {
    await http.post(
      Uri.parse('$ipAddress/$path'),
      headers: headers,
    );
  }

  Future<http.Response> requestGet(String path) => http.get(
        Uri.parse('$ipAddress/$path'),
        headers: headers,
      );

  DateTime? _lastOpen;

  DateTime get lastOpen => _lastOpen ??= DateTime.now();

  DateTime get firstBuzzStart => lastOpen;
  DateTime get firstBuzzEnd => firstBuzzStart.add(Duration(seconds: _buzzerDuration ?? 0));

  DateTime get waitStart => firstBuzzEnd;
  DateTime get waitEnd => waitStart.add(Duration(seconds: _buzzerDelay ?? 0));

  DateTime get secondBuzzStart => waitEnd;
  DateTime get secondBuzzEnd => secondBuzzStart.add(Duration(seconds: _buzzerDuration ?? 0));

  DateTime getStartTimeByState(BuzzerState state) {
    switch (state) {
      case BuzzerState.firstBuzz:
        return firstBuzzStart;
      case BuzzerState.wait:
        return waitStart;
      case BuzzerState.secondBuzz:
        return secondBuzzStart;
      case BuzzerState.finished:
        return secondBuzzEnd;
      default:
        return DateTime.now();
    }
  }

  DateTime getEndTimeByState(BuzzerState state) {
    switch (state) {
      case BuzzerState.firstBuzz:
        return firstBuzzEnd;
      case BuzzerState.wait:
        return waitEnd;
      case BuzzerState.secondBuzz:
        return secondBuzzEnd;
      case BuzzerState.finished:
        return secondBuzzEnd;
      default:
        return DateTime.now();
    }
  }

  Future<void> openDoor() async {
    if (state.value != BuzzerState.idle) return;

    await requestPost('button/door_buzzer/press');

    _lastOpen = DateTime.now();

    state.value = BuzzerState.firstBuzz;
    await Future<void>.delayed(Duration(seconds: await buzzerDuration));
    state.value = BuzzerState.wait;
    await Future<void>.delayed(Duration(seconds: await buzzerDelay));
    state.value = BuzzerState.secondBuzz;
    await Future<void>.delayed(Duration(seconds: await buzzerDuration));
    state.value = BuzzerState.finished;
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    isAvailable();
  }

  Future<bool> isAvailable() async {
    if ((await requestGet('')).statusCode == 200) {
      state.value = BuzzerState.idle;
      return true;
    }

    state.value = BuzzerState.unavailable;
    return false;
  }

  Future<String> getState(String type, String id) async {
    final response = await requestGet('$type/$id/get');
    final body = jsonDecode(response.body);
    return body['state'];
  }
}
