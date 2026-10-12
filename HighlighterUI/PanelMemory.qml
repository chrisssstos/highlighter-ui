pragma Singleton
import QtQuick
import QtCore

/// What the panel remembers between runs: which sliders the user has
/// maximised (sliders start minimised) and which minimised (an illustrated
/// slider starts maximised). Kept in highlighterui.ini in the
/// app's own config folder, so each app remembers its own panel.
QtObject {
    id: memory

    readonly property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.AppConfigLocation) + "/highlighterui.ini"
        category: "sliders"
        //! The keys of the maximised sliders, as a JSON list.
        property string maximised: "[]"
        //! And of the sliders minimised by hand.
        property string minimised: "[]"
    }

    function parse(text) {
        try { const l = JSON.parse(text); return Array.isArray(l) ? l : [] }
        catch (e) { return [] }
    }
    function list() { return parse(store.maximised) }
    function isMaximised(key) { return key.length > 0 && list().indexOf(key) >= 0 }
    function isMinimised(key) { return key.length > 0 && parse(store.minimised).indexOf(key) >= 0 }
    //! Remembers the user's choice: maximised (on) or minimised.
    function setMaximised(key, on) {
        if (!key.length) return
        const mx = list(), mn = parse(store.minimised)
        const drop = (l, k) => { const i = l.indexOf(k); if (i >= 0) l.splice(i, 1) }
        drop(mx, key); drop(mn, key)
        ;(on ? mx : mn).push(key)
        store.maximised = JSON.stringify(mx)
        store.minimised = JSON.stringify(mn)
        store.sync()
    }
}
