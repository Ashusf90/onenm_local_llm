package com.example.onenm_local_llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

class OnenmLocalLlmPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var native: OneNmNative? = null
  private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
  private var nativeLibDir: String? = null

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
          scope.launch {
            try {
              val output = getNative().generate(prompt)
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