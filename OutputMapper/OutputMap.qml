import QtQuick
import OutputMapper

/// The mapping: which part of the source (the app's content, rendered once)
/// each slice takes, and where and how it lands on an output. Shared by the
/// output (MappedOutput) and the editor (MappingWindow), which may be in
/// different windows.
///
/// The app gives `sourceWidth` / `sourceHeight` (its content's size) and
/// `outputs` (where each display is in the output window: { name, x, y,
/// width, height }), loads what it saved with `load(json)` (or starts from
/// `defaults`), and saves `toJson()` when `saveRequested` comes.
///
/// A slice: { name, output (index), enabled, input: { x, y, width, height }
/// (source pixels), columns, rows, perspective, points: [{ x, y }] (columns
/// x rows, row by row, normalised to the output), mask: [{ x, y }] (the
/// visible area, normalised to the output; fewer than 3 points: no mask) }.
QtObject {
    id: map

    property real sourceWidth: 1920
    property real sourceHeight: 1080
    property var outputs: [{ name: "Output", x: 0, y: 0, width: 1920, height: 1080 }]
    //! slices to start from, and to go back to (Reset all); the app's
    //! one-per-output layout, say
    property var defaults: []

    property var slices: []
    //! rises with every change, for bindings that read into `slices`
    property int revision: 0
    //! changed since loaded or saved
    property bool dirty: false

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
    property string view: "output"

    signal saveRequested()
    signal revertRequested()

    // --- slices ----------------------------------------------------------------
    function slice(name, output, input) {
        return {
            name: name, output: output ?? 0, enabled: true,
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
    }
    function resetAll() { slices = defaults.map(normalised); selected = slices.length ? 0 : -1; selectedPoint = -1; touch() }
    function saved() { dirty = false }

    function normalised(s) {
        const c = Math.max(2, s.columns ?? 2), r = Math.max(2, s.rows ?? 2)
        const pts = Array.isArray(s.points) && s.points.length === c * r ? s.points : Warp.grid(c, r)
        return {
            name: String(s.name ?? "Slice"), output: Math.max(0, Math.min(outputs.length - 1, s.output ?? 0)),
            enabled: s.enabled !== false,
            input: { x: s.input?.x ?? 0, y: s.input?.y ?? 0, width: s.input?.width ?? sourceWidth, height: s.input?.height ?? sourceHeight },
            columns: c, rows: r, perspective: s.perspective !== false,
            points: pts.map(p => ({ x: Number(p.x), y: Number(p.y) })),
            mask: (s.mask ?? []).map(p => ({ x: Number(p.x), y: Number(p.y) }))
        }
    }

    function touch() { slices = slices.slice(); revision++; dirty = true }
    function copyOf(i) { return JSON.parse(JSON.stringify(slices[i])) }
    function put(i, s) { const list = slices.slice(); list[i] = s; slices = list; revision++; dirty = true }

    function set(i, changes) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        for (const k in changes) s[k] = changes[k]
        put(i, s)
    }
    function setInput(i, rect) {
        set(i, { input: {
            x: Math.round(rect.x), y: Math.round(rect.y),
            width: Math.max(1, Math.round(rect.width)), height: Math.max(1, Math.round(rect.height)) } })
    }
    function setPoint(i, k, p) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        if (k < 0 || k >= s.points.length) return
        s.points[k] = { x: p.x, y: p.y }
        put(i, s)
    }
    //! every point of the slice moved by (dx, dy), output-normalised
    function moveAll(i, dx, dy) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.points = s.points.map(p => ({ x: p.x + dx, y: p.y + dy }))
        s.mask = s.mask.map(p => ({ x: p.x + dx, y: p.y + dy }))
        put(i, s)
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
    //! the warp back to the output's full rectangle
    function resetWarp(i) {
        if (i < 0 || i >= slices.length) return
        const s = copyOf(i)
        s.points = Warp.grid(s.columns, s.rows)
        put(i, s)
    }

    function add() {
        const list = slices.slice()
        list.push(slice("Slice " + (list.length + 1), selected >= 0 ? slices[selected].output : 0))
        slices = list; selected = list.length - 1; selectedPoint = -1; revision++; dirty = true
    }
    function duplicate(i) {
        if (i < 0 || i >= slices.length) return
        const list = slices.slice()
        const s = copyOf(i)
        s.name = s.name + " copy"
        list.splice(i + 1, 0, s)
        slices = list; selected = i + 1; selectedPoint = -1; revision++; dirty = true
    }
    function remove(i) {
        if (i < 0 || i >= slices.length) return
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
