import QtQuick
import QtQuick.Shapes
import HighlighterUI
import OutputMapper

/// The mapping editor, Resolume's Advanced Output in HighlighterUI's look:
/// the slices down the left, and a view of either the source (Input: which
/// rectangle each slice takes) or one output (Output: where its points put
/// it, and its mask). The views show a still of the content, taken now and
/// (`previewSource`, small, previewMs apart), or the test card; the
/// full picture is on the outputs (Show on output).
///
/// Output view: drag a point, or inside a slice to move it all; Shift is
/// fine, Ctrl stops it snapping to the output's edges. Arrow keys nudge the
/// picked point (or the whole slice) a pixel, ten with Shift; Tab picks the
/// next point. Mask: click to add a point, drag one, right-click to remove.
Item {
    id: ed

    required property OutputMap map
    //! what the views show, grabbed every previewMs: a MappedOutput's
    //! `thumbnail` (null: none)
    property Item previewSource: null
    property int previewMs: 33
    //! its own Save button (off where the app saves another way)
    property bool showSave: true

    readonly property var sel: { map.revision; return map.selected >= 0 && map.selected < map.slices.length ? map.slices[map.selected] : null }
    //! the output the Output view shows, by id (outputs come and go: a
    //! display found after start, one unplugged)
    property string viewedId: sel?.output ?? ""
    onSelChanged: if (sel && sel.output !== "") viewedId = sel.output
    readonly property int viewedOutput: Math.max(0, map.outputIndex(viewedId))
    //! the output a slice is on, as an index here (-1: not connected now)
    function at(s) { map.outputs; return map.outputIndex(s.output) }
    readonly property var outputNames: map.outputs.map(o => o.name)

    Rectangle { anchors.fill: parent; color: Theme.page }

    //! where a handle of the picked slice is, in the window (for test runs):
    //! "inputcorner" 0..3, "point" k, "stretch" 0..3 (left, right, top, bottom)
    function scenePoint(kind, k) {
        const s = sel
        if (!s) return Qt.point(-1, -1)
        if (kind === "inputcorner")
            return srcFrame.mapToItem(null, (s.input.x + (k % 2) * s.input.width) * inputView.k,
                                            (s.input.y + Math.floor(k / 2) * s.input.height) * inputView.k)
        if (kind === "point")
            return outFrame.mapToItem(null, s.points[k].x * outFrame.width, s.points[k].y * outFrame.height)
        const h = pointer.handleAt(["left", "right", "top", "bottom"][k])
        return outFrame.mapToItem(null, h.x, h.y)
    }

    // The slice list, made again only when what it shows changes (a drag
    // changes the slices on every move; their names and displays it doesn't).
    property var tableRows: []
    property string _tableKey: ""
    function refreshTable() {
        const rows = map.slices.map(s => [s.enabled ? s.name : { text: s.name, tone: "dim" },
            s.output === "" ? { text: "none", tone: "dim" } : outputNames[at(s)] ?? { text: "not connected", tone: "bad" }])
        const key = JSON.stringify(rows)
        if (key !== _tableKey) { _tableKey = key; tableRows = rows }
    }
    Connections {
        target: ed.map
        function onRevisionChanged() { ed.refreshTable() }
        function onOutputsChanged() { ed.refreshTable() }
    }
    Component.onCompleted: refreshTable()

    //! v snapped to the nearest of `lines` within `tol` (Ctrl: not at all): { v, line }
    function nearest(v, lines, tol, mods) {
        if (mods & Qt.ControlModifier) return { v: v, line: NaN }
        let best = NaN, d = tol
        for (const e of lines) if (Math.abs(v - e) < d) { d = Math.abs(v - e); best = e }
        return { v: isNaN(best) ? v : best, line: best }
    }
    //! A span (from, length) moved by delta, snapped by whichever of its ends
    //! (or its middle) is nearest a line: { off, line } (off: the snapped delta).
    function snapSpan(from, length, delta, lines, tol, mods) {
        let best = { off: delta, line: NaN, d: Infinity }
        for (const e of [from, from + length / 2, from + length]) {
            const s = nearest(e + delta, lines, tol, mods)
            if (!isNaN(s.line) && Math.abs(s.v - e - delta) < best.d) best = { off: s.v - e, line: s.line, d: Math.abs(s.v - e - delta) }
        }
        return best
    }

    Shortcut { enabled: ed.visible; sequences: [StandardKey.Undo]; onActivated: ed.map.undo() }
    Shortcut { enabled: ed.visible; sequences: [StandardKey.Redo]; onActivated: ed.map.redo() }

    Timer {
        interval: ed.previewMs
        repeat: true
        triggeredOnStart: true
        running: ed.visible && (ed.Window.window?.visible ?? false) && !!ed.previewSource && !ed.map.testCard
        // one grab at a time (a grab that never comes back is given up after a second)
        property real busySince: 0
        onTriggered: {
            if (busySince > 0 && Date.now() - busySince < 1000) return
            busySince = Date.now()
            if (!ed.previewSource.grabToImage(r => { still.source = r.url; busySince = 0 })) busySince = 0
        }
    }

    // the views' picture: the still, or the test card (drawn here, small).
    // The next still loads off the GUI thread; the last stays on show meanwhile.
    Image {
        id: still
        visible: false // only its texture is used
        width: ed.previewSource ? ed.previewSource.width : 1
        height: ed.previewSource ? ed.previewSource.height : 1
        asynchronous: true; cache: false; smooth: true
        retainWhileLoading: true
    }
    Item {
        id: cardHolder
        width: 1; height: 1; clip: true
        TestCard {
            id: card
            visible: ed.map.testCard
            map: ed.map
            width: ed.map.sourceWidth; height: ed.map.sourceHeight
        }
    }
    ShaderEffectSource {
        id: cardTexture
        sourceItem: ed.map.testCard ? card : null
        hideSource: true
        visible: false
        textureSize: Qt.size(Math.round(ed.map.sourceWidth / 4), Math.round(ed.map.sourceHeight / 4))
        textureMirroring: ShaderEffectSource.MirrorVertically
    }
    readonly property Item picture: map.testCard ? cardTexture : still

    // --- the side: slices, the picked slice, the view ---------------------------
    ParamPage {
        id: side
        width: Theme.s(330)
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }

        ParamSection {
            width: parent.width
            title: "Slices"
            ParamTable {
                width: parent.width
                columns: [{ title: "slice" }, { title: "output", width: 0.4 }]
rows: ed.tableRows
                currentRow: ed.map.selected
                visibleRows: 5
                onActivated: r => { ed.map.selected = r; ed.map.selectedPoint = -1 }
            }
            Flow {
                width: parent.width
                spacing: Theme.s(6)
                ParamButton { text: "Add"; onClicked: ed.map.add() }
                ParamButton { text: "Duplicate"; enabled: !!ed.sel; onClicked: ed.map.duplicate(ed.map.selected) }
                ParamButton { text: "Remove"; danger: true; enabled: !!ed.sel; onClicked: ed.map.remove(ed.map.selected) }
            }
        }

        ParamSection {
            width: parent.width
            title: ed.sel ? ed.sel.name : "Slice"
            visible: !!ed.sel
            ParamField {
                width: parent.width
                label: "Name"
                text: ed.sel?.name ?? ""
                onAccepted: t => ed.map.set(ed.map.selected, { name: t.trim() || ed.sel.name })
            }
            ParamCombo {
                width: parent.width
                label: "Output"
                // a display the slice is on but that isn't connected now stays its
                // own last entry, until another is picked
                readonly property bool missing: !!ed.sel && ed.sel.output !== "" && ed.at(ed.sel) < 0
                model: ["None"].concat(ed.outputNames).concat(missing ? ["Not connected"] : [])
                currentIndex: !ed.sel ? 0 : missing ? ed.outputNames.length + 1 : ed.at(ed.sel) + 1
                onActivated: i => {
                    if (i > ed.outputNames.length) return
                    const id = i === 0 ? "" : ed.map.outputs[i - 1].id
                    // a slice put on a display as a plain rectangle starts
                    // fitted, its shape kept (not stretched to the display)
                    const fresh = id !== "" && ed.map.untouched(ed.map.selected)
                    ed.map.beginGroup() // one undo step for both
                    ed.map.set(ed.map.selected, { output: id })
                    if (fresh) ed.map.sizeTo(ed.map.selected, "fit")
                    ed.map.endGroup()
                    if (id !== "") ed.viewedId = id
                }
            }
            ParamToggle {
                width: parent.width
                text: "Shown"
                checked: ed.sel?.enabled ?? true
                onToggled: c => ed.map.set(ed.map.selected, { enabled: c })
            }
            ParamChoice {
                width: parent.width
                label: "Warp"
                model: ["Corners", "3 × 3", "4 × 4", "5 × 5", "6 × 6"]
                currentIndex: ed.sel ? Math.max(0, ed.sel.columns - 2) : 0
                onActivated: i => i === 0 ? ed.map.setGrid(ed.map.selected, 2, 2, true)
                                          : ed.map.setGrid(ed.map.selected, i + 2, i + 2, false)
            }
            ParamHeading { width: parent.width; text: "Size"; note: "on its display" }
            Flow {
                width: parent.width
                spacing: Theme.s(6)
                Repeater {
                    model: [["fit", "Fit"], ["fill", "Fill"], ["stretch", "Stretch"], ["native", "1:1"]]
                    ParamButton {
                        required property var modelData
                        text: modelData[1]
                        enabled: !!ed.sel && ed.at(ed.sel) >= 0
                        onClicked: ed.map.sizeTo(ed.map.selected, modelData[0])
                    }
                }
            }

            // where it lands, in the display's pixels (the bounding box of its points)
            ParamHeading { width: parent.width; text: "Output"; note: "display px"; visible: !!ed.sel && ed.at(ed.sel) >= 0 }
            ParamGrid {
                width: parent.width
                visible: !!ed.sel && ed.at(ed.sel) >= 0
                minColumnWidth: Theme.s(120)
                maxColumns: 2
                readonly property var o: ed.sel ? ed.map.outputOf(ed.sel) : null
                readonly property var b: { ed.map.revision; return ed.sel ? ed.map.bounds(ed.map.selected) : null }
                Repeater {
                    model: [["x", "x", "width"], ["y", "y", "height"], ["width", "width", "width"], ["height", "height", "height"]]
                    ParamField {
                        required property var modelData
                        readonly property var grid: parent
                        label: modelData[0]
                        mono: true
                        text: grid.o && grid.b ? String(Math.round(grid.b[modelData[1]] * grid.o[modelData[2]])) : ""
                        onAccepted: t => {
                            const n = Number(t)
                            if (!grid.o || !grid.b || !isFinite(n)) return
                            const r = Object.assign({}, grid.b)
                            r[modelData[1]] = n / grid.o[modelData[2]]
                            if (r.width <= 0 || r.height <= 0) return
                            ed.map.setBounds(ed.map.selected, r)
                        }
                    }
                }
            }

            ParamHeading { width: parent.width; text: "Input"; note: "source px" }
            ParamGrid {
                width: parent.width
                minColumnWidth: Theme.s(120)
                maxColumns: 2
                Repeater {
                    model: [["x", "x"], ["y", "y"], ["width", "width"], ["height", "height"]]
                    ParamField {
                        required property var modelData
                        label: modelData[0]
                        mono: true
                        text: ed.sel ? String(ed.sel.input[modelData[1]]) : ""
                        onAccepted: t => {
                            const n = Number(t)
                            if (!ed.sel || !isFinite(n)) return
                            const r = Object.assign({}, ed.sel.input)
                            r[modelData[1]] = n
                            ed.map.setInput(ed.map.selected, r)
                        }
                    }
                }
            }

            ParamHeading { width: parent.width; text: "Mask"; note: (ed.sel?.mask.length ?? 0) >= 3 ? ed.sel.mask.length + " points" : "none" }
            ParamToggle {
                width: parent.width
                text: "Edit mask"
                checked: ed.map.maskMode
                onToggled: c => { ed.map.maskMode = c; if (c) ed.map.view = "output" }
            }
            Flow {
                width: parent.width
                spacing: Theme.s(6)
                ParamButton { text: "From outline"; onClicked: ed.map.maskFromOutline(ed.map.selected, 1) }
                ParamButton { text: "Clear"; enabled: (ed.sel?.mask.length ?? 0) > 0; onClicked: ed.map.clearMask(ed.map.selected) }
            }
        }

    }

    // --- the view ---------------------------------------------------------------
    Item {
        id: area
        anchors { top: parent.top; bottom: parent.bottom; left: side.right; right: parent.right; margins: Theme.s(16) }
        // what reaches past the view (an input far off the picture) stays in it
        clip: true

        // the toolbar: which view, what's shown, undo, save
        Row {
            id: toolbar
            width: parent.width
            spacing: Theme.s(16)
            ParamChoice {
                width: Theme.s(220)
                model: ["Input", "Output"]
                currentIndex: ed.map.view === "input" ? 0 : 1
                cellHeight: Theme.s(30)
                onActivated: i => ed.map.view = i === 0 ? "input" : "output"
            }
            ParamToggle {
                anchors.verticalCenter: parent.verticalCenter
                text: "Test card"
                checked: ed.map.testCard
                onToggled: c => ed.map.testCard = c
            }
            ParamToggle {
                anchors.verticalCenter: parent.verticalCenter
                text: "Show on output"
                checked: ed.map.showOnOutput
                onToggled: c => ed.map.showOnOutput = c
            }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: toolbar.verticalCenter
            spacing: Theme.s(6)
            ParamButton { text: "Undo"; enabled: ed.map.canUndo; onClicked: ed.map.undo() }
            ParamButton { text: "Redo"; enabled: ed.map.canRedo; onClicked: ed.map.redo() }
            ParamButton { visible: ed.showSave; text: "Save"; accent: true; enabled: ed.map.dirty; onClicked: ed.map.saveRequested() }
        }

        ParamText {
            id: caption
            anchors.top: toolbar.bottom
            anchors.topMargin: Theme.s(12)
            width: parent.width
            mono: true
            small: true
            text: ed.map.view === "input"
                  ? "Source  " + ed.map.sourceWidth + " × " + ed.map.sourceHeight + (inputView.hoverText ? "   " + inputView.hoverText : "")
                  : (ed.outputNames[ed.viewedOutput] ?? "") + "  " + (ed.map.outputs[ed.viewedOutput]?.width ?? 0) + " × "
                    + (ed.map.outputs[ed.viewedOutput]?.height ?? 0) + (outputView.hoverText ? "   " + outputView.hoverText : "")
        }

        // Input: the source, each slice's rectangle; drag a rectangle or its corners
        Item {
            id: inputView
            visible: ed.map.view === "input"
            anchors { top: caption.bottom; topMargin: Theme.s(8); left: parent.left; right: parent.right; bottom: parent.bottom }
            // room round the picture to drag past its edges
            readonly property real k: Math.min(width * 0.75 / ed.map.sourceWidth, height * 0.75 / ed.map.sourceHeight)
            property string hoverText: ""
            property real guideX: NaN
            property real guideY: NaN

            Item {
                id: srcFrame
                width: ed.map.sourceWidth * inputView.k
                height: ed.map.sourceHeight * inputView.k
                anchors.centerIn: parent
                Rectangle { anchors.fill: parent; color: "black" }
                WarpMesh { anchors.fill: parent; source: ed.picture; points: Warp.grid(2, 2) }
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: Theme.line; border.width: 1 }

                Repeater {
                    model: ed.map.slices.length
                    Rectangle {
                        required property int index
                        readonly property var s: ed.map.sliceAt(index)
                        readonly property bool on: index === ed.map.selected
                        x: s.input.x * inputView.k; y: s.input.y * inputView.k
                        width: s.input.width * inputView.k; height: s.input.height * inputView.k
                        color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : "transparent"
                        border.color: on ? Theme.accent : Theme.textDim
                        border.width: on ? 2 : 1
                        ParamText { x: Theme.s(6); y: Theme.s(4); text: parent.s.name; tone: parent.on ? "normal" : "dim" }
                    }
                }
                // the picked slice's corners
                Repeater {
                    model: ed.sel ? 4 : 0
                    Rectangle {
                        required property int index
                        readonly property real size: Theme.s(12)
                        x: (ed.sel.input.x + (index % 2) * ed.sel.input.width) * inputView.k - size / 2
                        y: (ed.sel.input.y + Math.floor(index / 2) * ed.sel.input.height) * inputView.k - size / 2
                        width: size; height: size
                        color: Theme.accent
                    }
                }

                // the lines a drag snapped to
                Rectangle {
                    visible: inputPointer.pressed && !isNaN(inputView.guideX)
                    x: inputView.guideX * inputView.k; y: 0; width: 1; height: parent.height
                    color: Theme.accent
                }
                Rectangle {
                    visible: inputPointer.pressed && !isNaN(inputView.guideY)
                    x: 0; y: inputView.guideY * inputView.k; width: parent.width; height: 1
                    color: Theme.accent
                }

                MouseArea {
                    id: inputPointer
                    anchors.fill: parent
                    anchors.margins: -pad
                    hoverEnabled: true
                    preventStealing: true
                    property int corner: -1   // 0..3, or 4 for the whole rectangle
                    property point start
                    property var startRect
                    readonly property real pad: Math.max(Theme.s(28), Math.min(srcFrame.x, srcFrame.y))

                    function srcAt(mx, my) { return Qt.point((mx - pad) / inputView.k, (my - pad) / inputView.k) }
                    //! the key lines, worked out when a drag starts (they don't move during it)
                    property var linesX: []
                    property var linesY: []
                    //! the key lines: the source's edges and middle, the app's own
                    //! lines, the other slices' edges
                    function lines(horizontal) {
                        const size = horizontal ? ed.map.sourceWidth : ed.map.sourceHeight
                        const out = [0, size / 2, size].concat(horizontal ? ed.map.snapX : ed.map.snapY)
                        ed.map.slices.forEach((s, i) => {
                            if (i === ed.map.selected) return
                            const a = horizontal ? s.input.x : s.input.y, b = a + (horizontal ? s.input.width : s.input.height)
                            out.push(a, b)
                        })
                        return out
                    }
                    function snap(v, horizontal, mods) {
                        return ed.nearest(v, horizontal ? linesX : linesY, Theme.s(10) / inputView.k, mods)
                    }

                    onPositionChanged: mouse => {
                        const p = srcAt(mouse.x, mouse.y)
                        inputView.hoverText = Math.round(p.x) + ", " + Math.round(p.y)
                        if (!pressed || corner < 0) return
                        const dx = p.x - start.x, dy = p.y - start.y
                        const m = mouse.modifiers
                        const r = Object.assign({}, startRect)
                        if (corner === 4) {
                            // the whole rectangle: whichever of its edges (or middle) is nearest a key line
                            const tol = Theme.s(10) / inputView.k
                            const sx = ed.snapSpan(startRect.x, r.width, dx, linesX, tol, m)
                            const sy = ed.snapSpan(startRect.y, r.height, dy, linesY, tol, m)
                            r.x = startRect.x + sx.off; r.y = startRect.y + sy.off
                            inputView.guideX = sx.line; inputView.guideY = sy.line
                        } else {
                            const right = corner % 2 === 1, bottom = corner >= 2
                            let x0 = startRect.x, y0 = startRect.y, x1 = startRect.x + startRect.width, y1 = startRect.y + startRect.height
                            const sx = snap((right ? x1 : x0) + dx, true, m), sy = snap((bottom ? y1 : y0) + dy, false, m)
                            if (right) x1 = sx.v; else x0 = sx.v
                            if (bottom) y1 = sy.v; else y0 = sy.v
                            inputView.guideX = sx.line; inputView.guideY = sy.line
                            r.x = Math.min(x0, x1); r.y = Math.min(y0, y1); r.width = Math.abs(x1 - x0); r.height = Math.abs(y1 - y0)
                        }
                        ed.map.setInput(ed.map.selected, r)
                    }
                    onExited: inputView.hoverText = ""
                    onPressed: mouse => {
                        const p = srcAt(mouse.x, mouse.y)
                        corner = -1
                        // a corner of the picked slice
                        if (ed.sel) {
                            const r = ed.sel.input
                            for (let i = 0; i < 4; i++) {
                                const cx = r.x + (i % 2) * r.width, cy = r.y + Math.floor(i / 2) * r.height
                                if (Math.hypot((cx - p.x) * inputView.k, (cy - p.y) * inputView.k) < Theme.s(10)) { corner = i; break }
                            }
                        }
                        // else the topmost slice under the mouse
                        if (corner < 0) {
                            for (let i = ed.map.slices.length - 1; i >= 0; i--) {
                                const r = ed.map.slices[i].input
                                if (p.x >= r.x && p.x <= r.x + r.width && p.y >= r.y && p.y <= r.y + r.height) {
                                    ed.map.selected = i; ed.map.selectedPoint = -1; corner = 4; break
                                }
                            }
                        }
                        if (corner >= 0) {
                            start = p; startRect = ed.map.slices[ed.map.selected].input
                            linesX = lines(true); linesY = lines(false)
                        }
                    }
                    onPressedChanged: pressed ? ed.map.beginGroup() : ed.map.endGroup()
                    onReleased: corner = -1
                }
            }
        }

        // Output: one output, its slices warped and masked; drag the points
        Item {
            id: outputView
            visible: ed.map.view === "output"
            focus: visible
            anchors { top: caption.bottom; topMargin: Theme.s(8); left: parent.left; right: parent.right; bottom: parent.bottom }
            readonly property var o: ed.map.outputs[ed.viewedOutput] ?? { width: 1920, height: 1080 }
            // room round the display to stretch and drag past its edges
            readonly property real k: Math.min(width * 0.75 / o.width, height * 0.75 / o.height)
            property string hoverText: ""
            property real guideX: NaN
            property real guideY: NaN

            Item {
                id: outFrame
                width: outputView.o.width * outputView.k
                height: outputView.o.height * outputView.k
                anchors.centerIn: parent
                Rectangle { anchors.fill: parent; color: "black" }

                // past the display's edge: drawn too, faintly (the display shows only what's on it)
                Item {
                    anchors.fill: parent
                    anchors.margins: -pointer.pad
                    clip: true
                    opacity: 0.35
                    Repeater {
                        model: ed.map.slices.length
                        WarpMesh {
                            required property int index
                            readonly property var s: ed.map.sliceAt(index)
                            x: pointer.pad; y: pointer.pad
                            width: outFrame.width; height: outFrame.height
                            visible: s.enabled && ed.at(s) === ed.viewedOutput
                            source: ed.picture
                            subdivisions: 16
                            sourceRect: Qt.rect(s.input.x / ed.map.sourceWidth, s.input.y / ed.map.sourceHeight,
                                                s.input.width / ed.map.sourceWidth, s.input.height / ed.map.sourceHeight)
                            columns: s.columns; rows: s.rows; perspective: s.perspective
                            points: s.points
                        }
                    }
                }
                Rectangle { anchors.fill: parent; color: "black" }
                Item {
                    anchors.fill: parent
                    clip: true
                Repeater {
                    model: ed.map.slices.length
                    Item {
                        id: pv
                        required property int index
                        readonly property var s: ed.map.sliceAt(index)
                        anchors.fill: parent
                        visible: s.enabled && ed.at(s) === ed.viewedOutput
                        WarpMesh {
                            anchors.fill: parent
                            source: ed.picture
                            subdivisions: 16
                            sourceRect: Qt.rect(pv.s.input.x / ed.map.sourceWidth, pv.s.input.y / ed.map.sourceHeight,
                                                pv.s.input.width / ed.map.sourceWidth, pv.s.input.height / ed.map.sourceHeight)
                            columns: pv.s.columns; rows: pv.s.rows; perspective: pv.s.perspective
                            points: pv.s.points
                        }
                        MaskShape { anchors.fill: parent; points: pv.s.mask; opacity: 0.85 }
                    }
                }
                }
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: Theme.line; border.width: 1 }
                Repeater {
                    model: ed.map.slices.length
                    SliceOverlay {
                        required property int index
                        readonly property var s: ed.map.sliceAt(index)
                        anchors.fill: parent
                        visible: ed.at(s) === ed.viewedOutput
                        slice: s
                        selected: index === ed.map.selected
                        selectedPoint: ed.map.selectedPoint
                        maskMode: ed.map.maskMode
                        color: Theme.accent
                        unit: Theme.scale
                    }
                }

                // the lines a drag snapped to
                Rectangle {
                    visible: pointer.pressed && !isNaN(outputView.guideX)
                    x: outputView.guideX * outFrame.width; y: -Theme.s(20); width: 1; height: outFrame.height + Theme.s(40)
                    color: Theme.accent
                }
                Rectangle {
                    visible: pointer.pressed && !isNaN(outputView.guideY)
                    x: -Theme.s(20); y: outputView.guideY * outFrame.height; width: outFrame.width + Theme.s(40); height: 1
                    color: Theme.accent
                }

                // stretch: drag a bar to stretch the slice that way
                Repeater {
                    model: ed.sel && !ed.map.maskMode && ed.at(ed.sel) === ed.viewedOutput ? 4 : 0
                    Rectangle {
                        required property int index
                        readonly property string modelData: ["left", "right", "top", "bottom"][index]
                        readonly property var b: { ed.map.revision; return ed.map.bounds(ed.map.selected) }
                        readonly property bool across: modelData === "left" || modelData === "right"
                        readonly property point at: pointer.handleAt(modelData)
                        width: across ? Theme.s(6) : Theme.s(30)
                        height: across ? Theme.s(30) : Theme.s(6)
                        x: at.x - width / 2
                        y: at.y - height / 2
                        color: pointer.dragging === "stretch" && pointer.stretchSide === modelData ? Theme.accent : Theme.accentDim
                        border.color: Theme.accent
                        border.width: 1
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    anchors.margins: -pad // points and edges can go past the display's
                    hoverEnabled: true
                    preventStealing: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    property string dragging: ""   // "point", "all", "mask", "stretch"
                    property int index: -1
                    property point start
                    property var startPoints
                    property var startBounds
                    property string stretchSide: ""

                    //! a stretch bar's centre, in outFrame's pixels
                    readonly property real reach: Theme.s(16)
                    function handleAt(which) {
                        const b = ed.map.bounds(ed.map.selected), w = outFrame.width, h = outFrame.height
                        if (which === "left") return Qt.point(b.x * w - reach, (b.y + b.height / 2) * h)
                        if (which === "right") return Qt.point((b.x + b.width) * w + reach, (b.y + b.height / 2) * h)
                        if (which === "top") return Qt.point((b.x + b.width / 2) * w, b.y * h - reach)
                        return Qt.point((b.x + b.width / 2) * w, (b.y + b.height) * h + reach)
                    }

                    readonly property real pad: Math.max(Theme.s(40), Math.min(outFrame.x, outFrame.y))
                    function norm(mx, my) { return Qt.point((mx - pad) / outFrame.width, (my - pad) / outFrame.height) }
                    function dist(a, b) { return Math.hypot((a.x - b.x) * outFrame.width, (a.y - b.y) * outFrame.height) }
                    function inside(p, poly) {
                        let c = false
                        for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
                            const a = poly[i], b = poly[j]
                            if ((a.y > p.y) !== (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) c = !c
                        }
                        return c
                    }
                    //! The key lines across (x) or down (y), output-normalised, for the
                    //! drag just begun: the display's edges and middle, and (but for a
                    //! whole slice moved) the points on this display other than those
                    //! being dragged. Worked out once: nothing else moves during a drag.
                    property var linesX: []
                    property var linesY: []
                    function prepareLines() {
                        const xs = [0, 0.5, 1], ys = [0, 0.5, 1]
                        if (dragging !== "all") {
                            ed.map.slices.forEach((s, i) => {
                                if (ed.at(s) !== ed.viewedOutput) return
                                s.points.forEach((q, k) => {
                                    const own = i === ed.map.selected && (dragging === "stretch" || (dragging === "point" && k === index))
                                    if (!own) { xs.push(q.x); ys.push(q.y) }
                                })
                            })
                        }
                        linesX = xs; linesY = ys
                    }
                    function snap(v, horizontal, mods) {
                        const tol = (dragging === "all" ? Theme.s(6) : Theme.s(10)) / (horizontal ? outFrame.width : outFrame.height)
                        return ed.nearest(v, horizontal ? linesX : linesY, tol, mods)
                    }

                    onPressed: mouse => {
                        outputView.forceActiveFocus()
                        const p = norm(mouse.x, mouse.y)
                        stretchSide = ""
                        start = p
                        dragging = ""
                        const s = ed.sel
                        if (ed.map.maskMode && s && ed.at(s) === ed.viewedOutput) {
                            const k = s.mask.findIndex(q => dist(q, p) < Theme.s(10))
                            if (mouse.button === Qt.RightButton) { if (k >= 0) ed.map.removeMaskPoint(ed.map.selected, k); return }
                            if (k >= 0) { dragging = "mask"; index = k; startPoints = s.mask; prepareLines(); return }
                            ed.map.addMaskPoint(ed.map.selected, p)
                            dragging = "mask"; index = s.mask.length; startPoints = ed.sel.mask; prepareLines()
                            return
                        }
                        if (mouse.button === Qt.RightButton) return
                        // a stretch bar of the picked slice
                        if (s && ed.at(s) === ed.viewedOutput) {
                            for (const which of ["left", "right", "top", "bottom"]) {
                                const h = handleAt(which)
                                if (Math.hypot(mouse.x - pad - h.x, mouse.y - pad - h.y) < Theme.s(14)) {
                                    dragging = "stretch"; stretchSide = which
                                    startBounds = ed.map.bounds(ed.map.selected)
                                    prepareLines()
                                    return
                                }
                            }
                        }
                        // a point of the picked slice
                        if (s && ed.at(s) === ed.viewedOutput) {
                            let best = -1, bestD = Theme.s(12)
                            s.points.forEach((q, k) => { const d = dist(q, p); if (d < bestD) { best = k; bestD = d } })
                            if (best >= 0) {
                                ed.map.selectedPoint = best
                                dragging = "point"; index = best; startPoints = s.points
                                prepareLines()
                                return
                            }
                        }
                        // inside a slice on this output: pick it, and move it all
                        for (let i = ed.map.slices.length - 1; i >= 0; i--) {
                            const t = ed.map.slices[i]
                            if (ed.at(t) !== ed.viewedOutput || !t.enabled) continue
                            if (inside(p, Warp.outline(t.points, t.columns, t.rows, t.perspective, 8))) {
                                ed.map.selected = i
                                ed.map.selectedPoint = -1
                                dragging = "all"; startBounds = ed.map.bounds(i)
                                prepareLines()
                                return
                            }
                        }
                        ed.map.selectedPoint = -1
                    }
                    onPositionChanged: mouse => {
                        const p = norm(mouse.x, mouse.y)
                        const o = outputView.o
                        outputView.hoverText = Math.round(p.x * o.width) + ", " + Math.round(p.y * o.height)
                        if (!pressed || dragging === "") return
                        const fine = (mouse.modifiers & Qt.ShiftModifier) ? 0.1 : 1
                        const dx = (p.x - start.x) * fine, dy = (p.y - start.y) * fine
                        const m = mouse.modifiers, i = ed.map.selected
                        outputView.guideX = NaN; outputView.guideY = NaN
                        if (dragging === "point" || dragging === "mask") {
                            const q = startPoints[index]
                            const sx = snap(q.x + dx, true, m), sy = snap(q.y + dy, false, m)
                            outputView.guideX = sx.line; outputView.guideY = sy.line
                            if (dragging === "point") ed.map.setPoint(i, index, Qt.point(sx.v, sy.v))
                            else ed.map.setMaskPoint(i, index, Qt.point(sx.v, sy.v))
                        } else if (dragging === "all") {
                            // whichever edge (or the middle) of the slice is nearest a key line
                            const b = startBounds
                            const sx = ed.snapSpan(b.x, b.width, dx, linesX, Theme.s(6) / outFrame.width, m)
                            const sy = ed.snapSpan(b.y, b.height, dy, linesY, Theme.s(6) / outFrame.height, m)
                            outputView.guideX = sx.line; outputView.guideY = sy.line
                            ed.map.setBounds(i, { x: b.x + sx.off, y: b.y + sy.off, width: b.width, height: b.height })
                        } else if (dragging === "stretch") {
                            // the dragged edge snaps; the opposite one stays, all between scales
                            const b = startBounds, min = 0.01
                            const across = stretchSide === "left" || stretchSide === "right"
                            const far = stretchSide === "right" || stretchSide === "bottom"
                            const lo = across ? b.x : b.y, len = across ? b.width : b.height
                            const s = snap((far ? lo + len : lo) + (across ? dx : dy), across, m)
                            if (across) outputView.guideX = s.line; else outputView.guideY = s.line
                            const from = far ? lo : Math.min(s.v, lo + len - min)
                            const to = far ? Math.max(s.v, lo + min) : lo + len
                            ed.map.setBounds(i, across ? { x: from, y: b.y, width: to - from, height: b.height }
                                                       : { x: b.x, y: from, width: b.width, height: to - from })
                        }
                    }
                    onPressedChanged: pressed ? ed.map.beginGroup() : ed.map.endGroup()
                    onReleased: dragging = ""
                    onExited: outputView.hoverText = ""
                }
            }

            // nudge: a pixel of the output, ten with Shift
            Keys.onPressed: event => {
                const s = ed.sel
                if (!s) return
                const o = outputView.o
                const step = (event.modifiers & Qt.ShiftModifier) ? 10 : 1
                let dx = 0, dy = 0
                if (event.key === Qt.Key_Left) dx = -step
                else if (event.key === Qt.Key_Right) dx = step
                else if (event.key === Qt.Key_Up) dy = -step
                else if (event.key === Qt.Key_Down) dy = step
                else if (event.key === Qt.Key_Tab) {
                    ed.map.selectedPoint = (ed.map.selectedPoint + 1) % s.points.length
                    event.accepted = true; return
                } else if (event.key === Qt.Key_Escape) { ed.map.selectedPoint = -1; event.accepted = true; return }
                else return
                event.accepted = true
                const nx = dx / o.width, ny = dy / o.height
                const k = ed.map.selectedPoint
                if (k >= 0) ed.map.setPoint(ed.map.selected, k, Qt.point(s.points[k].x + nx, s.points[k].y + ny), "nudge")
                else ed.map.moveAll(ed.map.selected, nx, ny, "nudge")
            }
        }
    }
}
