# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.1.2

### Fixed

- Fixed native backend loading failing in consumer apps on Android 6+ (API 23+).
  Root cause: `extractNativeLibs` defaults to `false`, so `.so` files stay inside
  the APK and are never extracted to the `nativeLibraryDir` on disk. Added
  `android:extractNativeLibs="true"` to the plugin manifest so it merges into all
  consumer apps automatically.
- Improved backend loading with a 4-step fallback chain: directory scan → system
  default discovery → filename-only load → full-path load, with `dlerror()` logging
  for diagnostics.

## 0.1.1

### Fixed

- Fixed ggml backend discovery failing in consumer apps outside the example project.
  Added explicit CPU backend loading fallback when `ggml_backend_load_all_from_path()`
  returns 0 backends (common on some Android devices due to SELinux restrictions).

## 0.1.0

### Added

- On-device LLM inference via llama.cpp (arm64-v8a).
- `OneNm` class with `initialize()`, `chat()`, `generate()`, `clearHistory()`,
  and `dispose()` methods.
- Optional `debug` flag for verbose `[1nm]` console logging with timing.
- Automatic GGUF model download from HuggingFace with progress reporting
  and retry logic (3 attempts, exponential backoff).
- Model registry (`OneNmModel`) with six built-in models:
  - TinyLlama 1.1B Chat
  - Phi-2 2.7B
  - Qwen2.5 1.5B Instruct
  - Gemma 2B IT
  - Llama 3.2 3B Instruct
  - Mistral 7B Instruct v0.2
- Per-model chat templates (`ChatTemplate`) for multi-turn conversations
  (Zephyr, Phi-2, ChatML, Gemma, Llama 3, and Mistral formats).
- Configurable generation settings: temperature, top-k, top-p, repeat penalty,
  max tokens (`GenerationSettings`).
- KV cache clearing between calls for correct multi-turn behaviour.
- Example chat app with Material 3 UI, message bubbles, and typing indicator.
