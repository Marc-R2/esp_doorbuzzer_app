import 'dart:convert';

import 'package:com_flutter_client/com_flutter_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  EspController esp = EspController(
    auth: 'admin:admin',
    ipAddress: 'http://192.168.178.93',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: OpenInfo(esp: esp),
      floatingActionButton: DataBuilder(
        data: esp.state,
        builder: (context, state) {
          return FloatingActionButton(
            onPressed: state != BuzzerState.idle ? null : esp.openDoor,
            tooltip: 'Open door',
            child: const Icon(Icons.door_back_door_outlined),
          );
        },
      ),
    );
  }
}

enum BuzzerState {
  unknown,
  unavailable,
  idle,
  firstBuzz,
  wait,
  secondBuzz,
  finished,
}

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

  Map<String, String> get headers =>
      {'Authorization': 'Basic ${base64Encode(utf8.encode('admin:admin'))}'};

  Future<void> requestPost(String path) async {
    await http.post(
      Uri.parse('$ipAddress/$path'),
      headers: headers,
    );
  }

  Future<http.Response> requestGet(String path) =>
      http.get(
        Uri.parse('$ipAddress/$path'),
        headers: headers,
      );

  Future<void> openDoor() async {
    if (state.value != BuzzerState.idle) return;

    await requestPost('button/door_buzzer/press');

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

class OpenInfo extends StatelessWidget {
  OpenInfo({super.key, required this.esp});

  final EspController esp;

  final ScrollController _scrollController = ScrollController();

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
          return IgnorePointer(
            ignoring: state != BuzzerState.idle,
            child: ListView(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(32),
              children: [
                ElevatedButton(
                  onPressed: esp.openDoor,
                  child: const Text('Open door'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
