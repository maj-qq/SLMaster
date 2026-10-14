cmake_minimum_required(VERSION 3.20)
project(SLMasterVTKQt VERSION 9.3.0 LANGUAGES C CXX)

find_package(VTK 9.3 REQUIRED)
if(NOT VTK_VERSION VERSION_EQUAL PROJECT_VERSION)
    message(FATAL_ERROR "Qt modules and the installed VTK must have the same version.")
endif()
set(VTK_SOURCE_DIR "" CACHE PATH "VTK source matching the installed binary package")
list(APPEND CMAKE_MODULE_PATH "${VTK_SOURCE_DIR}/CMake")
include(GNUInstallDirs)
include(vtkModuleTesting)
set(VTK_QT_VERSION 6 CACHE STRING "Qt major version")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INSTALL_QMLDIR "qml")
set(BUILD_SHARED_LIBS ON)
set(BUILD_TESTING OFF)
set(VTK_BUILD_TESTING OFF)

vtk_module_scan(
    MODULE_FILES
        "${VTK_SOURCE_DIR}/GUISupport/Qt/vtk.module"
        "${VTK_SOURCE_DIR}/GUISupport/QtQuick/vtk.module"
    REQUEST_MODULES VTK::GUISupportQt VTK::GUISupportQtQuick
    PROVIDES_MODULES slmaster_vtk_qt_modules
    ENABLE_TESTS OFF)
vtk_module_build(
    MODULES ${slmaster_vtk_qt_modules}
    PACKAGE SLMasterVTKQt
    INSTALL_EXPORT SLMasterVTKQt
    LIBRARY_NAME_SUFFIX "9.3"
    ENABLE_WRAPPING OFF
    TEST_DIRECTORY_NAME NONE)
target_include_directories(GUISupportQt PRIVATE "${VTK_SOURCE_DIR}/Rendering/OpenGL2")

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/SLMasterVTKQtConfig.cmake"
    "include(CMakeFindDependencyMacro)\nfind_dependency(VTK 9.3)\nfind_dependency(Qt${VTK_QT_VERSION} COMPONENTS Widgets OpenGL OpenGLWidgets Quick Qml)\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/SLMasterVTKQt-targets.cmake\")\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/SLMasterVTKQt-vtk-module-properties.cmake\")\n")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/SLMasterVTKQtConfig.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/SLMasterVTKQt")
