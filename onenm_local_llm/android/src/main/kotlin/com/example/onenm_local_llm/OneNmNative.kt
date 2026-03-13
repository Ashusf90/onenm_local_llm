package com.example.onenm_local_llm

class OneNmNative {
    external fun loadModel(modelPath: String, nativeLibDir: String): Boolean
    external fun generate(prompt: String, temperature: Float, topK: Int, topP: Float, maxTokens: Int, repeatPenalty: Float): String
    external fun releaseModel()

    companion object {
        init {
            System.loadLibrary("omp")
            System.loadLibrary("ggml")
            System.loadLibrary("ggml-base")
            System.loadLibrary("ggml-cpu-android_armv8.2_1")
            System.loadLibrary("llama")
            System.loadLibrary("onenm_bridge")
        }
    }
}