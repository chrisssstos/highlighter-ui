import QtQuick

/// A raised panel: the raised colour, and in the classic skin a soft
/// gradient, a dark outline and a raised bevel. Flat otherwise.
Item {
    id: plate

    property color color: Theme.raised

    Rectangle {
        anchors.fill: parent
        color: plate.color
        gradient: Theme.classic ? classicFace : null
        Gradient {
            id: classicFace
            GradientStop { position: 0; color: Qt.lighter(plate.color, 1.22) }
            GradientStop { position: 1; color: Qt.darker(plate.color, 1.05) }
        }
    }
    Rectangle { anchors.fill: parent; visible: Theme.classic; color: "transparent"; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.7) }
    ParamBevel { anchors.fill: parent; anchors.margins: 1; visible: Theme.classic; light: 0.2; dark: 0.4 }
    // hardware: a faceplate edge, lit from above
    Rectangle { visible: Theme.hardware; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.10) }
    Rectangle { visible: Theme.hardware; y: parent.height - 1; width: parent.width; height: 1; color: Qt.rgba(0, 0, 0, 0.35) }
}
