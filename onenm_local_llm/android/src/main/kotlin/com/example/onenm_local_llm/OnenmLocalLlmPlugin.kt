// Copyright 2026 1nm. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.example.onenm_local_llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

/**
 * Flutter plugin for on-device LLM inference using llama.cpp.
 *
 * This plugin acts as the bridge between the Dart layer and [OneNmNative],
 * routing method-channel calls to the C++ backend via JNI.
 *
 * ## Supported methods
 *
 * | Method         | Arguments                               | Returns   |
 * |----------------|----------------------------------------|-----------|
 * | `pingNative`   | —                                      | `"pong"` |
 * | `loadModel`    | `modelPath: String`                    | `Boolean` |
 * | `generate`     | `prompt, temperature, topK, topP, ...` | `String`  |
 * | `releaseModel` | —                                      | `null`    |
 */
class OnenmLocalLlmPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  /** Lazily initialised JNI bridge — deferred to avoid UnsatisfiedLinkError on registration. */
  private var native: OneNmNative? = null

  /** Coroutine scope for running model operations off the main thread. */
  private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

  /** Absolute path to the app's native library directory (contains .so files). */
  private var nativeLibDir: String? = null

  /** Returns the shared [OneNmNative] instance, creating it on first access. */
  private fun getNative(): OneNmNative {
    if (native == null) {
      native = OneNmNative()
    }
    return native!!
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "onenm_local_llm")
    channel.setMethodCallHandler(this)
    nativeLibDir = flutterPluginBinding.applicationContext.applicationInfo.nativeLibraryDir
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "pingNative" -> result.success("pong")

      "loadModel" -> {
        val modelPath = call.argument<String>("modelPath")
        if (modelPath == null) {
          result.error("INVALID_ARGUMENT", "modelPath is required", null)
        } else {
          val libDir = nativeLibDir ?: ""
          scope.launch {
            try {
              val loaded = getNative().loadModel(modelPath, libDir)
              withContext(Dispatchers.Main) {
                result.success(loaded)
              }
            } catch (e: Exception) {
              withContext(Dispatchers.Main) {
                result.error("LOAD_ERROR", e.message, null)
              }
            }
          }
        }
      }

      "generate" -> {
        val prompt = call.argument<String>("prompt")
        if (prompt == null) {
          result.error("INVALID_ARGUMENT", "prompt is required", null)
        } else {
          val temperature = (call.argument<Double>("temperature") ?: 0.7).toFloat()
          val topK = call.argument<Int>("topK") ?: 40
          val topP = (call.argument<Double>("topP") ?: 0.9).toFloat()
          val maxTokens = call.argument<Int>("maxTokens") ?: 128
          val repeatPenalty = (call.argument<Double>("repeatPenalty") ?: 1.1).toFloat()
          scope.launch {
            try {
              val output = getNative().generate(prompt, temperature, topK, topP, maxTokens, repeatPenalty)
              withContext(Dispatchers.Main) {
                result.success(output)
              }
            } catch (e: Exception) {
              withContext(Dispatchers.Main) {
                result.error("GENERATE_ERROR", e.message, null)
              }
            }
          }
        }
      }

      "releaseModel" -> {
        native?.releaseModel()
        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    scope.cancel()
  }
}