import QtQuick

/// The PC's displays that the output window covers, as outputs for an
/// OutputMap: { id, name, x, y, width, height } in `item`'s coordinates
/// (the MappedOutput, or what fills the window), so a slice can be sent to a
/// physical display, as in Resolume. Followed live: a display plugged in or
/// taken out, the window moved.
QtObject {
    id: root

    required property Item item

    property var displays: []

    function refresh() {
        if (!item || !item.Window.window) { if (displays.length) displays = []; return }
        const out = []
        const screens = Qt.application.screens
        for (let i = 0; i < screens.length; i++) {
            const s = screens[i]
            const a = item.mapFromGlobal(s.virtualX, s.virtualY)
            const b = item.mapFromGlobal(s.virtualX + s.width, s.virtualY + s.height)
            const r = { x: Math.round(a.x), y: Math.round(a.y), width: Math.round(b.x - a.x), height: Math.round(b.y - a.y) }
            // only the displays the window is on
            const overlapW = Math.min(r.x + r.width, item.width) - Math.max(r.x, 0)
            const overlapH = Math.min(r.y + r.height, item.height) - Math.max(r.y, 0)
            if (overlapW <= 0 || overlapH <= 0) continue
            const n = (String(s.name).match(/(\d+)\s*$/) || [])[1] ?? String(i + 1)
            const px = Math.round(s.width * s.devicePixelRatio) + "×" + Math.round(s.height * s.devicePixelRatio)
            out.push(Object.assign({ id: "display:" + s.name, name: "Display " + n + " · " + px + (s.model ? " · " + s.model : "") }, r))
        }
        if (JSON.stringify(out) !== JSON.stringify(displays)) displays = out
    }

    // a display or the window can change at any time; checking is cheap
    property Timer _poll: Timer { interval: 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
