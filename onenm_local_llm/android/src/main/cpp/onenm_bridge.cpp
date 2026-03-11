#include <jni.h>
#include <string>

extern "C"
JNIEXPORT jstring JNICALL
Java_com_example_onenm_OneNmNative_ping(
        JNIEnv* env,
        jobject /* this */) {
    std::string msg = "Native bridge is working";
    return env->NewStringUTF(msg.c_str());
}