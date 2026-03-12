package com.example.onenm_local_llm

class OneNmNative {
    external fun ping(): String

    companion object {
        init {
            System.loadLibrary("onenm_bridge")
        }
    }
}