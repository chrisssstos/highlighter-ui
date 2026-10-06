pragma Singleton
import QtQuick

/// Colours, sizes and the font every HighlighterUI control draws with. Change
/// scale to grow or shrink the whole panel (a window on a high DPI screen,
/// say), compact for smaller sliders and knobs that fit more on screen, and
/// accent to recolour it: the darker shades follow the accent.
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
    function sliderSize(key, small) { return s(sliderSizes[key][small ? 1 : 0]) }

    // --- colour ------------------------------------------------------------
    property color page:      "#4b4d4c"   // the window behind everything
    property color well:      "#5d6260"   // a slider's empty track, a field's fill
    property color wellHover: "#666b69"
    property color raised:    "#545756"   // a group's body
    property color sunken:    "#3f4241"   // buttons, code, the knob's face
    property color sunkenHover: "#464948"
    property color line:      "#6a6f6d"   // quiet outlines and dividers
    property color accent:    "#b8de52"   // the lime: fills, values, focus
    // Shades of the accent, so any accent works.
    property color accentDim:  Qt.darker(accent, 1.48)  // an arrow drawn on the accent
    property color accentEdge: Qt.darker(accent, 1.36)  // the line along the fill's edge
    property color accentInk:  Qt.darker(accent, 4.2)   // text drawn on the accent

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
    property color text:      "#f0f1ee"
    property color textDim:   "#b3b8b5"
    property color textFaint: "#8c918f"
    property color editFill:  "#a8abae"   // a value box while it is typed in
    property color editText:  "#4a25c9"
    property color danger:    "#e0664f"

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
    property int radius:      0

    // --- type --------------------------------------------------------------
    // Fonts every Windows PC has.
    property string family: "Segoe UI"
    property string mono: "Consolas"
    property int titleSize: s(13)   // every control's label: sliders, knobs, gauges
    property int labelSize: s(14)
    property int valueSize: s(13)
    property int smallSize: s(11)

    // --- drawing -----------------------------------------------------------
    //! Antialiasing for arrows, dials and round shapes. Off: hard,
    //! nearest-neighbour edges, the kit's look. Text stays smooth.
    property bool smooth: false

    // --- motion ------------------------------------------------------------
    property int quick: 90
    property int ease:  160
}
