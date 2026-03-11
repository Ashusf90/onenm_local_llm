
import 'onenm_local_llm_platform_interface.dart';

class OnenmLocalLlm {
  Future<String?> getPlatformVersion() {
    return OnenmLocalLlmPlatform.instance.getPlatformVersion();
  }
}
