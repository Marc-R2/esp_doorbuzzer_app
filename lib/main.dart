import 'package:com_flutter_client/com_flutter_client.dart';
import 'package:esp_doorbuzzer_app/buzzer_state.dart';
import 'package:esp_doorbuzzer_app/esp_controller.dart';
import 'package:esp_doorbuzzer_app/open_info.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doorbuzzer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
