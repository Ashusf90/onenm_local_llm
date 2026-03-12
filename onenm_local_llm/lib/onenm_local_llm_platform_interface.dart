import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'onenm_local_llm_method_channel.dart';

abstract class OnenmLocalLlmPlatform extends PlatformInterface {
  OnenmLocalLlmPlatform() : super(token: _token);

  static final Object _token = Object();

  static OnenmLocalLlmPlatform _instance = MethodChannelOnenmLocalLlm();

  static OnenmLocalLlmPlatform get instance => _instance;

  static set instance(OnenmLocalLlmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> pingNative() {
    throw UnimplementedError('pingNative() has not been implemented.');
  }
}
