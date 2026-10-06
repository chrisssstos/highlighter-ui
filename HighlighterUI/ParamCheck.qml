import QtQuick

/// A tick box with its label to the right: a stroked square, filled with a
/// lime square when on. Click it, or its label.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string text: ""
    property bool checked: false
    signal toggled(bool checked)

    implicitHeight: Math.max(Theme.s(22), label.implicitHeight)
    implicitWidth: box.width + (text.length ? Theme.s(8) + label.implicitWidth : 0)
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    // Tells you first; it only flips itself if you didn't, so checked bound
    // to your own state stays bound.
    function flip() {
        const want = !root.checked
        root.toggled(want)
        if (root.checked !== want) root.checked = want
    }

    Rectangle {
        id: box
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.s(16); height: width
        radius: Theme.radius
        color: area.containsMouse ? Theme.wellHover : Theme.well
        border.width: 1
        border.color: root.checked || area.containsMouse || (root.activeFocus && !area.focusedByMouse) ? root.tint : Theme.line
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.s(3)
            color: root.tint
            scale: root.checked ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutBack } }
        }
    }
    Text {
        id: label
        x: box.width + Theme.s(8)
        width: parent.width - x
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.family
        font.pixelSize: Theme.labelSize
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        property bool focusedByMouse: false
        onPressed: { focusedByMouse = true; root.forceActiveFocus(Qt.MouseFocusReason) }
        onClicked: root.flip()
    }
    onActiveFocusChanged: if (!activeFocus) area.focusedByMouse = false
    Keys.onPressed: e => { if (e.key === Qt.Key_Space || e.key === Qt.Key_Return) { area.focusedByMouse = false; root.flip(); e.accepted = true } }
}
