import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:com_flutter_client/com_flutter_client.dart';
import 'package:esp_doorbuzzer_app/buzzer_state.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';

class EspController {
  EspController({
    required this.auth,
    required this.ipAddress,
  }) {
    autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => refresh(),
    );
  }

  final localAuth = LocalAuthentication();

  final String auth;

  final String ipAddress;

  int? _buzzerDuration;

  int? _buzzerDelay;

  late Timer autoRefreshTimer;

  Future<int> get buzzerDuration async {
    final res = await getState('number', 'buzzer_duration');
    if (res == null) return 0;
    _buzzerDuration ??= int.parse(res);
    return _buzzerDuration!;
  }

  Future<int> get buzzerDelay async {
    final res = await getState('number', 'wait_duration');
    if (res == null) return 0;
    _buzzerDelay ??= int.parse(res);
    return _buzzerDelay!;
  }

  void refreshCache() async {
    final duration = _buzzerDuration;
    final delay = _buzzerDelay;

    _buzzerDuration = null;
    _buzzerDelay = null;

    await buzzerDuration;
    await buzzerDelay;

    if (_buzzerDuration == 0) _buzzerDuration = duration;
    if (_buzzerDelay == 0) _buzzerDelay = delay;
  }

  void refresh() async {
    if (state.value == BuzzerState.firstBuzz) return;
    if (state.value == BuzzerState.secondBuzz) return;
    if (state.value == BuzzerState.wait) return;
    if (state.value == BuzzerState.finished) return;

    if (!await isAvailable()) return;
    refreshCache();
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

  Future<http.Response?> requestGet(String path) async {
    try {
      return await http
          .get(Uri.parse('$ipAddress/$path'), headers: headers)
          .timeout(const Duration(milliseconds: 512));
    } catch (e) {
      // Handle any errors that may occur during the request
      print(e);
      return null;
    }
  }

  DateTime? _lastOpen;

  DateTime get lastOpen => _lastOpen ??= DateTime.now();

  DateTime get firstBuzzStart => lastOpen;

  DateTime get firstBuzzEnd =>
      firstBuzzStart.add(Duration(seconds: _buzzerDuration ?? 0));

  DateTime get waitStart => firstBuzzEnd;

  DateTime get waitEnd => waitStart.add(Duration(seconds: _buzzerDelay ?? 0));

  DateTime get secondBuzzStart => waitEnd;

  DateTime get secondBuzzEnd =>
      secondBuzzStart.add(Duration(seconds: _buzzerDuration ?? 0));

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

  String? getTitleByState(BuzzerState state) {
    switch (state) {
      case BuzzerState.firstBuzz:
      case BuzzerState.wait:
      case BuzzerState.secondBuzz:
        return 'Opening door';
      case BuzzerState.finished:
        return 'Door opened';
      case BuzzerState.unknown:
        return 'State Unknown - Tap to retry';
      case BuzzerState.unavailable:
        return 'ESP Unavailable - Tap to retry';
      case BuzzerState.idle:
        return 'Tap to open door';
    }
  }

  Future<void> openDoor() async {
    if (state.value != BuzzerState.idle) return;

    refreshCache();
    buzzerDuration;
    buzzerDelay;

    try {
      final bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Confirm to open the door',
      );
      if (!didAuthenticate) return;
    } on Exception catch (e) {
      print(e);
      if (Platform.isAndroid || Platform.isIOS) return;
    }

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
    if (state.value == BuzzerState.unavailable) {
      state.value = BuzzerState.unknown;
    }

    if ((await requestGet(''))?.statusCode == 200) {
      state.value = BuzzerState.idle;
      return true;
    }

    await Future<void>.delayed(const Duration(milliseconds: 512));
    state.value = BuzzerState.unavailable;
    return false;
  }

  Future<String?> getState(String type, String id) async {
    final response = await requestGet('$type/$id/get');
    if (response?.statusCode != 200) return null;
    final body = jsonDecode(response?.body ?? '{}');
    return body['state'];
  }
}
