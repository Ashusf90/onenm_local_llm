// Copyright 2024 1nm. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// Defines how to format chat messages for a specific model.
///
/// Each LLM family expects a different prompt structure. A [ChatTemplate]
/// encodes the special tokens / delimiters that surround system, user, and
/// assistant messages so the model generates coherent multi-turn replies.
///
/// The `{text}` placeholder in each template string is replaced with the
/// actual message content at formatting time.
///
/// ```dart
/// const zephyr = ChatTemplate(
///   system: '<|system|>\n{text}</s>\n',
///   user:   '<|user|>\n{text}</s>\n',
///   assistant: '<|assistant|>\n{text}</s>\n',
/// );
/// ```
class ChatTemplate {
  /// Template wrapping the system prompt.  Must contain `{text}`.
  final String system;

  /// Template wrapping each user message.  Must contain `{text}`.
  final String user;

  /// Template wrapping each assistant message.  Must contain `{text}`.
  final String assistant;

  /// Fallback system prompt used when none is provided by the caller.
  final String systemDefault;

  /// Creates a [ChatTemplate] with the given format strings.
  const ChatTemplate({
    required this.system,
    required this.user,
    required this.assistant,
    this.systemDefault = 'You are a helpful assistant.',
  });

  /// Renders a full prompt from a list of conversation [messages].
  ///
  /// An optional [systemPrompt] overrides [systemDefault]. The returned
  /// string is ready to be fed directly to the model for completion.
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

/// Controls the sampling behaviour during text generation.
///
/// All fields have sensible defaults suitable for conversational use.
///
/// ```dart
/// const settings = GenerationSettings(
///   temperature: 0.8,
///   maxTokens: 256,
/// );
/// ```
///
/// | Parameter       | Default | Description                                  |
/// |-----------------|---------|----------------------------------------------|
/// | temperature     | 0.7     | Randomness — higher = more creative.         |
/// | topK            | 40      | Keep only the top‑K most probable tokens.    |
/// | topP            | 0.9     | Nucleus sampling probability threshold.      |
/// | maxTokens       | 128     | Maximum number of tokens to generate.        |
/// | repeatPenalty   | 1.1     | Penalise recently generated tokens.          |
class GenerationSettings {
  /// Controls randomness.  `0.0` = deterministic, `> 1.0` = very creative.
  final double temperature;

  /// Limits sampling to the top‑K most likely next tokens.
  final int topK;

  /// Nucleus sampling: only tokens whose cumulative probability exceeds
  /// [topP] are considered.
  final double topP;

  /// Maximum number of tokens the model will generate per call.
  final int maxTokens;

  /// Penalises tokens that have already appeared, reducing repetition.
  /// `1.0` = no penalty.
  final double repeatPenalty;

  /// Creates generation settings. All parameters are optional and fall
  /// back to conservative defaults.
  const GenerationSettings({
    this.temperature = 0.7,
    this.topK = 40,
    this.topP = 0.9,
    this.maxTokens = 128,
    this.repeatPenalty = 1.1,
  });

  /// Serialises the settings to a [Map] for the platform channel.
  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'maxTokens': maxTokens,
        'repeatPenalty': repeatPenalty,
      };
}

/// Metadata for a supported LLM model.
///
/// A [ModelInfo] bundles everything the plugin needs to download, validate,
/// and interact with a specific GGUF model: the remote URL, expected file
/// size, hardware requirements, context length, and the matching
/// [ChatTemplate].
class ModelInfo {
  /// Short machine‑readable identifier (e.g. `'tinyllama'`).
  final String id;

  /// Human‑readable model name shown in UI.
  final String name;

  /// Local file name for the downloaded GGUF.
  final String fileName;

  /// Direct download URL for the quantised GGUF file.
  final String ggufUrl;

  /// Approximate download size in megabytes.
  final int sizeMB;

  /// Minimum device RAM (GB) recommended to load this model.
  final int minRamGB;

  /// Maximum context window length in tokens.
  final int context;

  /// The prompt template used for multi‑turn chat formatting.
  final ChatTemplate chatTemplate;

  /// Creates a [ModelInfo] instance.
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

/// Registry of pre‑configured models that can be used with [OneNm].
///
/// Each static constant is a [ModelInfo] describing a specific GGUF model
/// hosted on HuggingFace. Pass one of these to [OneNm] to use a model:
///
/// ```dart
/// final ai = OneNm(model: OneNmModel.tinyllama);
/// ```
///
/// To add a custom model, create your own [ModelInfo] instance.
class OneNmModel {
  /// Chat template used by the TinyLlama‑Chat / Zephyr family.
  static const _zephyrTemplate = ChatTemplate(
    system: '<|system|>\n{text}</s>\n',
    user: '<|user|>\n{text}</s>\n',
    assistant: '<|assistant|>\n{text}</s>\n',
  );

  /// Chat template used by Microsoft Phi‑2.
  static const _phi2Template = ChatTemplate(
    system: 'System: {text}\n',
    user: 'Human: {text}\n',
    assistant: 'AI: {text}\n',
    systemDefault: 'You are a helpful AI assistant.',
  );

  /// TinyLlama 1.1B Chat — lightweight model suitable for most phones.
  ///
  /// ~638 MB download, 2 GB RAM recommended, 2048 token context.
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

  /// Microsoft Phi‑2 2.7B — more capable but requires extra RAM.
  ///
  /// ~1.6 GB download, 4 GB RAM recommended, 2048 token context.
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

  /// List of all built-in models.
  static const all = [tinyllama, phi2];

  OneNmModel._();
}
