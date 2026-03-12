cmake_minimum_required(VERSION 3.22.1)
project(onenm)

add_library(onenm_bridge SHARED onenm_bridge.cpp)

include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/llama
)

# Path to your prebuilt libraries
set(LIB_PATH ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI})

add_library(llama SHARED IMPORTED)
set_target_properties(llama PROPERTIES
        IMPORTED_LOCATION ${LIB_PATH}/libllama.so
        IMPORTED_NO_SONAME TRUE)

add_library(ggml SHARED IMPORTED)
set_target_properties(ggml PROPERTIES
        IMPORTED_LOCATION ${LIB_PATH}/libggml.so
        IMPORTED_NO_SONAME TRUE)

add_library(ggml-base SHARED IMPORTED)
set_target_properties(ggml-base PROPERTIES
        IMPORTED_LOCATION ${LIB_PATH}/libggml-base.so
        IMPORTED_NO_SONAME TRUE)

add_library(ggml-cpu SHARED IMPORTED)
set_target_properties(ggml-cpu PROPERTIES
        IMPORTED_LOCATION ${LIB_PATH}/libggml-cpu-android_armv8.2_1.so
        IMPORTED_NO_SONAME TRUE)

add_library(omp SHARED IMPORTED)
set_target_properties(omp PROPERTIES
        IMPORTED_LOCATION ${LIB_PATH}/libomp.so
        IMPORTED_NO_SONAME TRUE)

find_library(log-lib log)

target_link_libraries(
        onenm_bridge
        llama
        ggml
        ggml-base
        ggml-cpu
        omp
        ${log-lib}
)