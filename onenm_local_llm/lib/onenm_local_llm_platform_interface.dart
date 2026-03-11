import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'onenm_local_llm_method_channel.dart';

abstract class OnenmLocalLlmPlatform extends PlatformInterface {
  /// Constructs a OnenmLocalLlmPlatform.
  OnenmLocalLlmPlatform() : super(token: _token);

  static final Object _token = Object();

  static OnenmLocalLlmPlatform _instance = MethodChannelOnenmLocalLlm();

  /// The default instance of [OnenmLocalLlmPlatform] to use.
  ///
  /// Defaults to [MethodChannelOnenmLocalLlm].
  static OnenmLocalLlmPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OnenmLocalLlmPlatform] when
  /// they register themselves.
  static set instance(OnenmLocalLlmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
