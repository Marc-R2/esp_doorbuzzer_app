import 'dart:convert';

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
      body: Center(
        child: FutureBuilder<bool>(
          future: esp.isAvailable(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!
                  ? OpenInfo(esp: esp)
                  : const Text('ESP not available');
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
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

  Map<String, String> get headers =>
      {'Authorization': 'Basic ${base64Encode(utf8.encode('admin:admin'))}'};

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

  Future<void> openDoor() => requestPost('button/door_buzzer/press');

  Future<bool> isAvailable() async => (await requestGet('')).statusCode == 200;

  Future<String> getState(String type, String id) async {
    final response = await requestGet('$type/$id/get');
    final body = jsonDecode(response.body);
    return body['state'];
  }
}

class OpenInfo extends StatelessWidget {
  const OpenInfo({
    super.key,
    required this.esp,
  });

  final EspController esp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(32),
          children: [
            ElevatedButton(
              onPressed: esp.openDoor,
              child: const Text('Open door'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => esp.openDoor(),
        tooltip: 'Open door',
        child: const Icon(Icons.door_back_door_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods
    );
  }
}
