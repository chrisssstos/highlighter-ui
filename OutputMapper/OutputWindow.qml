import QtQuick
import QtQuick.Window

/// Puts the output window over the displays the slices use, as Resolume's
/// outputs go full screen: borderless, covering exactly those displays (one
/// window spanning them: windows can't share a rendered picture, so the
/// content stays rendered once). With no slice on a display, the window
/// goes back to where and how it was, or, with parkWhenUnused, out of sight
/// beside the screens (as Resolume shows no output then; the window still
/// renders, for the editor's preview).
QtObject {
    id: root

    required property Window window
    required property OutputMap map
    required property DisplayOutputs displays
    //! off: the window is left alone
    property bool enabled: true
    //! with no slice on a display, out of sight rather than back in place
    property bool parkWhenUnused: false
    //! false until the app has had its say (it may put slices on displays
    //! first): nothing is parked before
    property bool ready: true
    //! the window has been put where it belongs once (the app may keep it
    //! hidden till then: shown first, it flashes in its old place)
    property bool placed: false

    //! the displays enabled slices are on
    readonly property var used: {
        const ids = map.slices.filter(s => s.enabled).map(s => map.outputId(s.output))
        return displays.screens.filter(d => ids.indexOf(d.id) >= 0)
    }
    //! the window's own place and look, kept the first time it is taken over;
    //! windowed and borderless from then
    function takeOver() {
        if (!_was) _was = { x: window.x, y: window.y, width: window.width, height: window.height,
                            flags: window.flags, visibility: window.visibility }
        if (window.visibility === Window.FullScreen || window.visibility === Window.Maximized) window.visibility = Window.Windowed
        window.flags = _was.flags | Qt.FramelessWindowHint
    }
    //! the window, as it was before it went over the displays
    property var _was: null
    //! what it was last placed for (edits that don't change it do nothing)
    property string _placed: ""

    function place() {
        if (!window) return
        const want = enabled ? used : []
        const park = enabled && !want.length && parkWhenUnused && ready
        const key = JSON.stringify(want) + park
        if (key === _placed) { if (ready) placed = true; return }
        _placed = key
        if (want.length) {
            const x0 = Math.min(...want.map(d => d.gx)), y0 = Math.min(...want.map(d => d.gy))
            const x1 = Math.max(...want.map(d => d.gx + d.width)), y1 = Math.max(...want.map(d => d.gy + d.height))
            takeOver()
            window.x = x0; window.y = y0
            window.width = x1 - x0; window.height = y1 - y0
            console.info("OutputMapper: output window over", want.map(d => d.name).join(", "), "at", x0, y0, x1 - x0, "x", y1 - y0)
        } else if (park) {
            takeOver()
            const s = displays.screens
            window.width = 64; window.height = 64
            window.x = (s.length ? Math.min(...s.map(d => d.gx)) : 0) - 2000
            window.y = (s.length ? Math.min(...s.map(d => d.gy)) : 0) - 2000
            console.info("OutputMapper: no slice on a display: the output window out of sight")
        } else if (_was) {
            window.flags = _was.flags
            window.x = _was.x; window.y = _was.y
            window.width = _was.width; window.height = _was.height
            if (_was.visibility !== Window.Windowed) window.visibility = _was.visibility
            _was = null
            console.info("OutputMapper: output window back to its own place")
        }
        if (ready) placed = true
    }

    onUsedChanged: Qt.callLater(place)
    onEnabledChanged: Qt.callLater(place)
    onParkWhenUnusedChanged: Qt.callLater(place)
    onReadyChanged: Qt.callLater(place)
}
