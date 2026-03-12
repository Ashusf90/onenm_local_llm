#include <jni.h>
#include <string>

extern "C"
JNIEXPORT jstring JNICALL
Java_com_example_onenm_1local_1llm_OneNmNative_ping(
    JNIEnv* env,
    jobject thiz
) {
    std::string msg = "Native bridge is working";
    return env->NewStringUTF(msg.c_str());
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_onenm_1local_1llm_OneNmNative_loadModel(
    JNIEnv* env,
    jobject thiz,
    jstring modelPath
) {
    const char* path = env->GetStringUTFChars(modelPath, nullptr);

    bool ok = true;

    env->ReleaseStringUTFChars(modelPath, path);
    return ok ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_example_onenm_1local_1llm_OneNmNative_generate(
    JNIEnv* env,
    jobject thiz,
    jstring prompt
) {
    const char* promptChars = env->GetStringUTFChars(prompt, nullptr);

    std::string response = std::string("Stub response for: ") + promptChars;

    env->ReleaseStringUTFChars(prompt, promptChars);
    return env->NewStringUTF(response.c_str());
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_onenm_1local_1llm_OneNmNative_releaseModel(
    JNIEnv* env,
    jobject thiz
) {
}