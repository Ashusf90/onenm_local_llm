// Copyright 2026 1nm. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// =============================================================================
// onenm_bridge.cpp — JNI bridge between Android/Kotlin and llama.cpp
//
// This file implements three JNI functions consumed by OneNmNative.kt:
//
//   loadModel()    – Initialises the llama.cpp backend, loads a GGUF model,
//                    and creates an inference context.
//   generate()     – Tokenises a prompt, feeds it through the model, then
//                    samples new tokens using a configurable sampler chain
//                    (repeat-penalty → top-k → top-p → temperature → dist).
//   releaseModel() – Frees the context, model, and backend.
//
// Logging goes to Android logcat under the tags "1nm_bridge" (this file)
// and "llama.cpp" (upstream library).
// =============================================================================

#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>
#include <dlfcn.h>

#include "llama.h"
#include "ggml.h"
#include "ggml-backend.h"

#define TAG "1nm_bridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Redirect llama.cpp internal logs to Android logcat.
static void llama_log_callback(enum ggml_log_level level, const char * text, void * user_data) {
    int prio = ANDROID_LOG_INFO;
    if (level == GGML_LOG_LEVEL_ERROR) prio = ANDROID_LOG_ERROR;
    else if (level == GGML_LOG_LEVEL_WARN) prio = ANDROID_LOG_WARN;
    else if (level == GGML_LOG_LEVEL_DEBUG) prio = ANDROID_LOG_DEBUG;
    __android_log_print(prio, "llama.cpp", "%s", text);
}

// Global model and context — only one model loaded at a time.
static llama_model * model = nullptr;
static llama_context * ctx = nullptr;

// ---------------------------------------------------------------------------
// loadModel  — Load a GGUF model from disk and create an inference context.
// ---------------------------------------------------------------------------
extern "C"
JNIEXPORT jboolean JNICALL
Java_com_theorangeshade_onenm_1local_1llm_OneNmNative_loadModel(
        JNIEnv * env,
        jobject thiz,
        jstring modelPath,
        jstring nativeLibDir) {

    const char * path = env->GetStringUTFChars(modelPath, nullptr);
    const char * lib_dir = env->GetStringUTFChars(nativeLibDir, nullptr);
    LOGI("loadModel called with path: %s", path);
    LOGI("Native lib dir: %s", lib_dir);

    // Verify file exists and is readable before handing to llama.cpp.
    FILE * f = fopen(path, "rb");
    if (!f) {
        LOGE("Cannot open file: %s", path);
        env->ReleaseStringUTFChars(modelPath, path);
        env->ReleaseStringUTFChars(nativeLibDir, lib_dir);
        return JNI_FALSE;
    }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fclose(f);
    LOGI("File size: %ld bytes", size);

    // Load ggml backends from the app's native library directory so that
    // platform-specific backends (CPU, GPU, etc.) are discovered at runtime.
    LOGI("Initializing llama backend...");
    llama_log_set(llama_log_callback, nullptr);

    // Try 1: Scan the native lib directory for backend .so files.
    ggml_backend_load_all_from_path(lib_dir);
    LOGI("Backends after path scan: %zu", ggml_backend_reg_count());

    // Try 2: System default discovery (may use different search paths).
    if (ggml_backend_reg_count() == 0) {
        LOGI("Path scan found no backends, trying system default discovery...");
        ggml_backend_load_all();
        LOGI("Backends after system discovery: %zu", ggml_backend_reg_count());
    }

    // Try 3: Load CPU backend by just the filename. Since System.loadLibrary()
    // in Kotlin already loaded the .so into the process, dlopen with just the
    // filename should find it in the linker namespace.
    if (ggml_backend_reg_count() == 0) {
        LOGI("Trying to load CPU backend by filename only...");
        const char * cpu_names[] = {
            "libggml-cpu-android_armv8.2_1.so",
            "libggml-cpu.so",
        };
        for (const char * name : cpu_names) {
            ggml_backend_reg_t reg = ggml_backend_load(name);
            if (reg) {
                LOGI("CPU backend loaded via filename: %s", name);
                break;
            } else {
                LOGI("Failed to load %s: %s", name, dlerror() ? dlerror() : "unknown");
            }
        }
        LOGI("Backends after filename load: %zu", ggml_backend_reg_count());
    }

    // Try 4: Full path as last resort.
    if (ggml_backend_reg_count() == 0) {
        LOGI("Trying full path load...");
        std::string cpu_path = std::string(lib_dir) + "/libggml-cpu-android_armv8.2_1.so";
        ggml_backend_reg_t reg = ggml_backend_load(cpu_path.c_str());
        if (reg) {
            LOGI("CPU backend loaded via full path");
        } else {
            LOGE("All backend loading strategies failed. dlopen error: %s",
                 dlerror() ? dlerror() : "unknown");
        }
        LOGI("Backends after full path load: %zu", ggml_backend_reg_count());
    }

    llama_backend_init();
    env->ReleaseStringUTFChars(nativeLibDir, lib_dir);

    LOGI("Loading model from file...");
    llama_model_params model_params = llama_model_default_params();
    model = llama_model_load_from_file(path, model_params);

    if (!model) {
        LOGE("Failed to load model from: %s", path);
        env->ReleaseStringUTFChars(modelPath, path);
        return JNI_FALSE;
    }
    LOGI("Model loaded successfully");

    LOGI("Creating context...");
    llama_context_params ctx_params = llama_context_default_params();
    ctx = llama_init_from_model(model, ctx_params);

    env->ReleaseStringUTFChars(modelPath, path);

    if (ctx) {
        LOGI("Context created successfully");
    } else {
        LOGE("Failed to create context");
    }

    return ctx != nullptr ? JNI_TRUE : JNI_FALSE;
}

