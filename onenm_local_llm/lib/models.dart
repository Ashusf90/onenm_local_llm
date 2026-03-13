class ModelInfo {
  final String id;
  final String name;
  final String fileName;
  final String ggufUrl;
  final int sizeMB;
  final int minRamGB;
  final int context;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.fileName,
    required this.ggufUrl,
    required this.sizeMB,
    required this.minRamGB,
    required this.context,
  });
}

class OneNmModel {
  static const tinyllama = ModelInfo(
    id: "tinyllama",
    name: "TinyLlama 1.1B Chat",
    fileName: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
    ggufUrl:
        "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
    sizeMB: 638,
    minRamGB: 2,
    context: 2048,
  );

  static const phi2 = ModelInfo(
    id: "phi2",
    name: "Phi-2 2.7B",
    fileName: "phi-2.Q4_K_M.gguf",
    ggufUrl:
        "https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf",
    sizeMB: 1600,
    minRamGB: 4,
    context: 2048,
  );

  static const all = [tinyllama, phi2];

  OneNmModel._();
}
