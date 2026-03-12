import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onenm_local_llm/onenm_local_llm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _nativeMessage = 'Waiting...';
  final _onenmLocalLlmPlugin = OnenmLocalLlm();

  @override
  void initState() {
    super.initState();
    initNative();
  }

  Future<void> initNative() async {
    String message;

    try {
      message = await _onenmLocalLlmPlugin.pingNative() ?? "No response";
    } on PlatformException {
      message = "Failed to call native code.";
    }

    if (!mounted) return;

    setState(() {
      _nativeMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('1nm Plugin Test'),
        ),
        body: Center(
          child: Text(
            _nativeMessage,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
