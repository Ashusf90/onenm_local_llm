cmake_minimum_required(VERSION 3.22.1)
project(onenm)

add_library(onenm_bridge SHARED onenm_bridge.cpp)

find_library(log-lib log)

target_link_libraries(
    onenm_bridge
    ${log-lib}
)