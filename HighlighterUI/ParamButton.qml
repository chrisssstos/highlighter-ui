import QtQuick

/// A flat, slightly bevelled button: lime text on a dark slab, or a solid
/// lime one (accent) for the action that matters. checkable makes it stay
/// down, marked by a lime bar on its left. Space or Enter press it too.
Item {
    id: root

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

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
    // From the texts' natural widths, so a button given less room (or the
    // kit scaled up) cuts its label short with an ellipsis instead of
    // spilling past its edges.
    implicitWidth: (glyph.visible ? glyph.implicitWidth : 0)
                 + (glyph.visible && label.visible ? content.spacing : 0)
                 + (label.visible ? label.implicitWidth : 0)
                 + 2 * horizontalPadding
                 + (Theme.classic && checkable ? Theme.s(12) : 0)   // the LED
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function activate() {
        if (root.checkable) { root.checked = !root.checked; root.toggled(root.checked) }
        root.clicked()
    }

    readonly property color ink: root.accent ? Theme.inkOf(root.tint)
                              : root.danger ? Theme.danger
                              : root.checked ? root.tint
                              : Theme.classic ? Theme.text : root.tint

    Rectangle {
        id: slab
        anchors.fill: parent
        radius: Theme.radius
        color: root.accent ? (area.pressed ? Qt.darker(root.tint, 1.18) : area.containsMouse ? Qt.lighter(root.tint, 1.07) : root.tint)
             : root.checked ? (area.pressed ? Theme.sunken : Theme.sunkenHover)
             : (area.pressed ? Qt.darker(Theme.sunken, 1.15) : area.containsMouse ? Theme.sunkenHover : Theme.sunken)
        Behavior on color { ColorAnimation { duration: Theme.quick } }
        // classic: lighter at the top, a raised bevel, sunk when pressed
        gradient: Theme.classic ? classicFace : null
        Gradient {
            id: classicFace
            GradientStop { position: 0; color: Qt.lighter(slab.color, area.pressed || root.checked ? 0.92 : 1.28) }
            GradientStop { position: 1; color: Qt.darker(slab.color, area.pressed || root.checked ? 0.95 : 1.08) }
        }
        Rectangle { anchors.fill: parent; visible: Theme.classic; color: "transparent"; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.7) }
        ParamBevel {
            anchors.fill: parent; anchors.margins: 1
            visible: Theme.classic
            inset: area.pressed || root.checked
            light: root.accent ? 0.35 : 0.22
            dark: 0.4
        }

        // flat bevel: light top, dark bottom, swapped when pressed
        Rectangle { visible: !Theme.classic; width: parent.width; height: 1; color: area.pressed ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, root.accent ? 0.25 : 0.07) }
        Rectangle { visible: !Theme.classic; y: parent.height - 1; width: parent.width; height: 1; color: area.pressed ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.3) }

        // checked, classic: an LED, lit when down
        Item {
            id: led
            visible: Theme.classic && root.checkable
            x: Theme.s(8); anchors.verticalCenter: parent.verticalCenter
            width: Theme.s(6); height: width
            Rectangle {   // its glow
                anchors.centerIn: parent
                width: parent.width + Theme.s(6); height: width
                color: root.tint; opacity: root.checked ? 0.22 : 0
            }
            Rectangle {
                anchors.fill: parent
                color: root.checked ? root.tint : Qt.rgba(0, 0, 0, 0.45)
                border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.5)
            }
        }

        // checked, flat: a lime bar on the left
        Rectangle {
            visible: root.checkable && !Theme.classic
            width: Theme.s(3); height: parent.height
            color: root.checked ? root.tint : Theme.line
        }

        // keyboard focus
        Rectangle {
            anchors.fill: parent; anchors.margins: -Theme.s(2)
            color: "transparent"; border.width: 1; border.color: root.tint
            opacity: root.activeFocus && !area.focusedByMouse ? 0.6 : 0
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        anchors.verticalCenterOffset: area.pressed ? 1 : 0
        anchors.horizontalCenterOffset: led.visible ? Theme.s(6) : 0
        spacing: Theme.s(6)
        Text {
            id: glyph
            visible: root.icon.length > 0
            text: root.icon
            color: root.ink
            font.family: Theme.family
            font.pixelSize: Theme.labelSize
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: label
            visible: root.text.length > 0
            width: Math.max(0, Math.min(implicitWidth, root.width - 2 * root.horizontalPadding
                                        - (led.visible ? Theme.s(12) : 0)
                                        - (glyph.visible ? glyph.implicitWidth + content.spacing : 0)))
            elide: Text.ElideRight
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
