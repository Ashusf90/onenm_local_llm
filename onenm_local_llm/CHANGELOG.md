# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.1.0

### Added

- On-device LLM inference via llama.cpp (arm64-v8a).
- `OneNm` class with `initialize()`, `chat()`, `generate()`, `clearHistory()`,
  and `dispose()` methods.
- Optional `debug` flag for verbose `[1nm]` console logging with timing.
- Automatic GGUF model download from HuggingFace with progress reporting
  and retry logic (3 attempts, exponential backoff).
- Model registry (`OneNmModel`) with TinyLlama 1.1B Chat and Phi-2 2.7B.
- Per-model chat templates (`ChatTemplate`) for multi-turn conversations
  (Zephyr and Phi-2 formats).
- Configurable generation settings: temperature, top-k, top-p, repeat penalty,
  max tokens (`GenerationSettings`).
- KV cache clearing between calls for correct multi-turn behaviour.
- Example chat app with Material 3 UI, message bubbles, and typing indicator.
