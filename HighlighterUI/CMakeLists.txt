# HighlighterUI as a QML module, for an app to link:
#
#   add_subdirectory(<path to highlighter-ui>/HighlighterUI ${CMAKE_BINARY_DIR}/HighlighterUI)
#   target_link_libraries(<app> PRIVATE HighlighterUIplugin)
#
# then `import HighlighterUI` in QML.
cmake_minimum_required(VERSION 3.21)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick QuickControls2)

set_source_files_properties(Theme.qml PanelMemory.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_library(HighlighterUI STATIC)
qt_add_qml_module(HighlighterUI
    URI HighlighterUI
    VERSION 1.0
    QML_FILES
        Theme.qml
        PanelMemory.qml
        ParamMath.js
        ParamArrow.qml
        ParamPlate.qml
        ParamBevel.qml
        ParamSizeMark.qml
        ParamValueBox.qml
        ParamSlider.qml
        ParamKnob.qml
        ParamButton.qml
        ParamToggle.qml
        ParamCheck.qml
        ParamChoice.qml
        ParamCombo.qml
        ParamField.qml
        ParamMeter.qml
        ParamHeading.qml
        ParamGroup.qml
        ParamCode.qml
        ParamPage.qml
        ParamScrollBar.qml
        ParamGrid.qml
        ParamSection.qml
        ParamGauge.qml
        ParamLevel.qml
        ParamSwatches.qml
        ParamXY.qml
        ParamText.qml
        ParamLight.qml
    RESOURCES
        textures/knob_classic.png
        textures/sheen.png
)
target_link_libraries(HighlighterUI PRIVATE Qt6::Quick Qt6::QuickControls2)
