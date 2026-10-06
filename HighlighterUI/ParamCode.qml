import QtQuick

/// A block of text to copy out, like settings ready to paste into a TOML
/// file. Folded by default: its title, how many lines, and a Copy button
/// that copies it all without opening it; a click on the title opens it to
/// read or select from. Like ParamGroup, open bound to your own state stays
/// bound (set your state in onToggled).
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string title: ""
    property string text: ""
    property bool open: false

    signal toggled(bool open)

    //! Opens or folds it, as a click on its title does. Tells you first; it
    //! only does it itself if you didn't.
    function flip() {
        const want = !root.open
        root.toggled(want)
        if (root.open !== want) root.open = want
    }

    readonly property int lines: root.text.length ? root.text.split("\n").length : 0

    implicitWidth: Theme.s(300)
    implicitHeight: head.height + (root.open ? Theme.rowGap + block.height : 0)

    Item {
        id: head
        width: parent.width
        height: Math.max(cap.implicitHeight, copy.implicitHeight)

        ParamArrow {
            id: chevron
            x: Theme.s(2)
            anchors.verticalCenter: parent.verticalCenter
            direction: Qt.RightArrow
            width: Theme.s(7); height: Theme.s(9)
            color: headArea.containsMouse ? root.tint : Theme.textDim
            rotation: root.open ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }
        }
        Text {
            id: cap
            x: chevron.x + chevron.width + Theme.s(8)
            width: copy.x - x - Theme.s(8)
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: (root.title.length ? root.title.toUpperCase() + "  " : "")
                  + "<font color=\"" + Theme.textFaint + "\">" + root.lines + (root.lines === 1 ? " line" : " lines") + "</font>"
            color: Theme.textDim
            font.family: Theme.family
            font.pixelSize: Theme.smallSize
            font.weight: Font.Bold
            font.letterSpacing: Theme.s(1)
        }
        MouseArea {
            id: headArea
            width: copy.x
            height: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.flip()
        }
        ParamButton {
            id: copy
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Theme.s(22)
            text: done.running ? "Copied" : "Copy"
            icon: done.running ? "✓" : ""
            onClicked: { edit.selectAll(); edit.copy(); edit.deselect(); done.restart() }
            Timer { id: done; interval: 1400 }
        }
    }

    Rectangle {
        id: block
        visible: root.open
        y: head.height + Theme.rowGap
        width: parent.width
        height: edit.implicitHeight + 2 * Theme.s(10)
        color: Theme.sunken
        radius: Theme.radius
        Rectangle { width: Theme.s(3); height: parent.height; color: root.tint; opacity: 0.6 }

        TextEdit {
            id: edit
            x: Theme.s(14); y: Theme.s(10)
            width: parent.width - x - Theme.s(14)
            text: root.text
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.WrapAnywhere
            color: Theme.text
            selectionColor: root.tint
            selectedTextColor: Theme.inkOf(root.tint)
            font.family: Theme.mono
            font.pixelSize: Theme.s(12)
        }
    }
}
