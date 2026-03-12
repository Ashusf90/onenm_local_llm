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
  String _message = 'Waiting...';
  final _plugin = OnenmLocalLlm();

  @override
  void initState() {
    super.initState();
    testNative();
  }

  Future<void> testNative() async {
    String message;

    try {
      final loaded = await _plugin.loadModel("/fake/path/model.gguf");
      final generated = await _plugin.generate("Hello model");

      message = "loadModel: $loaded\ngenerate: $generated";
    } on PlatformException catch (e) {
      message = "Error: ${e.message}";
    }

    if (!mounted) return;

    setState(() {
      _message = message;
    });
  }

  @override
  void dispose() {
    _plugin.releaseModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('1nm Test')),
        body: Center(
          child: Text(
            _message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
