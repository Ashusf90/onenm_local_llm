import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'onenm_local_llm_platform_interface.dart';

class MethodChannelOnenmLocalLlm extends OnenmLocalLlmPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('onenm_local_llm');

  @override
  Future<String?> pingNative() async {
    return await methodChannel.invokeMethod<String>('pingNative');
  }

  @override
  Future<bool?> loadModel(String modelPath) async {
    return await methodChannel.invokeMethod<bool>(
      'loadModel',
      {'modelPath': modelPath},
    );
  }

  @override
  Future<String?> generate(String prompt, Map<String, dynamic> settings) async {
    return await methodChannel.invokeMethod<String>(
      'generate',
      {'prompt': prompt, ...settings},
    );
  }

  @override
  Future<void> releaseModel() async {
    await methodChannel.invokeMethod('releaseModel');
  }
}
