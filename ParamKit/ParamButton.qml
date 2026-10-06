import QtQuick

/// A flat, slightly bevelled button: lime text on a dark slab, or a solid
/// lime one (accent) for the action that matters. checkable makes it stay
/// down, marked by a lime bar on its left. Space or Enter press it too.
Item {
    id: root

    property string text: ""
    //! A glyph drawn before the text (any character, e.g. "✓").
    property string icon: ""
    property bool accent: false
    property bool danger: false
    property bool checkable: false
    property bool checked: false
    property int horizontalPadding: Theme.s(12)

    signal clicked()
    signal toggled(bool checked)

    readonly property bool pressed: area.pressed
    readonly property bool hovered: area.containsMouse

    implicitHeight: Theme.s(26)
    implicitWidth: content.implicitWidth + 2 * horizontalPadding
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function activate() {
        if (root.checkable) { root.checked = !root.checked; root.toggled(root.checked) }
        root.clicked()
    }

    readonly property color ink: root.accent ? Theme.accentInk
                              : root.danger ? Theme.danger
                              : root.checked ? Theme.accent
                              : Theme.accent

    Rectangle {
        id: slab
        anchors.fill: parent
        radius: Theme.radius
        color: root.accent ? (area.pressed ? Qt.darker(Theme.accent, 1.18) : area.containsMouse ? Qt.lighter(Theme.accent, 1.07) : Theme.accent)
             : root.checked ? (area.pressed ? Theme.sunken : Theme.sunkenHover)
             : (area.pressed ? Qt.darker(Theme.sunken, 1.15) : area.containsMouse ? Theme.sunkenHover : Theme.sunken)
        Behavior on color { ColorAnimation { duration: Theme.quick } }

        // bevel: a faint light top edge and a dark bottom edge, swapped when pressed
        Rectangle { width: parent.width; height: 1; color: area.pressed ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, root.accent ? 0.25 : 0.07) }
        Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: area.pressed ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.3) }

        // checked: a lime bar on the left
        Rectangle {
            visible: root.checkable
            width: Theme.s(3); height: parent.height
            color: root.checked ? Theme.accent : Theme.line
        }

        // keyboard focus
        Rectangle {
            anchors.fill: parent; anchors.margins: -Theme.s(2)
            color: "transparent"; border.width: 1; border.color: Theme.accent
            opacity: root.activeFocus && !area.focusedByMouse ? 0.6 : 0
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        anchors.verticalCenterOffset: area.pressed ? 1 : 0
        spacing: Theme.s(6)
        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.ink
            font.family: Theme.family
            font.pixelSize: Theme.labelSize
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.text.length > 0
            text: root.text
            color: root.ink
            font.family: Theme.family
            font.pixelSize: Theme.labelSize
            font.weight: root.accent ? Font.DemiBold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        property bool focusedByMouse: false
        onPressed: { focusedByMouse = true; root.forceActiveFocus(Qt.MouseFocusReason) }
        onClicked: root.activate()
    }
    onActiveFocusChanged: if (!activeFocus) area.focusedByMouse = false
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            area.focusedByMouse = false
            root.activate(); e.accepted = true
        }
    }
}
