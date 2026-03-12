import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'onenm_local_llm_platform_interface.dart';

class MethodChannelOnenmLocalLlm extends OnenmLocalLlmPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('onenm_local_llm');

  @override
  Future<String?> pingNative() async {
    final version = await methodChannel.invokeMethod<String>('pingNative');
    return version;
  }
}
