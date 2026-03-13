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
    if (loaded != true) {
      // Load failed — likely corrupted download. Delete and retry once.
      _report('Load failed, re-downloading...');
      final file = File(modelPath);
      if (await file.exists()) await file.delete();
      await _downloadModel(modelPath);

      _report('Loading model (retry)...');
      final retryLoaded =
          await OnenmLocalLlmPlatform.instance.loadModel(modelPath);
      if (retryLoaded != true) throw Exception('Failed to load model');
    }
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
      final expectedMin = model.sizeMB * 0.95 * 1024 * 1024;
      if (size >= expectedMin) {
        _report('Model found (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
        return modelPath;
      }
      // File too small — probably a truncated download
      _report('Incomplete model file, re-downloading...');
      await file.delete();
    }

    await _downloadModel(modelPath);
    return modelPath;
  }

  Future<void> _downloadModel(String modelPath) async {
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _report('Downloading ${model.name} (~${model.sizeMB} MB)...'
            '${attempt > 1 ? ' (attempt $attempt/$maxAttempts)' : ''}');

        final request = http.Request('GET', Uri.parse(model.ggufUrl));
        final response = await http.Client().send(request);

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final totalBytes = response.contentLength ?? model.sizeMB * 1024 * 1024;
        int receivedBytes = 0;

        final file = File(modelPath);
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

        // Verify file size
        final size = await file.length();
        final expectedMin = model.sizeMB * 0.95 * 1024 * 1024;
        if (size < expectedMin) {
          await file.delete();
          throw Exception(
              'Download incomplete: ${(size / 1024 / 1024).toStringAsFixed(1)} MB');
        }

        _report('Download complete');
        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        final delay = Duration(seconds: 2 << (attempt - 1)); // 2s, 4s
        _report('Download failed: $e\nRetrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
  }
}
