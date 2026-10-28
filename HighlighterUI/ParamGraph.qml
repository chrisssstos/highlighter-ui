import QtQuick
import QtQuick.Shapes
import "ParamMath.js" as PM

/// A read-only graph of one live value over time: fps, load, memory, a level.
/// A raised panel with a grey title bar on top holding the name and the
/// value now in a readout, then the last `keep` readings as a line over a
/// translucent fill on a fine grid, the scale on the left and the time along
/// the bottom. An optional dashed guide marks a budget (`mark`); past `warnAt`
/// the readout turns red. A reading that jumps away from the last few (by
/// `jumpAt` of the scale) colours the line and the readout for a moment: blue
/// if it jumped the good way, red the bad way (`better` says which is which),
/// so a change made elsewhere shows which graphs it moved, and how. Steady,
/// it draws in the accent. Feed it with add(v), once per `interval` seconds;
/// add(NaN) when there is nothing to read (a video's rate with none on show):
/// the line breaks there, and the readout shows `noValueText`. `highlighted`
/// marks it as the one picked elsewhere (its row in a ParamTable of results),
/// in the table's own way: the accent over its title bar, and an accent outline.
/// For a value the user sets, use a slider or knob instead.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string label: ""
    //! The value now (add() sets it too).
    property real value: 0
    property int decimals: 1
    property string unit: ""
    //! What the readout shows instead of value + unit ("1.2 of 24 cores"), if set.
    property string valueText: ""
    //! Picked elsewhere (its row in a table of results): tinted and outlined.
    property bool highlighted: false
    //! What the readout shows while there is no reading (add(NaN)).
    property string noValueText: "-"
    //! The scale; a reading past `to` stays at the top.
    property real from: 0
    property real to: 1
    //! A dashed guide at this value (a budget), or NaN for none.
    property real mark: NaN
    //! Past this the readout turns red, or NaN for never.
    property real warnAt: NaN
    //! How many readings it keeps, and the seconds between them (for the time axis).
    property int keep: 120
    property real interval: 1
    //! The plot's height.
    property real plotHeight: Theme.s(80)
    //! A reading this far (a share of the scale) from the last few's average
    //! flashes the graph (Theme.jump, fading over flashMs); NaN never does.
    property real jumpAt: 0.15
    property int flashMs: 1500
    //! Which way is good: 1 higher (fps), -1 lower (load, time, memory), 0
    //! either (a jump then flashes in Theme.jump).
    property int better: 0
    //! The colour of the last jump: Theme.jump (good) or Theme.jumpBad.
    property color flashColor: Theme.jump

    //! 1 just after a jump, falling to 0.
    property real flash: 0
    NumberAnimation { id: flashFade; target: root; property: "flash"; from: 1; to: 0; duration: root.flashMs; easing.type: Easing.InQuad }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    //! What it draws in now: the accent, or the jump colour for a moment.
    readonly property color ink: mix(root.tint, root.flashColor, root.flash)

    //! The readings, oldest first.
    property var points: []
    function add(v) {
        const before = root.points.slice(-5).filter(x => !isNaN(x))
        if (!isNaN(v) && !isNaN(root.jumpAt) && before.length >= 3 && root.to !== root.from) {
            const mean = before.reduce((a, x) => a + x, 0) / before.length
            if (Math.abs(v - mean) >= root.jumpAt * Math.abs(root.to - root.from)) {
                const up = v > mean
                root.flashColor = root.better === 0 || (up === (root.better > 0)) ? Theme.jump : Theme.jumpBad
                flashFade.restart()
            }
        }
        root.value = v
        const p = root.points.concat([v])
        root.points = p.length > root.keep ? p.slice(p.length - root.keep) : p
    }
    function clear() { root.points = [] }

    function fraction(v) { return root.to === root.from ? 0 : PM.clamp((v - root.from) / (root.to - root.from), 0, 1) }
    function timeText(s) { return s >= 60 ? "-" + PM.format(s / 60, s % 60 ? 1 : 0) + " min" : "-" + Math.round(s) + " s" }
    readonly property bool warning: !isNaN(root.warnAt) && root.value >= root.warnAt
    //! Small (in a grid of several): a smaller readout, only the scale's ends
    //! and the time's ends.
    readonly property bool narrow: width < Theme.s(260)

    implicitWidth: Theme.s(320)
    implicitHeight: bar.height + plot.height + axis.height + Theme.s(22)

    ParamPlate { anchors.fill: parent }

    // --- the title bar: the name and the value now ---------------------------
    Rectangle {
        id: bar
        width: parent.width
        height: head.height + Theme.s(8)
        color: Theme.panelBar
        gradient: Theme.classic ? classicBar : null
        Gradient {
            id: classicBar
            GradientStop { position: 0; color: Qt.lighter(Theme.titleBar, 1.12) }
            GradientStop { position: 0.5; color: Theme.titleBar }
            GradientStop { position: 1; color: Theme.titleBarEnd }
        }
        // picked: the accent over it, as a ParamTable's picked row
        Rectangle { anchors.fill: parent; visible: root.highlighted; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.22) }
        // a dark line under it, against the body
        Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Qt.rgba(0, 0, 0, 0.3) }
    }
    // a thin outline round the whole panel; in the accent while picked
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.highlighted ? Theme.s(2) : 1
        border.color: root.highlighted ? root.tint : Theme.panelEdge
        visible: root.highlighted || !Theme.classic
    }

    Item {
        id: head
        x: Theme.s(10); y: Theme.s(4)
        width: parent.width - x - Theme.s(4)
        height: Math.max(name.implicitHeight, readout.height)
        Text {
            id: name
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - readout.width - Theme.s(8)
            text: root.label
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.family
            font.pixelSize: Theme.titleSize
            style: Theme.titleStyle; styleColor: Theme.titleStyleColor
        }
        Rectangle {
            id: readout
            anchors.right: parent.right
            width: Math.max(Theme.s(root.narrow ? 40 : 72), reading.implicitWidth + Theme.s(12))
            height: reading.implicitHeight + Theme.s(4)
            color: Theme.sunken
            ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.12; dark: 0.45 }
            Text {
                id: reading
                anchors.right: parent.right; anchors.rightMargin: Theme.s(6)
                anchors.verticalCenter: parent.verticalCenter
                text: isNaN(root.value) ? root.noValueText : root.valueText !== "" ? root.valueText : PM.format(root.value, root.decimals) + root.unit
                color: root.warning ? Theme.danger : root.ink
                font.family: Theme.family
                font.pixelSize: Theme.valueSize
                font.features: { "tnum": 1 }
            }
        }
    }

    // --- the scale, left of the plot ---------------------------------------
    Item {
        id: scale
        x: Theme.s(10); y: plot.y
        width: Math.max(top.implicitWidth, root.narrow ? 0 : mid.implicitWidth, bottom.implicitWidth)
        height: plot.height
        Text { id: top; anchors.right: parent.right; y: -implicitHeight / 2; text: PM.format(root.to, root.decimals) + root.unit; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
        Text { id: mid; visible: !root.narrow; anchors.right: parent.right; y: parent.height / 2 - implicitHeight / 2; text: PM.format((root.from + root.to) / 2, root.decimals) + root.unit; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
        Text { id: bottom; anchors.right: parent.right; y: parent.height - implicitHeight / 2; text: PM.format(root.from, root.decimals) + root.unit; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
    }

    // --- the plot ------------------------------------------------------------
    Rectangle {
        id: plot
        x: scale.x + scale.width + Theme.s(6)
        y: bar.height + Theme.s(12)
        width: parent.width - x - Theme.s(10)
        height: root.plotHeight
        color: Theme.sunken
        clip: true
        ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.1; dark: 0.45 }

        // the grid: twelve columns of time, quarters of the scale (the middle a little stronger)
        Repeater {
            model: 11
            Rectangle { required property int index; x: Math.round((index + 1) * plot.width / 12); width: 1; height: plot.height; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.12) }
        }
        Repeater {
            model: 3
            Rectangle { required property int index; y: Math.round((index + 1) * plot.height / 4); width: plot.width; height: 1; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, index === 1 ? 0.25 : 0.12) }
        }

        // the readings: the newest at the right edge, one step apart
        readonly property real step: plot.width / Math.max(1, root.keep - 1)
        function yOf(v) { return plot.height - 1 - root.fraction(v) * (plot.height - 2) }
        // the line in runs, broken where there was no reading (NaN)
        readonly property var runs: {
            const p = root.points, out = []
            const x0 = plot.width - (p.length - 1) * plot.step
            let run = []
            for (let i = 0; i < p.length; i++) {
                if (isNaN(p[i])) { if (run.length) out.push(run); run = []; continue }
                run.push(Qt.point(x0 + i * plot.step, plot.yOf(p[i])))
            }
            if (run.length) out.push(run)
            return out
        }
        // a lone reading between gaps, as a dot
        Repeater {
            model: plot.runs.filter(r => r.length === 1)
            Rectangle {
                required property var modelData
                x: modelData[0].x - width / 2; y: modelData[0].y - height / 2
                width: Theme.s(3); height: width; radius: width / 2
                color: root.ink
            }
        }

        Shape {
            anchors.fill: parent
            visible: plot.runs.some(r => r.length > 1)
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            // the fill under the line
            ShapePath {
                strokeColor: "transparent"
                fillColor: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.22 + 0.12 * root.flash)
                PathMultiline {
                    paths: plot.runs.filter(r => r.length > 1).map(r =>
                        [Qt.point(r[0].x, plot.height)].concat(r).concat([Qt.point(r[r.length - 1].x, plot.height)]))
                }
            }
            // the line
            ShapePath {
                strokeColor: root.ink
                strokeWidth: Theme.s(1.5)
                fillColor: "transparent"
                joinStyle: ShapePath.MiterJoin
                PathMultiline { paths: plot.runs.filter(r => r.length > 1) }
            }
        }
        // the guide, dashed
        Shape {
            anchors.fill: parent
            visible: !isNaN(root.mark)
            preferredRendererType: Shape.GeometryRenderer
            ShapePath {
                strokeColor: Theme.textDim
                strokeWidth: 1
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                startX: 0; startY: Math.round(plot.yOf(root.mark)) + 0.5
                PathLine { x: plot.width; y: Math.round(plot.yOf(root.mark)) + 0.5 }
            }
        }
    }

    // --- the time along the bottom -------------------------------------------
    Item {
        id: axis
        x: plot.x; y: plot.y + plot.height + Theme.s(3)
        width: plot.width
        height: first.implicitHeight
        readonly property real span: root.keep * root.interval
        Text { id: first; text: root.timeText(axis.span); color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
        Text { visible: !root.narrow; anchors.horizontalCenter: parent.horizontalCenter; text: root.timeText(axis.span / 2); color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
        Text { anchors.right: parent.right; text: "now"; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
    }
}
