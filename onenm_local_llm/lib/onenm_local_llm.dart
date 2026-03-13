import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'onenm_local_llm_platform_interface.dart';
import 'models.dart';

export 'models.dart';

/// Progress callback for model download / load status.
typedef OneNmProgressCallback = void Function(String status);

/// High-level API for on-device LLM inference.
///
/// ```dart
/// final ai = OneNm(model: OneNmModel.tinyllama);
/// await ai.initialize();
/// final reply = await ai.generate("Hello");
/// ai.dispose();
/// ```
class OneNm {
  final ModelInfo model;
  final OneNmProgressCallback? onProgress;
  bool _ready = false;

  OneNm({required this.model, this.onProgress});

  void _report(String msg) {
    debugPrint('[1nm] $msg');
    onProgress?.call(msg);
  }

  /// Downloads the model if missing then loads it.  Returns when ready.
  Future<void> initialize() async {
    final modelPath = await _ensureModel();

    _report('Loading model...');
    final loaded = await OnenmLocalLlmPlatform.instance.loadModel(modelPath);
    if (loaded != true) throw Exception('Failed to load model');
    _ready = true;
    _report('Ready');
  }

  /// Generate a completion for [prompt]. Must call [initialize] first.
  Future<String> generate(String prompt) async {
    if (!_ready) throw StateError('Call initialize() first');
    final result = await OnenmLocalLlmPlatform.instance.generate(prompt);
    return result ?? '';
  }

  /// Release native resources.
  Future<void> dispose() async {
    await OnenmLocalLlmPlatform.instance.releaseModel();
    _ready = false;
  }

  // ── internal ──────────────────────────────────────────────

  Future<String> _ensureModel() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    await modelDir.create(recursive: true);

    final modelPath = '${modelDir.path}/${model.fileName}';
    final file = File(modelPath);

    if (await file.exists()) {
      final size = await file.length();
      _report('Model found (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
      return modelPath;
    }

    _report('Downloading ${model.name} (~${model.sizeMB} MB)...');

    final request = http.Request('GET', Uri.parse(model.ggufUrl));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? model.sizeMB * 1024 * 1024;
    int receivedBytes = 0;

    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      final pct = (receivedBytes / totalBytes * 100).toStringAsFixed(1);
      final recvMB = (receivedBytes / 1024 / 1024).toStringAsFixed(1);
      final totalMB = (totalBytes / 1024 / 1024).toStringAsFixed(1);
      _report('Downloading ${model.name}...\n'
          '$recvMB / $totalMB MB ($pct%)');
    }
    await sink.close();

    _report('Download complete');
    return modelPath;
  }
}
