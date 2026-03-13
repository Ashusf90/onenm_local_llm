/// Defines how to format chat messages for a specific model.
class ChatTemplate {
  final String system;
  final String user;
  final String assistant;
  final String systemDefault;

  const ChatTemplate({
    required this.system,
    required this.user,
    required this.assistant,
    this.systemDefault = 'You are a helpful assistant.',
  });

  String format({
    String? systemPrompt,
    required List<({String role, String text})> messages,
  }) {
    final buf = StringBuffer();
    buf.write(system.replaceAll('{text}', systemPrompt ?? systemDefault));
    for (final msg in messages) {
      if (msg.role == 'user') {
        buf.write(user.replaceAll('{text}', msg.text));
      } else {
        buf.write(assistant.replaceAll('{text}', msg.text));
      }
    }
    // Prompt the assistant to respond
    buf.write(assistant.split('{text}').first);
    return buf.toString();
  }
}

/// Generation settings with safe defaults.
class GenerationSettings {
  final double temperature;
  final int topK;
  final double topP;
  final int maxTokens;
  final double repeatPenalty;

  const GenerationSettings({
    this.temperature = 0.7,
    this.topK = 40,
    this.topP = 0.9,
    this.maxTokens = 128,
    this.repeatPenalty = 1.1,
  });

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'maxTokens': maxTokens,
        'repeatPenalty': repeatPenalty,
      };
}

class ModelInfo {
  final String id;
  final String name;
  final String fileName;
  final String ggufUrl;
  final int sizeMB;
  final int minRamGB;
  final int context;
  final ChatTemplate chatTemplate;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.fileName,
    required this.ggufUrl,
    required this.sizeMB,
    required this.minRamGB,
    required this.context,
    required this.chatTemplate,
  });
}

class OneNmModel {
  static const _zephyrTemplate = ChatTemplate(
    system: '<|system|>\n{text}</s>\n',
    user: '<|user|>\n{text}</s>\n',
    assistant: '<|assistant|>\n{text}</s>\n',
  );

  static const _phi2Template = ChatTemplate(
    system: 'System: {text}\n',
    user: 'Human: {text}\n',
    assistant: 'AI: {text}\n',
    systemDefault: 'You are a helpful AI assistant.',
  );

  static const tinyllama = ModelInfo(
    id: 'tinyllama',
    name: 'TinyLlama 1.1B Chat',
    fileName: 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    ggufUrl:
        'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    sizeMB: 638,
    minRamGB: 2,
    context: 2048,
    chatTemplate: _zephyrTemplate,
  );

  static const phi2 = ModelInfo(
    id: 'phi2',
    name: 'Phi-2 2.7B',
    fileName: 'phi-2.Q4_K_M.gguf',
    ggufUrl:
        'https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf',
    sizeMB: 1600,
    minRamGB: 4,
    context: 2048,
    chatTemplate: _phi2Template,
  );

  static const all = [tinyllama, phi2];

  OneNmModel._();
}
