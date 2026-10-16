cmake_minimum_required(VERSION 3.20)

project(SLMaster LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build configuration" FORCE)
endif()
if(MSVC)
    # Qt and PCL provide separate Debug runtimes; keep the application ABI in sync.
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    add_compile_options(/utf-8)
endif()

add_subdirectory(src)

option(BUILD_GUI "build the gui." ON)

if(BUILD_GUI)
    add_subdirectory(gui)
    message(NOTICE "[SLMaster]: build gui...")
endif()

option(BUILD_TEST "build the test case with google_test." OFF)

if(BUILD_TEST)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/test)
    message(NOTICE "[SLMaster]: build test case...")
endif()

option(BUILD_PERF "build the perfermance case with google benchmark." OFF)

if(BUILD_PERF)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/perf)
    message(NOTICE "[SLMaster]: build perfermance case...")
endif()
