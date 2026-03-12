import 'onenm_local_llm_platform_interface.dart';

class OnenmLocalLlm {
  Future<String?> pingNative() {
    return OnenmLocalLlmPlatform.instance.pingNative();
  }
}
