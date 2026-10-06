import QtQuick

/// A small heading over a run of controls, with a rule running off it.
Item {
    id: root
    property string text: ""
    property string note: ""

    implicitWidth: Theme.s(280)
    implicitHeight: t.implicitHeight + Theme.s(6)

    Row {
        id: row
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.s(2)
        spacing: Theme.s(8)
        Text {
            id: t
            text: root.text.toUpperCase()
            color: Theme.textDim
            font.family: Theme.family
            font.pixelSize: Theme.smallSize
            font.weight: Font.Bold
            font.letterSpacing: Theme.s(1)
        }
        Text {
            visible: root.note.length > 0
            text: root.note
            color: Theme.textFaint
            font.family: Theme.family
            font.pixelSize: Theme.smallSize
            anchors.baseline: t.baseline
        }
    }
    Rectangle {
        x: row.width + Theme.s(10)
        width: Math.max(0, parent.width - x)
        height: 1
        anchors.verticalCenter: row.verticalCenter
        color: Theme.line
        opacity: 0.6
    }
}
