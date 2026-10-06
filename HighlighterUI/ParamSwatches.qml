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
    property int swatchWidth: Theme.s(14)
    property int swatchHeight: Theme.s(26)
    signal picked(color color)

    // One row of them, unless given less width (then they wrap).
    implicitWidth: model.length * swatchWidth
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
        width: Math.max(root.swatchWidth, root.width)
        spacing: 0
        Repeater {
            model: root.model
            Item {
                id: swatch
                required property var modelData
                readonly property color c: root.colorOf(modelData)
                readonly property bool on: Qt.colorEqual(c, root.current)
                width: root.swatchWidth; height: root.swatchHeight
                z: on ? 1 : 0
                Rectangle {
                    anchors.fill: parent
                    color: swatch.c
                }
                // the picked one: an inner outline in the text colour; hover: a fainter one
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: swatch.on ? Theme.s(2) : 1
                    border.color: swatch.on ? Theme.text : Qt.rgba(1, 1, 1, 0.6)
                    visible: swatch.on || area.containsMouse
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
