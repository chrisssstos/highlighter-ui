import QtQuick

/// A row of colour swatches, one picked: a colour setting, or the kit's own
/// accent (model: Theme.accents, current: Theme.accent). Wraps when it runs
/// out of width. The label shows the name of the swatch under the mouse,
/// else the picked one's.
Item {
    id: root

    property string label: ""
    //! [{ name, color }], or plain colours.
    property var model: Theme.accents
    property color current: Theme.accent
    property int size: Theme.s(20)
    signal picked(color color)

    // One row of them, unless given less width (then they wrap).
    implicitWidth: model.length * size + Math.max(0, model.length - 1) * flow.spacing + 2 * flow.padding
    implicitHeight: (title.visible ? title.implicitHeight + Theme.rowGap : 0) + flow.implicitHeight
    opacity: enabled ? 1 : 0.4

    function colorOf(m) { return typeof m === "object" && m.color !== undefined ? m.color : m }
    function nameOf(m) { return typeof m === "object" && m.name !== undefined ? m.name : String(m) }
    property string hoveredName: ""
    readonly property string currentName: {
        for (let i = 0; i < model.length; ++i)
            if (Qt.colorEqual(colorOf(model[i]), current)) return nameOf(model[i])
        return current.toString()
    }

    Text {
        id: title
        visible: root.label.length > 0
        text: root.label + "  " + (root.hoveredName || root.currentName)
        color: Theme.text
        font.family: Theme.family
        font.pixelSize: Theme.labelSize
    }

    Flow {
        id: flow
        y: title.visible ? title.implicitHeight + Theme.rowGap : 0
        width: Math.max(root.size, root.width)
        padding: Theme.s(3)   // room for the ring
        spacing: Theme.s(6)
        Repeater {
            model: root.model
            Item {
                id: swatch
                required property var modelData
                readonly property color c: root.colorOf(modelData)
                readonly property bool on: Qt.colorEqual(c, root.current)
                width: root.size; height: root.size
                // the ring round the picked one
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -Theme.s(3)
                    color: "transparent"
                    border.width: Theme.s(2)
                    border.color: Theme.text
                    visible: swatch.on
                }
                Rectangle {
                    anchors.fill: parent
                    color: swatch.c
                    scale: area.containsMouse && !swatch.on ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.quick } }
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.3)
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: root.hoveredName = containsMouse ? root.nameOf(swatch.modelData) : ""
                    onClicked: { root.current = swatch.c; root.picked(swatch.c) }
                }
            }
        }
    }
}
