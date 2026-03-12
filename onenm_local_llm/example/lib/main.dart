import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  String _message = "Starting...";
  final plugin = OnenmLocalLlm();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => runTest());
  }

  void _log(String msg) {
    debugPrint("[1nm] $msg");
    setState(() {
      _message = msg;
    });
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> runTest() async {
    try {
      _log("Requesting storage permission...");
      final granted = await _requestStoragePermission();
      if (!granted) {
        _log(
            "Storage permission denied.\nPlease grant 'All files access' in app settings.");
        return;
      }

      _log("Getting app directory...");
      final appDir = await getApplicationDocumentsDirectory();

      final modelDir = Directory("${appDir.path}/models");
      await modelDir.create(recursive: true);

      final modelPath = "${modelDir.path}/tinyllama.gguf";
      final target = File(modelPath);

      if (!await target.exists()) {
        const downloadPath =
            "/storage/emulated/0/Download/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf";
        final source = File(downloadPath);

        if (!await source.exists()) {
          _log(
            "Model not found.\n\n"
            "Place tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf\n"
            "in your Downloads folder, then restart the app.",
          );
          return;
        }

        _log("Copying model to app directory...");
        await source.copy(modelPath);
      }

      final fileSize = await target.length();
      _log(
          "Loading model... (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)");
      final loaded = await plugin.loadModel(modelPath);
      _log("Model loaded: $loaded\nGenerating...");

      final output = await plugin.generate("Hello");
      _log("Output: $output");
    } catch (e, stackTrace) {
      debugPrint("ERROR: $e");
      debugPrint("$stackTrace");
      setState(() {
        _message = "Error: $e\n\n$stackTrace";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("1nm Test")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(_message),
        ),
      ),
    );
  }
}
