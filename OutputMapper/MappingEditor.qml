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
    property int previewMs: 66

    readonly property var sel: { map.revision; return map.selected >= 0 && map.selected < map.slices.length ? map.slices[map.selected] : null }
    //! the output the Output view shows, by id (outputs come and go: a
    //! display found after start, one unplugged)
    property string viewedId: sel?.output ?? ""
    onSelChanged: if (sel && ed.map.view === "output") viewedId = sel.output
    readonly property int viewedOutput: Math.max(0, map.outputIndex(viewedId))
    //! the output a slice is on, as an index here (-1: not connected now)
    function at(s) { map.outputs; return map.outputIndex(s.output) }
    readonly property var outputNames: map.outputs.map(o => o.name)
    property url snapshot: ""

    Rectangle { anchors.fill: parent; color: Theme.page }

    Timer {
        interval: ed.previewMs
        repeat: true
        triggeredOnStart: true
        running: ed.visible && !!ed.previewSource && !ed.map.testCard
        // one grab at a time
        property bool busy: false
        onTriggered: {
            if (busy) return
            busy = true
            if (!ed.previewSource.grabToImage(r => { ed.snapshot = r.url; busy = false })) busy = false
        }
    }

    // the views' picture: the still, or the test card (drawn here, small)
    // (through a layer: an Image's own texture is replaced, and freed, with
    // each new still; a layer's stays the same one)
    Image {
        id: still
        x: -width - 16 // beside the window, never seen
        width: ed.previewSource ? ed.previewSource.width : 1
        height: ed.previewSource ? ed.previewSource.height : 1
        source: ed.snapshot
        smooth: true
        cache: false
    }
    ShaderEffectSource {
        id: stillTexture
        sourceItem: still
        hideSource: true
        visible: false
        textureSize: Qt.size(still.width, still.height)
        textureMirroring: ShaderEffectSource.MirrorVertically
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
    readonly property Item picture: map.testCard ? cardTexture : stillTexture

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
                rows: { ed.map.revision; return ed.map.slices.map(s => [s.enabled ? s.name : { text: s.name, tone: "dim" }, ed.outputNames[ed.at(s)] ?? { text: "not connected", tone: "bad" }]) }
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
                model: ed.outputNames
                currentIndex: ed.sel ? ed.at(ed.sel) : -1
                onActivated: i => { ed.map.set(ed.map.selected, { output: ed.map.outputs[i].id }); ed.viewedId = ed.map.outputs[i].id }
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
            ParamCheck {
                width: parent.width
                visible: ed.sel?.columns === 2 && ed.sel?.rows === 2
                text: "Perspective"
                checked: ed.sel?.perspective ?? true
                onToggled: c => ed.map.setGrid(ed.map.selected, 2, 2, c)
            }
            ParamButton { text: "Reset warp"; onClicked: ed.map.resetWarp(ed.map.selected) }

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
            ParamButton {
                text: "Whole source"
                onClicked: ed.map.setInput(ed.map.selected, { x: 0, y: 0, width: ed.map.sourceWidth, height: ed.map.sourceHeight })
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

        ParamSection {
            width: parent.width
            title: "View"
            ParamChoice {
                width: parent.width
                model: ["Input", "Output"]
                currentIndex: ed.map.view === "input" ? 0 : 1
                onActivated: i => ed.map.view = i === 0 ? "input" : "output"
            }
            ParamCombo {
                width: parent.width
                visible: ed.map.view === "output" && ed.outputNames.length > 1
                label: "Showing"
                model: ed.outputNames
                currentIndex: ed.viewedOutput
                onActivated: i => ed.viewedId = ed.map.outputs[i].id
            }
            ParamToggle {
                width: parent.width
                text: "Test card"
                checked: ed.map.testCard
                onToggled: c => ed.map.testCard = c
            }
            ParamToggle {
                width: parent.width
                text: "Show on output"
                checked: ed.map.showOnOutput
                onToggled: c => ed.map.showOnOutput = c
            }
        }

        Flow {
            width: parent.width
            spacing: Theme.s(6)
            ParamButton { text: "Save"; accent: true; enabled: ed.map.dirty; onClicked: ed.map.saveRequested() }
            ParamButton { text: "Revert"; enabled: ed.map.dirty; onClicked: ed.map.revertRequested() }
            ParamButton { text: "Reset all"; danger: true; onClicked: ed.map.resetAll() }
        }
        ParamText { width: parent.width; small: true; text: ed.map.dirty ? "Not saved" : "Saved" }
    }

    // --- the view ---------------------------------------------------------------
    Item {
        id: area
        anchors { top: parent.top; bottom: parent.bottom; left: side.right; right: parent.right; margins: Theme.s(16) }

        ParamText {
            id: caption
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
            readonly property real k: Math.min(width / ed.map.sourceWidth, height / ed.map.sourceHeight)
            property string hoverText: ""

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
                        readonly property var s: { ed.map.revision; return ed.map.slices[index] }
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

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Theme.s(10)
                    hoverEnabled: true
                    preventStealing: true
                    property int corner: -1   // 0..3, or 4 for the whole rectangle
                    property point start
                    property var startRect

                    function srcAt(mx, my) { return Qt.point((mx - Theme.s(10)) / inputView.k, (my - Theme.s(10)) / inputView.k) }
                    function snap(v, edges) {
                        for (const e of edges) if (Math.abs(v - e) * inputView.k < Theme.s(8)) return e
                        return v
                    }

                    onPositionChanged: mouse => {
                        const p = srcAt(mouse.x, mouse.y)
                        inputView.hoverText = Math.round(p.x) + ", " + Math.round(p.y)
                        if (!pressed || corner < 0) return
                        const dx = p.x - start.x, dy = p.y - start.y
                        const r = Object.assign({}, startRect)
                        const xs = [0, ed.map.sourceWidth], ys = [0, ed.map.sourceHeight]
                        if (corner === 4) {
                            r.x = snap(startRect.x + dx, xs); r.y = snap(startRect.y + dy, ys)
                            r.x = snap(r.x + r.width, xs) - r.width; r.y = snap(r.y + r.height, ys) - r.height
                        } else {
                            const right = corner % 2 === 1, bottom = corner >= 2
                            let x0 = startRect.x, y0 = startRect.y, x1 = startRect.x + startRect.width, y1 = startRect.y + startRect.height
                            if (right) x1 = snap(x1 + dx, xs); else x0 = snap(x0 + dx, xs)
                            if (bottom) y1 = snap(y1 + dy, ys); else y0 = snap(y0 + dy, ys)
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
                        if (corner >= 0) { start = p; startRect = Object.assign({}, ed.map.slices[ed.map.selected].input) }
                    }
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
            readonly property real k: Math.min(width / o.width, height / o.height)
            property string hoverText: ""

            Item {
                id: outFrame
                width: outputView.o.width * outputView.k
                height: outputView.o.height * outputView.k
                anchors.centerIn: parent
                Rectangle { anchors.fill: parent; color: "black" }

                Item {
                    anchors.fill: parent
                    clip: true
                Repeater {
                    model: ed.map.slices.length
                    Item {
                        id: pv
                        required property int index
                        readonly property var s: { ed.map.revision; return ed.map.slices[index] }
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
                        readonly property var s: { ed.map.revision; return ed.map.slices[index] }
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

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    anchors.margins: -Theme.s(40) // points can sit past the output's edge
                    hoverEnabled: true
                    preventStealing: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    property string dragging: ""   // "point", "all", "mask"
                    property int index: -1
                    property point start
                    property var startPoints

                    readonly property real pad: Theme.s(40)
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
                    function snapEdge(v, size, mods) {
                        if (mods & Qt.ControlModifier) return v
                        for (const e of [0, 1]) if (Math.abs(v - e) * size < Theme.s(8)) return e
                        return v
                    }

                    onPressed: mouse => {
                        outputView.forceActiveFocus()
                        const p = norm(mouse.x, mouse.y)
                        start = p
                        dragging = ""
                        const s = ed.sel
                        if (ed.map.maskMode && s && ed.at(s) === ed.viewedOutput) {
                            const k = s.mask.findIndex(q => dist(q, p) < Theme.s(10))
                            if (mouse.button === Qt.RightButton) { if (k >= 0) ed.map.removeMaskPoint(ed.map.selected, k); return }
                            if (k >= 0) { dragging = "mask"; index = k; startPoints = s.mask.map(q => ({ x: q.x, y: q.y })); return }
                            ed.map.addMaskPoint(ed.map.selected, p)
                            dragging = "mask"; index = s.mask.length; startPoints = ed.sel.mask.map(q => ({ x: q.x, y: q.y }))
                            return
                        }
                        if (mouse.button === Qt.RightButton) return
                        // a point of the picked slice
                        if (s && ed.at(s) === ed.viewedOutput) {
                            let best = -1, bestD = Theme.s(12)
                            s.points.forEach((q, k) => { const d = dist(q, p); if (d < bestD) { best = k; bestD = d } })
                            if (best >= 0) {
                                ed.map.selectedPoint = best
                                dragging = "point"; index = best; startPoints = s.points.map(q => ({ x: q.x, y: q.y }))
                                return
                            }
                        }
                        // inside a slice on this output: pick it, and move it all
                        for (let i = ed.map.slices.length - 1; i >= 0; i--) {
                            const t = ed.map.slices[i]
                            if (ed.at(t) !== ed.viewedOutput || !t.enabled) continue
                            if (inside(p, Warp.outline(t.points, t.columns, t.rows, t.perspective, 8))) {
                                if (ed.map.selected !== i) { ed.map.selected = i }
                                ed.map.selectedPoint = -1
                                dragging = "all"; startPoints = t.points.map(q => ({ x: q.x, y: q.y }))
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
                        if (dragging === "point" || dragging === "mask") {
                            const q = startPoints[index]
                            const np = Qt.point(snapEdge(q.x + dx, outFrame.width, mouse.modifiers), snapEdge(q.y + dy, outFrame.height, mouse.modifiers))
                            if (dragging === "point") ed.map.setPoint(ed.map.selected, index, np)
                            else ed.map.setMaskPoint(ed.map.selected, index, np)
                        } else if (dragging === "all") {
                            const cur = ed.sel.points[0], want = startPoints[0]
                            ed.map.moveAll(ed.map.selected, want.x + dx - cur.x, want.y + dy - cur.y)
                        }
                    }
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
                if (k >= 0) ed.map.setPoint(ed.map.selected, k, Qt.point(s.points[k].x + nx, s.points[k].y + ny))
                else ed.map.moveAll(ed.map.selected, nx, ny)
            }
        }
    }
}
