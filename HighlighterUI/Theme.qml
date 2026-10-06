pragma Singleton
import QtQuick

/// Colours, sizes and the font every HighlighterUI control draws with. Change
/// scale to grow or shrink the whole panel (a window on a high DPI screen,
/// say), compact for smaller sliders and knobs that fit more on screen, and
/// accent to recolour it: the darker shades follow the accent. A window
/// that declares its own `property color accent` draws in that colour
/// instead, so two panels can tell themselves apart.
QtObject {
    id: theme

    //! Every size in the kit is multiplied by this.
    property real scale: 1
    function s(px) { return Math.round(px * theme.scale) }
    //! Smaller knobs and spacing, to fit more on screen.
    property bool compact: false
    //! Sliders start minimised; each one the user maximises is remembered
    //! (PanelMemory). False: they start maximised.
    property bool slidersStartMinimised: true
    function c(full, small) { return s(theme.compact ? small : full) }
    //! Slider sizes, [full, compact], for a slider minimised on its own.
    // Only the bar changes; the label, value box and spacing stay the same.
    readonly property var sliderSizes: ({
        track: [44, 12], edge: [4, 2], box: [18, 18], arrowW: [10, 5], arrowH: [12, 8],
        gap: [4, 2], title: [13, 13], value: [13, 13], row: [5, 5]
    })
    // the classic skin's smaller type and box
    readonly property var classicSliderSizes: ({ title: [11, 11], value: [11, 11], box: [16, 16], row: [4, 4] })
    function sliderSize(key, small) {
        const t = theme.classic && classicSliderSizes[key] ? classicSliderSizes[key] : sliderSizes[key]
        return s(t[small ? 1 : 0])
    }

    // --- skin --------------------------------------------------------------
    //! The look: "flat" (plain grey), "modular" (a synth rack: modules on
    //! rails, rendered knobs, LCDs) or "classic" (a 2006 DAW: slate-blue
    //! plugin windows with gradient title bars, raised bevels, small type,
    //! glossy knobs). The colours below follow it.
    property string skin: "classic"
    readonly property bool classic: skin === "classic"

    // --- colour ------------------------------------------------------------
    property color page:      classic ? "#2c3338" : "#4b4d4c"   // the window behind everything
    property color well:      classic ? "#1f2529" : "#5d6260"   // a slider's empty track, a field's fill
    property color wellHover: classic ? "#283035" : "#666b69"
    property color raised:    classic ? "#4a555c" : "#545756"   // a group's body
    property color sunken:    classic ? "#3a444a" : "#3f4241"   // buttons, code, the knob's face
    property color sunkenHover: classic ? "#455058" : "#464948"
    property color line:      classic ? "#5f6c73" : "#6a6f6d"   // quiet outlines and dividers
    property color titleBar:  "#5b6870"   // classic: a window's title bar, top of its gradient
    property color titleBarEnd: "#38434a" // and its foot
    property color accent:    "#b8de52"   // the lime: fills, values, focus
    // Shades of the accent, so any accent works.
    property color accentDim:  dimOf(accent)   // an arrow drawn on the accent
    property color accentEdge: edgeOf(accent)  // the line along the fill's edge
    property color accentInk:  inkOf(accent)   // text drawn on the accent
    function dimOf(c)  { return Qt.darker(c, 1.48) }
    function edgeOf(c) { return Qt.darker(c, 1.36) }
    function inkOf(c)  { return Qt.darker(c, 4.2) }
    //! The accent a control in this window draws with: the window's own
    //! accent if it declares one, the kit's otherwise.
    function accentIn(win) { return win && win.accent !== undefined ? win.accent : theme.accent }

    //! Accents that read well on the grey, for a swatch row.
    readonly property var accents: [
        { name: "highlighter", color: "#b8de52" },
        { name: "yellow",      color: "#f0e442" },
        { name: "amber",       color: "#ffbe3d" },
        { name: "orange",      color: "#ff8a3d" },
        { name: "coral",       color: "#ff6f61" },
        { name: "pink",        color: "#ff79c6" },
        { name: "violet",      color: "#b794ff" },
        { name: "sky",         color: "#5cc8ff" },
        { name: "aqua",        color: "#3fe0c5" },
        { name: "mint",        color: "#7dffa8" },
        { name: "white",       color: "#e8ecef" }
    ]
    property color arrow:     "#b9c0c4"   // an arrow drawn on the well
    property color arrowHot:  "#e6ecef"
    property color text:      classic ? "#e2e9ed" : "#f0f1ee"
    property color textDim:   classic ? "#a7b4bb" : "#b3b8b5"
    property color textFaint: classic ? "#7f8c93" : "#8c918f"
    property color editFill:  "#a8abae"   // a value box while it is typed in
    property color editText:  "#4a25c9"
    property color danger:    "#e0664f"
    property color screen:    classic ? "#14191c" : "#2b2f2e"   // a value box's LCD, the XY pad's scope, in the industrial look
    property color screwFace: "#8e9391"
    property color rack:      "#1c1e1d"   // the inside of the rack, behind the modules (industrial)

    // --- size --------------------------------------------------------------
    // c(full, compact)
    property int trackHeight: c(44, 22)
    property int edgeLine:    c(4, 3)    // the darker line along the fill's edge
    property int boxHeight:   s(18)
    property int arrowW:      c(10, 7)
    property int arrowH:      c(12, 9)
    property int arrowGap:    c(4, 3)    // between an arrow and the fill's edge
    property int rowGap:      s(5)    // label to control
    property int controlGap:  c(16, 10)  // one control to the next
    property int knobSize:    c(58, 42)
    property int groupInset:    s(18)   // a folding group's controls from its left edge (past the bracket)
    property int groupInsetEnd: s(14)   // and from its right edge
    property int sectionInset:  groupInsetEnd   // an always-open section's controls from either edge (no bracket)
    property int radius:      0

    // --- type --------------------------------------------------------------
    // Fonts every Windows PC has.
    property string family: classic ? "Tahoma" : "Segoe UI"
    property string mono: "Consolas"
    property int titleSize: s(classic ? 11 : 13)   // every control's label: sliders, knobs, gauges
    property int labelSize: s(classic ? 11 : 14)
    property int valueSize: s(classic ? 11 : 13)
    property int smallSize: s(classic ? 10 : 11)

    // --- drawing -----------------------------------------------------------
    //! The industrial look: brushed, bevelled plates with screws, a grained
    //! page, inset grooves, LCD value boxes, a scope screen for the XY pad,
    //! knurled knobs, LED buttons and stamped titles. Off: flat.
    //! Whether the skin is "modular" (the name from when it was the only
    //! other look). Set skin to change it.
    readonly property bool industrial: skin === "modular"
    //! A stamped title's style: a dark edge under the letters when industrial.
    readonly property int titleStyle: industrial ? Text.Raised : Text.Normal
    readonly property color titleStyleColor: Qt.rgba(0, 0, 0, 0.6)
    //! Antialiasing for arrows, dials and round shapes. Off: hard,
    //! nearest-neighbour edges, the kit's look. Text stays smooth.
    property bool smooth: false

    // --- motion ------------------------------------------------------------
    property int quick: 90
    property int ease:  160
}
