import QtQuick

/// A titled group of controls that folds open and shut. Flat: a title above
/// a body held in a lime bracket. Industrial: a synth module, its own
/// faceplate bolted to a pair of rack rails, its name printed across the
/// top, a power LED lit while it is open, and folded down to a slim blank
/// panel. For "one open at a time", bind open to your own state and set it
/// in onToggled. Give its children width: parent.width.
Item {
    id: root
    objectName: "paramGroup"

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string title: ""
    property string note: ""
    property bool open: true
    property bool collapsible: true
    default property alias content: body.data
    property alias spacing: body.spacing

    signal toggled(bool open)

    //! Folds it open or shut, as a click on its title does. Tells you first;
    //! it only folds itself if you didn't, so open bound to your own state
    //! stays bound (one open at a time).
    function flip() {
        const want = !root.open
        root.toggled(want)
        if (root.open !== want) root.open = want
    }

    readonly property bool module: Theme.industrial
    //! Inside another group: a recessed sub-panel, not a module on rails of its own.
    property bool nested: false
    Component.onCompleted: {
        for (let p = parent; p; p = p.parent)
            if (p.objectName === "paramGroup") { nested = true; break }
    }
    //! How far the rails reach past the module, into the page's margin.
    property int railReach: Theme.s(16)

    implicitWidth: Theme.s(300)
    implicitHeight: header.height + frame.height

    // --- industrial: rails behind the top and bottom edges, the faceplate ---
    Repeater {
        model: root.module && !root.nested ? 2 : 0
        ParamRail {
            required property int index
            x: -root.railReach
            width: root.width + 2 * root.railReach
            // a slim (folded) module hangs on one rail, through its middle
            readonly property bool slim: root.height <= Theme.s(56)
            y: slim ? Math.round((root.height - height) / 2)
                    : index === 0 ? Theme.s(3) : root.height - height - Theme.s(3)
            visible: index === 0 || !slim
        }
    }
    ParamPlate {
        visible: root.module
        width: root.width
        height: root.height
        color: root.nested ? Qt.darker(Theme.raised, 1.18) : Theme.raised
        screws: !root.nested
        castShadow: !root.nested
    }
    ParamBevel { anchors.fill: parent; visible: root.module && root.nested; inset: true; dark: 0.5; light: 0.1 }

    Item {
        id: header
        width: parent.width
        height: root.module ? Theme.s(36) : Theme.s(30)

        // flat: chevron and title at the left
        ParamArrow {
            id: chevron
            visible: root.collapsible
            x: root.module ? Theme.s(22) : Theme.s(2)
            anchors.verticalCenter: parent.verticalCenter
            direction: Qt.RightArrow
            width: Theme.s(7); height: Theme.s(9)
            color: headArea.containsMouse ? root.tint : Theme.textDim
            rotation: root.open ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }
        }
        Row {
            id: titleRow
            // industrial: printed across the top, centred; flat: after the chevron
            x: root.module ? Math.round((parent.width - width) / 2) : (root.collapsible ? Theme.s(16) : 0)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.s(8)
            Text {
                id: titleText
                text: root.title.toUpperCase()
                color: root.open || headArea.containsMouse ? Theme.text : Theme.textDim
                font.family: Theme.family
                font.pixelSize: Theme.labelSize
                font.weight: Font.Bold
                font.letterSpacing: root.module ? Theme.s(2) : Theme.s(0.5)
                style: Theme.titleStyle; styleColor: Theme.titleStyleColor
            }
            Text {
                visible: root.note.length > 0
                width: Math.min(implicitWidth, Math.max(0, header.width - titleText.width - Theme.s(80)))
                anchors.baseline: titleText.baseline
                text: root.note
                elide: Text.ElideRight
                color: Theme.textFaint
                font.family: Theme.family
                font.pixelSize: Theme.smallSize
            }
        }
        // industrial: a power LED, lit while it is open
        Item {
            visible: root.module && root.collapsible
            x: parent.width - Theme.s(32); anchors.verticalCenter: parent.verticalCenter
            width: Theme.s(7); height: width
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + Theme.s(6); height: width
                color: root.tint; opacity: root.open ? 0.25 : 0
            }
            Rectangle {
                anchors.fill: parent
                color: root.open ? root.tint : Qt.rgba(0, 0, 0, 0.5)
                border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.6)
                Rectangle { x: 1; y: 1; width: Theme.s(2); height: width; color: Qt.rgba(1, 1, 1, root.open ? 0.6 : 0.15) }
            }
        }
        // the printed rule under the name
        Rectangle {
            visible: root.module && root.open
            x: Theme.s(22); width: parent.width - 2 * Theme.s(22)
            y: parent.height - 1; height: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }
        MouseArea {
            id: headArea
            anchors.fill: parent
            enabled: root.collapsible
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.flip()
        }
    }

    Item {
        id: frame
        y: header.height
        width: parent.width
        readonly property int pad: Theme.s(12)
        // industrial: room at the foot for the screws and the maker's mark
        readonly property int foot: root.module && !root.nested ? Theme.s(20) : 0
        height: root.open ? body.implicitHeight + 2 * pad + foot : 0
        clip: true
        Behavior on height { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }

        // flat: the raised body and, on a group that folds, the bracket
        Rectangle { anchors.fill: parent; visible: !root.module; color: Theme.raised }
        Item {
            anchors.fill: parent
            visible: root.collapsible && !root.module
            Rectangle { width: Theme.s(4); height: parent.height; color: root.tint }
            Rectangle { width: Theme.s(10); height: Theme.s(3); color: root.tint }
            Rectangle { y: parent.height - height; width: Theme.s(10); height: Theme.s(3); color: root.tint }
        }

        Column {
            id: body
            // flat: past the bracket, or the same margin both sides; industrial: in from the plate's edges
            x: root.module ? Theme.s(18) : root.collapsible ? Theme.groupInset : Theme.sectionInset
            y: frame.pad
            width: parent.width - x - (root.module ? Theme.s(18) : Theme.groupInsetEnd)
            spacing: Theme.controlGap
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ease } }
        }

        // the maker's mark, printed small at the foot
        Text {
            visible: root.module && !root.nested
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - frame.foot + Math.round((frame.foot - height) / 2) - Theme.s(2)
            text: "HIGHLIGHTER"
            color: Qt.rgba(1, 1, 1, 0.22)
            font.family: Theme.family
            font.pixelSize: Theme.s(8)
            font.weight: Font.Bold
            font.letterSpacing: Theme.s(3)
        }
    }
}
