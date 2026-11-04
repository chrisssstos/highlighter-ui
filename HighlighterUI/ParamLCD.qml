import QtQuick

/// A reflective LCD, as on a hardware unit: a pale grey-green glass in a dark
/// bezel, lit by the room, not backlit. Put a ParamSevenSeg (ink: Theme.lcdInk,
/// ghost: Theme.lcdGhost) or ParamText inside; give the LCD a size or let it
/// take its content's (padding round it). A small caps label can sit in the
/// glass's top left corner.
Item {
    id: lcd
    property string label: ""
    property real padding: Theme.s(6)
    default property alias content: glass.data

    implicitWidth: glass.childrenRect.width + 2 * padding + 2 * bezel.border.width
    implicitHeight: glass.childrenRect.height + 2 * padding + 2 * bezel.border.width
                    + (title.visible ? title.implicitHeight : 0)

    Rectangle {
        id: bezel
        anchors.fill: parent
        color: Theme.lcd
        border.width: Theme.s(2)
        border.color: "#202122"
        // the glass: a little lighter at the top, a soft inner shade along the top edge
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(Theme.lcd, 1.06) }
            GradientStop { position: 1; color: Qt.darker(Theme.lcd, 1.04) }
        }
        Rectangle {
            x: bezel.border.width; y: bezel.border.width
            width: parent.width - 2 * bezel.border.width
            height: Theme.s(3)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.18) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
            }
        }
    }
    Text {
        id: title
        visible: lcd.label.length > 0
        x: bezel.border.width + lcd.padding
        y: bezel.border.width + Theme.s(3)
        text: lcd.label.toUpperCase()
        color: Theme.lcdInk
        opacity: 0.75
        font.family: Theme.mono
        font.pixelSize: Theme.s(9)
        font.weight: Font.Bold
        font.letterSpacing: Theme.s(1)
    }
    Item {
        id: glass
        x: bezel.border.width + lcd.padding
        y: bezel.border.width + lcd.padding + (title.visible ? title.implicitHeight : 0)
        width: parent.width - 2 * x
        height: parent.height - y - bezel.border.width - lcd.padding
    }
}
