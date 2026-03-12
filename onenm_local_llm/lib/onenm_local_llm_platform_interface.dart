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

  Future<bool?> loadModel(String modelPath) {
    throw UnimplementedError('loadModel() has not been implemented.');
  }

  Future<String?> generate(String prompt) {
    throw UnimplementedError('generate() has not been implemented.');
  }

  Future<void> releaseModel() {
    throw UnimplementedError('releaseModel() has not been implemented.');
  }
}
