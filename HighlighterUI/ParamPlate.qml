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
}
