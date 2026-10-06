# Proves ParamKit links into an app the way a project would use it: builds
# the gallery as a compiled app. tests/build-check.bat runs it.
cmake_minimum_required(VERSION 3.21)
project(ParamKitConsumer LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.5)

add_subdirectory(../../ParamKit ${CMAKE_BINARY_DIR}/ParamKit)

qt_add_executable(ParamKitGallery main.cpp)
qt_add_qml_module(ParamKitGallery
    URI Consumer
    VERSION 1.0
    QML_FILES Gallery.qml
)
target_link_libraries(ParamKitGallery PRIVATE Qt6::Quick ParamKitplugin)
