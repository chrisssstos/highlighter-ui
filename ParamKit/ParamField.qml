import QtQuick

/// A labelled one-line text field: a name, a path, a URL. Enter or leaving
/// it reports the text (accepted); Esc puts the old text back.
Item {
    id: root

    property string label: ""
    property string text: ""
    property string placeholder: ""
    property bool mono: false
    signal accepted(string text)

    readonly property bool editing: input.activeFocus

    implicitWidth: Theme.s(280)
    implicitHeight: (title.visible ? title.implicitHeight + Theme.rowGap : 0) + field.height
    opacity: enabled ? 1 : 0.4

    Text {
        id: title
        visible: root.label.length > 0
        width: parent.width
        text: root.label
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.family
        font.pixelSize: Theme.labelSize
    }

    Rectangle {
        id: field
        y: title.visible ? title.implicitHeight + Theme.rowGap : 0
        width: parent.width
        height: Theme.s(26)
        radius: Theme.radius
        color: root.editing ? Theme.sunken : (hover.hovered ? Theme.wellHover : Theme.well)
        border.width: 1
        border.color: root.editing ? Theme.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.quick } }

        TextInput {
            id: input
            anchors.fill: parent
            leftPadding: Theme.s(8); rightPadding: Theme.s(8)
            verticalAlignment: Text.AlignVCenter
            text: root.text
            clip: true
            selectByMouse: true
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            font.family: root.mono ? Theme.mono : Theme.family
            font.pixelSize: Theme.labelSize
            property bool cancelling: false
            onAccepted: focus = false
            onActiveFocusChanged: if (!activeFocus && !cancelling && text !== root.text) { root.text = text; root.accepted(text) }
            Keys.onEscapePressed: { cancelling = true; text = root.text; focus = false; cancelling = false }
        }
        Text {
            anchors.fill: parent
            leftPadding: Theme.s(8)
            verticalAlignment: Text.AlignVCenter
            visible: !input.text.length && !root.editing
            text: root.placeholder
            color: Theme.textFaint
            font: input.font
            elide: Text.ElideRight
        }
        HoverHandler { id: hover; cursorShape: Qt.IBeamCursor }
    }
}