// ---------------------------------------------------------------------------
// generate  — Run inference on a prompt and return generated text.
//
// Steps:
//  1. Clear the KV cache so the full prompt is decoded fresh each call.
//  2. Tokenise the prompt.
//  3. Feed tokens through the model (prefill / decode).
//  4. Build a sampler chain: repeat_penalty → top_k → top_p → temp → dist.
//  5. Sample tokens in a loop until EOS or maxTokens is reached.
// ---------------------------------------------------------------------------
extern "C"
JNIEXPORT jstring JNICALL
Java_com_theorangeshade_onenm_1local_1llm_OneNmNative_generate(
        JNIEnv * env,
        jobject thiz,
        jstring prompt,
        jfloat temperature,
        jint topK,
        jfloat topP,
        jint maxTokens,
        jfloat repeatPenalty) {

    if (!ctx || !model) {
        return env->NewStringUTF("Model not loaded");
    }

    const char * prompt_chars = env->GetStringUTFChars(prompt, nullptr);
    std::string prompt_str(prompt_chars);
    LOGI("generate called with prompt: %s", prompt_chars);
    LOGI("settings: temp=%.2f top_k=%d top_p=%.2f max=%d repeat=%.2f",
         (float)temperature, (int)topK, (float)topP, (int)maxTokens, (float)repeatPenalty);

    const llama_vocab * vocab = llama_model_get_vocab(model);

    // Clear model memory so the full conversation prompt is decoded fresh.
    // This is essential for multi-turn chat: each call sends the entire
    // conversation history, so stale state would corrupt output.
    llama_memory_clear(llama_get_memory(ctx), true);

    // Tokenize the prompt
    int n = prompt_str.size() + 128;
    std::vector<llama_token> tokens(n);

    int token_count = llama_tokenize(
            vocab,
            prompt_str.c_str(),
            prompt_str.length(),
            tokens.data(),
            tokens.size(),
            true,
            true);

    tokens.resize(token_count);
    LOGI("Tokenized prompt: %d tokens", token_count);

    // Decode the prompt
    llama_batch batch = llama_batch_get_one(tokens.data(), tokens.size());
    if (llama_decode(ctx, batch) != 0) {
        LOGE("Failed to decode prompt");
        env->ReleaseStringUTFChars(prompt, prompt_chars);
        return env->NewStringUTF("Error: failed to decode prompt");
    }

    // Set up sampler chain.  Order matters:
    // penalties → top-k → top-p → temperature → distribution sampling.
    auto sparams = llama_sampler_chain_default_params();
    struct llama_sampler * smpl = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(smpl, llama_sampler_init_penalties(
            64, repeatPenalty, 0.0f, 0.0f));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(topK));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(topP, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(42));

    std::string result;

    // Auto-regressive generation loop.
    for (int i = 0; i < (int)maxTokens; i++) {
        llama_token new_token = llama_sampler_sample(smpl, ctx, -1);

        // Check for end of generation
        if (llama_vocab_is_eog(vocab, new_token)) {
            LOGI("EOS reached after %d tokens", i);
            break;
        }

        // Convert token to text
        char piece[256];
        int len = llama_token_to_piece(
                vocab,
                new_token,
                piece,
                sizeof(piece),
                0,
                true);

        if (len > 0) {
            result.append(piece, len);
        }

        // Prepare next batch with the sampled token
        llama_batch next_batch = llama_batch_get_one(&new_token, 1);
        if (llama_decode(ctx, next_batch) != 0) {
            LOGE("Failed to decode at token %d", i);
            break;
        }
    }

    llama_sampler_free(smpl);
    env->ReleaseStringUTFChars(prompt, prompt_chars);

    LOGI("Generated %zu chars", result.size());
    return env->NewStringUTF(result.c_str());
}

// ---------------------------------------------------------------------------
// releaseModel  — Free all native resources.
// ---------------------------------------------------------------------------
extern "C"
JNIEXPORT void JNICALL
Java_com_theorangeshade_onenm_1local_1llm_OneNmNative_releaseModel(
        JNIEnv * env,
        jobject thiz) {

    if (ctx) {
        llama_free(ctx);
        ctx = nullptr;
    }

    if (model) {
        llama_model_free(model);
        model = nullptr;
    }

    llama_backend_free();
}