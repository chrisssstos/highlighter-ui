# OutputMapper as a QML module, for an app to link (with HighlighterUI, which
# its editor is drawn with):
#
#   add_subdirectory(<path>/HighlighterUI  ${CMAKE_BINARY_DIR}/HighlighterUI)
#   add_subdirectory(<path>/OutputMapper   ${CMAKE_BINARY_DIR}/OutputMapper)
#   target_link_libraries(<app> PRIVATE HighlighterUIplugin OutputMapperplugin)
#
# then `import OutputMapper` in QML.
cmake_minimum_required(VERSION 3.21)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Quick)

qt_add_library(OutputMapper STATIC)
qt_add_qml_module(OutputMapper
    URI OutputMapper
    VERSION 1.0
    SOURCES
        warpmath.h warpmath.cpp
        warpmesh.h warpmesh.cpp
        warp.h warp.cpp
    QML_FILES
        OutputMap.qml
        MappedOutput.qml
        DisplayOutputs.qml
        MaskShape.qml
        SliceOverlay.qml
        TestCard.qml
        MappingEditor.qml
        MappingWindow.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Shapes
        HighlighterUI
)

target_link_libraries(OutputMapper PRIVATE Qt6::Core Qt6::Gui Qt6::Quick)
