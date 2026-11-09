import QtQuick
import QtQuick.Window

/// Puts the output window over the displays the slices use, as Resolume's
/// outputs go full screen: borderless, covering exactly those displays (one
/// window spanning them: windows can't share a rendered picture, so the
/// content stays rendered once). With no slice on a display, the window
/// goes back to where and how it was.
QtObject {
    id: root

    required property Window window
    required property OutputMap map
    required property DisplayOutputs displays
    //! off: the window is left alone
    property bool enabled: true

    //! the displays enabled slices are on
    readonly property var used: {
        map.revision
        const ids = map.slices.filter(s => s.enabled).map(s => map.outputId(s.output))
        return displays.screens.filter(d => ids.indexOf(d.id) >= 0)
    }
    //! the window, as it was before it went over the displays
    property var _was: null
    //! what it was last placed for (edits that don't change it do nothing)
    property string _placed: ""

    function place() {
        if (!window) return
        const want = enabled ? used : []
        const key = JSON.stringify(want)
        if (key === _placed) return
        _placed = key
        if (want.length) {
            const x0 = Math.min(...want.map(d => d.gx)), y0 = Math.min(...want.map(d => d.gy))
            const x1 = Math.max(...want.map(d => d.gx + d.width)), y1 = Math.max(...want.map(d => d.gy + d.height))
            if (!_was) _was = { x: window.x, y: window.y, width: window.width, height: window.height,
                                flags: window.flags, visibility: window.visibility }
            if (window.visibility === Window.FullScreen || window.visibility === Window.Maximized) window.visibility = Window.Windowed
            window.flags = _was.flags | Qt.FramelessWindowHint
            window.x = x0; window.y = y0
            window.width = x1 - x0; window.height = y1 - y0
            console.info("OutputMapper: output window over", want.map(d => d.name).join(", "), "at", x0, y0, x1 - x0, "x", y1 - y0)
        } else if (_was) {
            window.flags = _was.flags
            window.x = _was.x; window.y = _was.y
            window.width = _was.width; window.height = _was.height
            if (_was.visibility !== Window.Windowed) window.visibility = _was.visibility
            _was = null
            console.info("OutputMapper: output window back to its own place")
        }
    }

    onUsedChanged: Qt.callLater(place)
    onEnabledChanged: Qt.callLater(place)
}
