import QtQuick

/// A rack rail: a strip of satin aluminium with its row of threaded holes,
/// that a module is bolted to (industrial look).
Item {
    id: rail

    height: Theme.s(10)

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#9aa09e" }
            GradientStop { position: 0.45; color: "#7b817f" }
            GradientStop { position: 1; color: "#4f5453" }
        }
        border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.55)
    }
    // the threaded holes, one every 5.08 mm in a real rack; one per 10 px here
    Row {
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.s(4)
        spacing: Theme.s(7)
        Repeater {
            model: Math.max(0, Math.floor((rail.width - Theme.s(4)) / Theme.s(10)))
            Rectangle {
                width: Theme.s(3); height: Theme.s(4)
                color: Qt.rgba(0, 0, 0, 0.65)
                Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.25) }
            }
        }
    }
}
