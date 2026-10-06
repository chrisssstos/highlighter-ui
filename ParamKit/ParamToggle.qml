import QtQuick

/// An on/off switch with its label to the right. Click it, or its label.
Item {
    id: root

    property string text: ""
    property bool checked: false
    signal toggled(bool checked)

    implicitHeight: Math.max(Theme.s(22), label.implicitHeight)
    implicitWidth: pill.width + (text.length ? Theme.s(8) + label.implicitWidth : 0)
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function flip() { root.checked = !root.checked; root.toggled(root.checked) }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.s(36); height: Theme.s(18)
        radius: height / 2
        color: root.checked ? Theme.accent : (area.containsMouse ? Theme.wellHover : Theme.well)
        Behavior on color { ColorAnimation { duration: Theme.ease } }
        border.width: root.activeFocus && !area.focusedByMouse ? 1 : 0
        border.color: Theme.text

        Rectangle {
            width: parent.height - Theme.s(4); height: width
            radius: width / 2
            y: Theme.s(2)
            x: root.checked ? parent.width - width - Theme.s(2) : Theme.s(2)
            color: root.checked ? Theme.accentInk : Theme.arrow
            Behavior on x { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.ease } }
        }
    }
    Text {
        id: label
        x: pill.width + Theme.s(8)
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
