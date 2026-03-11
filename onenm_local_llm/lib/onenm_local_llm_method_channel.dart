import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'onenm_local_llm_platform_interface.dart';

/// An implementation of [OnenmLocalLlmPlatform] that uses method channels.
class MethodChannelOnenmLocalLlm extends OnenmLocalLlmPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('onenm_local_llm');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
