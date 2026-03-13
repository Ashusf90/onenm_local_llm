import 'package:flutter/material.dart';
import 'package:onenm_local_llm/onenm_local_llm.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Starting...';

  late final OneNm ai = OneNm(
    model: OneNmModel.tinyllama,
    onProgress: (msg) => setState(() => _status = msg),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      await ai.initialize();
      final output = await ai.generate('Hello');
      setState(() => _status = 'Output: $output');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('1nm Test')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(_status),
        ),
      ),
    );
  }
}
