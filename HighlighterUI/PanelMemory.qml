pragma Singleton
import QtQuick
import QtCore

/// What the panel remembers between runs: which sliders the user has
/// maximised (sliders start minimised). Kept in highlighterui.ini in the
/// app's own config folder, so each app remembers its own panel.
QtObject {
    id: memory

    readonly property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.AppConfigLocation) + "/highlighterui.ini"
        category: "sliders"
        //! The keys of the maximised sliders, as a JSON list.
        property string maximised: "[]"
    }

    function list() {
        try { const l = JSON.parse(store.maximised); return Array.isArray(l) ? l : [] }
        catch (e) { return [] }
    }
    function isMaximised(key) { return key.length > 0 && list().indexOf(key) >= 0 }
    function setMaximised(key, on) {
        if (!key.length) return
        const l = list(), i = l.indexOf(key)
        if (on && i < 0) l.push(key)
        else if (!on && i >= 0) l.splice(i, 1)
        else return
        store.maximised = JSON.stringify(l)
        store.sync()
    }
}
