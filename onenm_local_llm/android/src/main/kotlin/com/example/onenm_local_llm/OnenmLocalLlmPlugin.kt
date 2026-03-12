package com.example.onenm_local_llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class OnenmLocalLlmPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private val native = OneNmNative()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "onenm_local_llm")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "pingNative" -> result.success(native.ping())

      "loadModel" -> {
        val modelPath = call.argument<String>("modelPath")
        if (modelPath == null) {
          result.error("INVALID_ARGUMENT", "modelPath is required", null)
        } else {
          result.success(native.loadModel(modelPath))
        }
      }

      "generate" -> {
        val prompt = call.argument<String>("prompt")
        if (prompt == null) {
          result.error("INVALID_ARGUMENT", "prompt is required", null)
        } else {
          result.success(native.generate(prompt))
        }
      }

      "releaseModel" -> {
        native.releaseModel()
        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}