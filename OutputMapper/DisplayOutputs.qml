import QtQuick

/// Where an OutputMap's slices can go: every display the PC has (as in
/// Resolume's output menu), then any areas the app adds, each as an output
/// { id, name, x, y, width, height } in `item`'s coordinates (the window's
/// content item, where the MappedOutput is). A display is there whether or
/// not the window covers it yet: OutputWindow moves the window over the
/// displays the slices use. Followed live: a display plugged in or out, the
/// window moved.
QtObject {
    id: root

    //! what the outputs are drawn in: the output window's content item
    required property Item item
    //! the app's own areas ({ id, name, x, y, width, height } in areaItem's
    //! coordinates), offered after the displays
    property Item areaItem: null
    property var areas: []

    //! every display: { id, name, gx, gy, width, height } (global, logical px)
    property var screens: []
    //! every display, then the areas, as outputs
    property var outputs: []

    function refresh() {
        if (!item || !item.Window.window) return
        const sc = [], out = []
        const list = Qt.application.screens
        for (let i = 0; i < list.length; i++) {
            const s = list[i]
            const n = (String(s.name).match(/(\d+)\s*$/) || [])[1] ?? String(i + 1)
            const px = Math.round(s.width * s.devicePixelRatio) + "×" + Math.round(s.height * s.devicePixelRatio)
            const d = { id: "display:" + s.name, name: "Display " + n + " · " + px + (s.model ? " · " + s.model : ""),
                        gx: s.virtualX, gy: s.virtualY, width: s.width, height: s.height }
            sc.push(d)
            const a = item.mapFromGlobal(d.gx, d.gy), b = item.mapFromGlobal(d.gx + d.width, d.gy + d.height)
            out.push({ id: d.id, name: d.name, x: Math.round(a.x), y: Math.round(a.y),
                       width: Math.round(b.x - a.x), height: Math.round(b.y - a.y) })
        }
        if (areaItem) {
            for (const r of areas) {
                const a = areaItem.mapToItem(item, r.x, r.y), b = areaItem.mapToItem(item, r.x + r.width, r.y + r.height)
                out.push({ id: r.id, name: r.name, x: Math.round(a.x), y: Math.round(a.y),
                           width: Math.round(b.x - a.x), height: Math.round(b.y - a.y) })
            }
        }
        if (JSON.stringify(sc) !== JSON.stringify(screens)) screens = sc
        if (JSON.stringify(out) !== JSON.stringify(outputs)) outputs = out
    }

    onAreasChanged: refresh()
    onItemChanged: refresh()

    // displays come and go (checked each second); the window moves and resizes
    property Timer _poll: Timer { interval: 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refresh() }
    property Connections _window: Connections {
        target: root.item ? root.item.Window.window : null
        function onXChanged() { root.refresh() }
        function onYChanged() { root.refresh() }
        function onWidthChanged() { root.refresh() }
        function onHeightChanged() { root.refresh() }
    }
    property Connections _areaItem: Connections {
        target: root.areaItem
        function onWidthChanged() { root.refresh() }
        function onHeightChanged() { root.refresh() }
    }
}
