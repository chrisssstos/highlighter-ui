import QtQuick
import QtQuick.Controls.Basic as B
import "ParamMath.js" as PM

/// A colour setting: its name and a chip of the colour; click the chip to
/// pick one: drag in the square for how strong and how bright, along the
/// strip for the hue, type a hex code, or take a preset swatch. Like the
/// other controls it tells you first: bind `color` to your setting and set
/// it in onPicked. `resettable` adds a mark that sends reset() (back to
/// the default, which is yours to set).
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

    property string label: ""
    property color color: Theme.accent
    //! Quick picks under the picker: colours, or { name, color } (as ParamSwatches).
    property var presets: []
    //! Shows a reset mark beside the chip.
    property bool resettable: false
    signal picked(color color)
    signal reset()

    readonly property bool open: popup.opened

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.s(26)
    opacity: enabled ? 1 : 0.4

    // the colour being picked, as hue / strength / brightness, so the hue holds while it's grey
    property real h: 0
    property real sv: 0
    property real vv: 1
    function fromColor(c) {
        if (c.hsvHue >= 0) root.h = c.hsvHue
        root.sv = c.hsvSaturation
        root.vv = c.hsvValue
    }
    function choose(c) {
        root.fromColor(c)
        root.picked(c)
    }
    function chooseHsv() { root.picked(Qt.hsva(root.h, root.sv, root.vv, 1)) }
    function hex(c) {
        const t = x => ("0" + Math.round(x * 255).toString(16)).slice(-2)
        return "#" + t(c.r) + t(c.g) + t(c.b)
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.s(8)
        Text {
            visible: root.label.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: Theme.text
            font.family: Theme.family
            font.pixelSize: Theme.labelSize
        }
        // the chip: the colour in a frame; the frame in the accent while picking or hovered
        Rectangle {
            id: chip
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.s(34); height: Theme.s(22)
            radius: Theme.radius
            color: root.color
            border.width: popup.opened || chipArea.containsMouse ? Theme.s(2) : 1
            border.color: popup.opened || chipArea.containsMouse ? Theme.onPanel(root.tint) : Theme.line
            MouseArea {
                id: chipArea
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (popup.opened) popup.close(); else { root.fromColor(root.color); popup.open() } }
            }
        }
        Text {
            visible: root.resettable
            anchors.verticalCenter: parent.verticalCenter
            text: "↺"
            color: resetArea.containsMouse ? Theme.onPanel(root.tint) : Theme.textFaint
            font.family: Theme.family
            font.pixelSize: Theme.titleSize
            MouseArea { id: resetArea; anchors.fill: parent; anchors.margins: -Theme.s(4); hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.reset() }
        }
    }

    // --- the picker -----------------------------------------------------------------
    B.Popup {
        id: popup
        y: row.height + Theme.s(6)
        padding: Theme.s(10)
        closePolicy: B.Popup.CloseOnEscape | B.Popup.CloseOnPressOutsideParent
        background: Rectangle {
            color: Theme.raised
            radius: Theme.radius * 1.5
            border.width: 1; border.color: Theme.line
        }
        contentItem: Column {
            spacing: Theme.s(8)
            readonly property int w: Theme.s(190)

            // how strong (across) and how bright (up), in the hue
            Rectangle {
                id: square
                width: parent.w; height: Theme.s(120)
                radius: Theme.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: Qt.hsva(root.h, 1, 1, 1) }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: "black" }
                    }
                }
                // where it is: a ring, light or dark against the colour under it
                Rectangle {
                    readonly property real size: Theme.s(10)
                    x: Math.round(root.sv * square.width - size / 2)
                    y: Math.round((1 - root.vv) * square.height - size / 2)
                    width: size; height: size; radius: size / 2
                    color: "transparent"
                    border.width: Theme.s(2)
                    border.color: root.vv > 0.6 && root.sv < 0.5 ? "black" : "white"
                }
                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    cursorShape: Qt.CrossCursor
                    function at(m) {
                        root.sv = PM.clamp(m.x / width, 0, 1)
                        root.vv = PM.clamp(1 - m.y / height, 0, 1)
                        root.chooseHsv()
                    }
                    onPressed: m => at(m)
                    onPositionChanged: m => { if (pressed) at(m) }
                }
            }

            // the hue
            Rectangle {
                id: hues
                width: parent.w; height: Theme.s(14)
                radius: Theme.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0 / 6; color: "#ff0000" }
                    GradientStop { position: 1 / 6; color: "#ffff00" }
                    GradientStop { position: 2 / 6; color: "#00ff00" }
                    GradientStop { position: 3 / 6; color: "#00ffff" }
                    GradientStop { position: 4 / 6; color: "#0000ff" }
                    GradientStop { position: 5 / 6; color: "#ff00ff" }
                    GradientStop { position: 6 / 6; color: "#ff0000" }
                }
                Rectangle {
                    x: Math.round(root.h * hues.width - width / 2); y: -Theme.s(2)
                    width: Theme.s(4); height: hues.height + Theme.s(4)
                    color: "white"; border.width: 1; border.color: "black"
                }
                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    cursorShape: Qt.SizeHorCursor
                    function at(m) { root.h = PM.clamp(m.x / width, 0, 0.999); root.chooseHsv() }
                    onPressed: m => at(m)
                    onPositionChanged: m => { if (pressed) at(m) }
                }
            }

            // the code, typed
            ParamField {
                width: parent.w
                mono: true
                text: root.hex(root.color)
                onAccepted: t => {
                    const s = t.trim().replace(/^#?/, "#")
                    if (/^#[0-9a-fA-F]{6}$/.test(s)) root.choose(Qt.tint(s, "transparent"))   // as a colour, not text
                }
            }

            // quick picks
            ParamSwatches {
                visible: root.presets.length > 0
                width: parent.w
                model: root.presets
                current: root.color
                swatchWidth: Math.floor(parent.w / Math.max(1, root.presets.length))
                swatchHeight: Theme.s(18)
                onPicked: c => root.choose(c)
            }
        }
    }
}
