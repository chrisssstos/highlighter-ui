# ParamKit as a QML module, for an app to link:
#
#   add_subdirectory(<path to param-kit>/ParamKit ${CMAKE_BINARY_DIR}/ParamKit)
#   target_link_libraries(<app> PRIVATE ParamKitplugin)
#
# then `import ParamKit` in QML.
cmake_minimum_required(VERSION 3.21)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2)

set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_library(ParamKit STATIC)
qt_add_qml_module(ParamKit
    URI ParamKit
    VERSION 1.0
    QML_FILES
        Theme.qml
        ParamMath.js
        ParamArrow.qml
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
)
target_link_libraries(ParamKit PRIVATE Qt6::Quick Qt6::QuickControls2)
