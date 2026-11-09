import QtQuick
import OutputMapper

/// The mapping: which part of the source (the app's content, rendered once)
/// each slice takes, and where and how it lands on an output. Shared by the
/// output (MappedOutput) and the editor (MappingWindow), which may be in
/// different windows.
///
/// The app gives `sourceWidth` / `sourceHeight` (its content's size) and
/// `outputs` (where each lands in the output window: { id, name, x, y,
/// width, height }: the PC's displays, from DisplayOutputs, and / or areas
/// of the window), loads what it saved with `load(json)` (or starts from
/// `defaults`), and saves `toJson()` when `saveRequested` comes.
///
/// A slice: { name, output (an output's id, "" for none), enabled, input: { x, y, width, height }
/// (source pixels), columns, rows, perspective, points: [{ x, y }] (columns
/// x rows, row by row, normalised to the output), mask: [{ x, y }] (the
/// visible area, normalised to the output; fewer than 3 points: no mask) }.
QtObject {
    id: map

    property real sourceWidth: 1920
    property real sourceHeight: 1080
    property var outputs: [{ id: "output", name: "Output", x: 0, y: 0, width: 1920, height: 1080 }]
    //! lines of the source an input snaps to besides its edges, middle and the
    //! other slices (source px): where the app's own parts meet, say
    property var snapX: []
    property var snapY: []
    //! slices to start from, and to go back to (Reset all); the app's
    //! one-per-output layout, say
    property var defaults: []

    property var slices: []
    //! rises with every change, for bindings that read into `slices`
    property int revision: 0
    //! changed since loaded or saved
    property bool dirty: false
    //! some shown slice is on an output that is there now: the outputs are
    //! in use (otherwise the app shows its content plain)
    readonly property bool live: { revision; outputs; return slices.some(s => s.enabled && outputIndex(s.output) >= 0) }

    // --- what the editor and the outputs share -------------------------------
    property int selected: slices.length ? 0 : -1
    property int selectedPoint: -1
    //! the outlines, points and names drawn on the outputs themselves
    property bool showOnOutput: false
    //! a test card in place of the content
    property bool testCard: false
    //! editing the selected slice's mask rather than its warp
    property bool maskMode: false
    //! the editor's view: "input" (the source) or "output"
    property string view: "input"

    signal saveRequested()
    signal revertRequested()

    //! a stand-in for a slice that has just gone (a view's delegate may read it
    //! before its Repeater has shrunk)
    readonly property var blank: ({ name: "", output: "", enabled: false, input: { x: 0, y: 0, width: 1, height: 1 },
                                    columns: 2, rows: 2, perspective: true, points: [], mask: [] })

    // --- outputs -------------------------------------------------------------
    //! an output's id: an id kept as it is (its display may come back), an
    //! index (older mappings) turned into that output's id
    function outputId(o) { return typeof o === "number" ? (outputs[o]?.id ?? "") : String(o ?? "") }
    //! where an output is in `outputs`, or -1 (none, or a display not connected now)
    function outputIndex(o) { const id = outputId(o); return id === "" ? -1 : outputs.findIndex(x => x.id === id) }
    //! a slice's output, or null when it isn't there now (the slice isn't drawn)
    function outputOf(s) { const i = s ? outputIndex(s.output) : -1; return i >= 0 ? outputs[i] : null }

    // --- slices ----------------------------------------------------------------
    function slice(name, output, input) {
        return {
            name: name, output: outputId(output ?? ""), enabled: true,
            input: input ?? { x: 0, y: 0, width: sourceWidth, height: sourceHeight },
            columns: 2, rows: 2, perspective: true,
            points: Warp.grid(2, 2), mask: []
        }
    }

    function toJson() { return JSON.stringify({ version: 1, slices: slices }) }

    //! the saved mapping, or the defaults when there is none (or it's unreadable)
    function load(json) {
        let list = null
        if (json && String(json).trim() !== "") {
            try { list = JSON.parse(json).slices } catch (e) { console.warn("OutputMapper: unreadable mapping,", e) }
        }
        slices = (Array.isArray(list) && list.length ? list : defaults).map(normalised)
        selected = slices.length ? Math.min(Math.max(selected, 0), slices.length - 1) : -1
        selectedPoint = -1
        revision++
        dirty = false
        _undo = []; _redo = []
    }
    function resetAll() { record(); slices = defaults.map(normalised); selected = slices.length ? 0 : -1; selectedPoint = -1; touch() }
    function saved() { dirty = false }

    function normalised(s) {
        const c = Math.max(2, s.columns ?? 2), r = Math.max(2, s.rows ?? 2)
        const pts = Array.isArray(s.points) && s.points.length === c * r ? s.points : Warp.grid(c, r)
        return {
            // (a number is from before outputs had ids: a canvas, not a display)
            name: String(s.name ?? "Slice"), output: typeof s.output === "number" ? "" : outputId(s.output),
            enabled: s.enabled !== false,
            input: onSource(s.input ?? {}),
            columns: c, rows: r, perspective: s.perspective !== false,
            points: pts.map(p => ({ x: Number(p.x), y: Number(p.y) })),
            mask: (s.mask ?? []).map(p => ({ x: Number(p.x), y: Number(p.y) }))
        }
    }

    //! an input rectangle in whole pixels; it may reach past the source
    //! (that part shows black)
    function onSource(r) {
        return { x: Math.round(r.x ?? 0), y: Math.round(r.y ?? 0),
                 width: Math.max(1, Math.round(r.width ?? sourceWidth)), height: Math.max(1, Math.round(r.height ?? sourceHeight)) }
    }
    function touch() { slices = slices.slice(); revision++; dirty = true }
    function copyOf(i) { return JSON.parse(JSON.stringify(slices[i])) }
    function put(i, s, kind) { record(kind); const list = slices.slice(); list[i] = s; slices = list; revision++; dirty = true }

    // --- undo --------------------------------------------------------------------
    // Every change records the slices before it. A drag is one step
    // (beginGroup on press, endGroup on release); changes with the same
    // `kind` close together (arrow-key nudges) are one step too.
    property var _undo: []
    property var _redo: []
    property int _group: 0
    property bool _groupRecorded: false
    property string _lastKind: ""
    property real _lastAt: 0
    readonly property bool canUndo: { revision; return _undo.length > 0 }
    readonly property bool canRedo: { revision; return _redo.length > 0 }
    function record(kind) {
        if (_group > 0) { if (_groupRecorded) return; _groupRecorded = true }
        else if (kind && kind === _lastKind && Date.now() - _lastAt < 800) { _lastAt = Date.now(); return }
        _lastKind = kind ?? ""; _lastAt = Date.now()
        _undo.push(JSON.stringify(slices))
        if (_undo.length > 200) _undo.shift()
        _redo = []
    }
    function beginGroup() { if (_group++ === 0) _groupRecorded = false }
    function endGroup() { _group = Math.max(0, _group - 1) }
    function _restore(from, to) {
        if (!from.length) return
        to.push(JSON.stringify(slices))
        slices = JSON.parse(from.pop())
        selected = Math.min(selected, slices.length - 1); selectedPoint = -1
        _lastKind = ""
        revision++; dirty = true
    }
    // not in the middle of a drag (its step is still open)
    function undo() { if (_group === 0) _restore(_undo, _redo) }
    function redo() { if (_group === 0) _restore(_redo, _undo) }

    function set(i, changes) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        for (const k in changes) s[k] = changes[k]
        put(i, s)
    }
    //! the slice's input
    function setInput(i, rect) { set(i, { input: onSource(rect) }) }
    function setPoint(i, k, p, kind) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        if (k < 0 || k >= s.points.length) return
        s.points[k] = { x: p.x, y: p.y }
        put(i, s, kind)
    }
    //! every point of the slice moved by (dx, dy), output-normalised
    function moveAll(i, dx, dy, kind) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.points = s.points.map(p => ({ x: p.x + dx, y: p.y + dy }))
        s.mask = s.mask.map(p => ({ x: p.x + dx, y: p.y + dy }))
        put(i, s, kind)
    }
    //! the slice's points (and mask) as given: a stretch worked out from where
    //! a drag started
    function setShape(i, points, mask) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.points = points.map(p => ({ x: p.x, y: p.y }))
        if (mask) s.mask = mask.map(p => ({ x: p.x, y: p.y }))
        put(i, s)
    }
    //! The slice's points (and mask) moved and scaled so their bounding box is
    //! `rect` (output-normalised): a warp keeps its shape.
    function setBounds(i, rect) {
        if (i < 0 || i >= slices.length) return
        const b = bounds(i), s = copyOf(i)
        const sx = rect.width / Math.max(1e-6, b.width), sy = rect.height / Math.max(1e-6, b.height)
        const f = q => ({ x: rect.x + (q.x - b.x) * sx, y: rect.y + (q.y - b.y) * sy })
        s.points = s.points.map(f)
        s.mask = s.mask.map(f)
        put(i, s)
    }
    //! the bounding box of the slice's points (output-normalised)
    function bounds(i) {
        const pts = slices[i]?.points ?? []
        if (!pts.length) return { x: 0, y: 0, width: 1, height: 1 }
        const xs = pts.map(p => p.x), ys = pts.map(p => p.y)
        const x0 = Math.min(...xs), y0 = Math.min(...ys)
        return { x: x0, y: y0, width: Math.max(...xs) - x0, height: Math.max(...ys) - y0 }
    }
    //! a new grid of points for the same warp (Corners keeps its perspective)
    function setGrid(i, columns, rows, perspective) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.points = Warp.resample(s.points, s.columns, s.rows, s.perspective, columns, rows)
        s.columns = columns; s.rows = rows; s.perspective = perspective
        put(i, s)
        selectedPoint = -1
    }
    //! The slice's size on its output, its shape kept or not:
    //!  "fit"     the whole input, its shape kept, as big as fits (bars round it)
    //!  "fill"    the whole output, its shape kept (the input cropped to fit)
    //!  "stretch" the whole output, the input stretched to it
    //!  "native"  one source pixel to an output pixel, centred
    function sizeTo(i, mode) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i), o = outputOf(s)
        if (!o || o.width <= 0 || o.height <= 0) return
        const aIn = s.input.width / s.input.height, aOut = o.width / o.height
        let w = 1, h = 1
        if (mode === "fit") { if (aIn > aOut) h = aOut / aIn; else w = aIn / aOut }
        if (mode === "native") { w = s.input.width / o.width; h = s.input.height / o.height }
        if (mode === "fill") {
            // the input cropped round its middle to the output's shape
            const cx = s.input.x + s.input.width / 2, cy = s.input.y + s.input.height / 2
            let iw = s.input.width, ih = s.input.height
            if (aIn > aOut) iw = ih * aOut; else ih = iw / aOut
            s.input = { x: Math.round(cx - iw / 2), y: Math.round(cy - ih / 2), width: Math.round(iw), height: Math.round(ih) }
        }
        const x0 = (1 - w) / 2, y0 = (1 - h) / 2
        s.points = Warp.grid(s.columns, s.rows).map(p => ({ x: x0 + p.x * w, y: y0 + p.y * h }))
        put(i, s)
    }
    //! the slice's points are still the plain full rectangle (never warped)
    function untouched(i) {
        const s = slices[i]
        return !!s && JSON.stringify(s.points.map(p => [Math.round(p.x * 1e4), Math.round(p.y * 1e4)]))
            === JSON.stringify(Warp.grid(s.columns, s.rows).map(p => [Math.round(p.x * 1e4), Math.round(p.y * 1e4)]))
    }

    //! the warp back to the output's full rectangle
    function resetWarp(i) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.points = Warp.grid(s.columns, s.rows)
        put(i, s)
    }

    function add() {
        const list = slices.slice()
        record()
        list.push(slice("Slice " + (list.length + 1), selected >= 0 ? slices[selected].output : ""))
        slices = list; selected = list.length - 1; selectedPoint = -1; revision++; dirty = true
    }
    function duplicate(i) {
        if (i < 0 || i >= slices.length) return
        record()
        const list = slices.slice()
        const s = copyOf(i)
        s.name = s.name + " copy"
        list.splice(i + 1, 0, s)
        slices = list; selected = i + 1; selectedPoint = -1; revision++; dirty = true
    }
    function remove(i) {
        if (i < 0 || i >= slices.length) return
        record()
        const list = slices.slice()
        list.splice(i, 1)
        slices = list
        selected = Math.min(selected, list.length - 1); selectedPoint = -1; revision++; dirty = true
    }

    // --- the mask: the visible area, a polygon ---------------------------------
    function addMaskPoint(i, p) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.mask.push({ x: p.x, y: p.y })
        put(i, s)
    }
    function setMaskPoint(i, k, p) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        if (k < 0 || k >= s.mask.length) return
        s.mask[k] = { x: p.x, y: p.y }
        put(i, s)
    }
    function removeMaskPoint(i, k) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.mask.splice(k, 1)
        put(i, s)
    }
    function clearMask(i) { set(i, { mask: [] }) }
    //! the mask as the slice's current outline (a start to adjust)
    function maskFromOutline(i, steps) {
        if (i < 0 || i >= slices.length) return
        const s = slices[i]
        set(i, { mask: Warp.outline(s.points, s.columns, s.rows, s.perspective, steps ?? 1) })
    }
}
