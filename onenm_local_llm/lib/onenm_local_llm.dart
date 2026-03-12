import 'onenm_local_llm_platform_interface.dart';

class OnenmLocalLlm {
  Future<String?> pingNative() {
    return OnenmLocalLlmPlatform.instance.pingNative();
  }

  Future<bool?> loadModel(String modelPath) {
    return OnenmLocalLlmPlatform.instance.loadModel(modelPath);
  }

  Future<String?> generate(String prompt) {
    return OnenmLocalLlmPlatform.instance.generate(prompt);
  }

  Future<void> releaseModel() {
    return OnenmLocalLlmPlatform.instance.releaseModel();
  }
}
