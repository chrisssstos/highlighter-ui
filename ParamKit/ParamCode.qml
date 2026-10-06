import QtQuick

/// A block of text to copy out, like settings ready to paste into a TOML
/// file, with a Copy button.
Item {
    id: root

    property string title: ""
    property string text: ""

    implicitWidth: Theme.s(300)
    implicitHeight: (title.length ? cap.implicitHeight + Theme.rowGap : 0) + block.height

    Text {
        id: cap
        visible: root.title.length > 0
        text: root.title.toUpperCase()
        color: Theme.textDim
        font.family: Theme.family
        font.pixelSize: Theme.smallSize
        font.weight: Font.Bold
        font.letterSpacing: Theme.s(1)
    }

    Rectangle {
        id: block
        y: root.title.length ? cap.implicitHeight + Theme.rowGap : 0
        width: parent.width
        height: edit.implicitHeight + 2 * Theme.s(10)
        color: Theme.sunken
        radius: Theme.radius
        Rectangle { width: Theme.s(3); height: parent.height; color: Theme.accent; opacity: 0.6 }

        TextEdit {
            id: edit
            x: Theme.s(14); y: Theme.s(10)
            width: parent.width - x - copy.width - Theme.s(16)
            text: root.text
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.WrapAnywhere
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            font.family: Theme.mono
            font.pixelSize: Theme.s(12)
        }
        ParamButton {
            id: copy
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.s(6)
            implicitHeight: Theme.s(22)
            text: done.running ? "Copied" : "Copy"
            icon: done.running ? "✓" : ""
            onClicked: { edit.selectAll(); edit.copy(); edit.deselect(); done.restart() }
            Timer { id: done; interval: 1400 }
        }
    }
}
