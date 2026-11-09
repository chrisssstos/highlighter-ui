import QtQuick
import QtQuick.Window
import HighlighterUI
import OutputMapper

/// The mapping editor in a window of its own, as Resolume's Advanced Output.
/// Closing it takes the outlines off the outputs.
Window {
    id: win

    required property OutputMap map
    property Item previewSource: null

    title: "Output mapping"
    width: Theme.s(1280)
    height: Theme.s(780)
    color: Theme.page

    onClosing: map.showOnOutput = false

    Shortcut { sequences: [StandardKey.Undo]; onActivated: win.map.undo() }
    Shortcut { sequences: [StandardKey.Redo, "Ctrl+Y"]; onActivated: win.map.redo() }

    MappingEditor {
        anchors.fill: parent
        map: win.map
        previewSource: win.previewSource
    }
}
