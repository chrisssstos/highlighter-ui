pragma Singleton
import QtQuick

/// Colours, sizes and the font every HighlighterUI control draws with. Change
/// scale to grow or shrink the whole panel (a window on a high DPI screen,
/// say), compact for smaller sliders and knobs that fit more on screen, and
/// accent to recolour it: the darker shades follow the accent. A window, or
/// any item (a section, a deck's panel), that declares its own
/// `property color accent` draws its controls in that colour instead, so two
/// panels can tell themselves apart, even in one window.
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
    //! The look: "flat" (plain grey, the default), "classic" (old FL
    //! Studio: slate-blue plugin windows with gradient title bars, raised
    //! bevels, small type, glossy knobs) or "hardware" (a light warm-grey
    //! faceplate with rounded bevelled panels and keys, dark recessed screens,
    //! and whatever is on lit pale and glowing, like a backlit unit). The
    //! colours below follow it; choosing a skin sets the glow to its own.
    property string skin: "flat"
    readonly property bool classic: skin === "classic"
    readonly property bool hardware: skin === "hardware"

    // --- colour ------------------------------------------------------------
    //! The hardware skin's mode: "dark" (a dark faceplate, the default) or
    //! "light" (a light warm-grey faceplate, dark ink). Only the hardware
    //! skin has a light mode.
    property string mode: "dark"
    readonly property bool lightMode: hardware && mode === "light"
    // hardware, dark: a warm dark-grey faceplate, darker keys, near-black screens;
    // light: a light warm-grey faceplate and keys on a mid grey, near-black screens
    property color page:      classic ? "#2c3338" : lightMode ? "#a3a09a" : hardware ? "#454543" : "#4b4d4c"   // the window behind everything
    property color well:      classic ? "#1f2529" : lightMode ? "#2c2d2f" : hardware ? "#28292b" : "#5d6260"   // a slider's empty track, a field's fill (hardware: a dark screen)
    property color wellHover: classic ? "#283035" : lightMode ? "#343537" : hardware ? "#303133" : "#666b69"
    property color raised:    classic ? "#4a555c" : lightMode ? "#cdcac3" : hardware ? "#52524f" : "#545756"   // a group's body (hardware: the faceplate)
    property color sunken:    classic ? "#3a444a" : lightMode ? "#bcb9b2" : hardware ? "#2d2e2f" : "#3f4241"   // buttons, code, the knob's face (hardware: keys)
    property color sunkenHover: classic ? "#455058" : lightMode ? "#c6c3bc" : hardware ? "#363739" : "#464948"
    property color line:      classic ? "#5f6c73" : lightMode ? "#8d8981" : hardware ? "#686763" : "#6a6f6d"   // quiet outlines and dividers
    property color panelBar:  classic ? "#5b6870" : lightMode ? "#bfbcb5" : hardware ? "#5d5d59" : "#636866"   // a graph panel's title bar
    property color panelEdge: lightMode ? "#8f8b84" : hardware ? "#2f302f" : "#3b3e3d"   // the thin outline round a graph panel
    //! A screen a graph, an envelope or a table is drawn on: dark glass in
    //! the hardware skin (either mode), the sunken colour otherwise; and the
    //! text and marks on it, always light on it.
    property color screenFill: hardware ? (lightMode ? "#292a2c" : "#242527") : sunken
    //! A marked stretch of a screen (an animator's range): a lighter shade of
    //! it, a hint of the accent, so it stands apart from the rest.
    function screenMarked(c) { return hardware ? Qt.tint(Qt.lighter(well, lightMode ? 1.5 : 1.55), Qt.rgba(c.r, c.g, c.b, 0.12)) : screenFill }
    property color screenText: hardware ? "#e4dfd3" : text
    property color screenDim:  hardware ? "#a8a397" : textDim
    property color screenFaint: hardware ? "#77736a" : textFaint
    property color titleBar:  "#5b6870"   // classic: a window's title bar, top of its gradient
    property color titleBarEnd: "#38434a" // and its foot
    property color accent:    "#def243"   // the highlighter yellow-lime: fills, values, focus
    // Shades of the accent, so any accent works.
    property color accentDim:  dimOf(accent)   // an arrow drawn on the accent
    property color accentEdge: edgeOf(accent)  // the line along the fill's edge
    property color accentInk:  inkOf(accent)   // text drawn on the accent
    function dimOf(c)  { return Qt.darker(c, 1.48) }
    function edgeOf(c) { return Qt.darker(c, 1.36) }
    function inkOf(c)  { return Qt.darker(c, 4.2) }
    //! Hardware: something lit is almost white, its colour in the glow round
    //! it (a neon tube, a backlit legend): the colour washed toward warm white.
    function hotOf(c)  { return Qt.tint(c, Qt.rgba(1, 0.96, 0.93, 0.74)) }
    //! What a lit thing is drawn in: hot in the hardware skin, the colour
    //! otherwise. In light mode less washed, so it stands out on light keys.
    function litOf(c)  { return theme.lightMode ? Qt.tint(c, Qt.rgba(1, 0.96, 0.93, 0.38)) : theme.hardware ? hotOf(c) : c }
    //! The accent as text or a thin line drawn straight on the faceplate or
    //! a key: deepened in light mode, so it always reads (an accent is made
    //! to read on dark grey).
    function onPanel(c) { return theme.lightMode ? Qt.darker(c, 1.75) : c }
    //! The accent a control in this window draws with: the window's own
    //! accent if it declares one, the kit's otherwise.
    function accentIn(win) { return win && win.accent !== undefined ? win.accent : theme.accent }
    //! The accent a control draws with: the nearest item from it up (itself
    //! included) that declares a `property color accent`, else its window's
    //! (accentIn). A bool `accent` (ParamButton's "the action that matters")
    //! is not a colour and is passed over.
    function accentAt(item, win) {
        for (let p = item; p; p = p.parent)
            if (p.accent !== undefined && typeof p.accent !== "boolean") return p.accent
        return accentIn(win)
    }

    //! Accents that read well on the grey, for a swatch row.
    readonly property var accents: [
        { name: "highlighter", color: "#def243" },
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
    //! An arrow drawn on the faceplate (a knob's, a slider's past the bar's end).
    property color panelArrow:    lightMode ? "#5f5c56" : arrow
    property color panelArrowHot: lightMode ? "#262522" : arrowHot
    property color text:      classic ? "#e2e9ed" : lightMode ? "#262522" : hardware ? "#ece8df" : "#f0f1ee"   // light mode: dark ink on the faceplate
    property color textDim:   classic ? "#a7b4bb" : lightMode ? "#4c4a45" : hardware ? "#b0aca3" : "#b3b8b5"
    property color textFaint: classic ? "#7f8c93" : lightMode ? "#6f6b64" : hardware ? "#85827b" : "#8c918f"
    property color editFill:  "#a8abae"   // a value box while it is typed in
    property color editText:  "#4a25c9"
    property color danger:    "#e0664f"
    property color caution:   "#f0b44a"   // between fine and danger: a rating that's only OK
    property color jump:      "#5cc8ff"   // a graph for a moment after its value jumps the good way
    property color jumpBad:   "#e0664f"   // and the bad way
    property color screen:    "#14191c"   // classic: a value box's LCD
    // hardware: a reflective LCD (ParamLCD): pale grey-green, dark segments
    property color lcd:       "#a9b19e"
    property color lcdInk:    "#1c211b"
    property color lcdGhost:  "#9aa290"

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
    property int radius:      hardware ? s(4) : 0   // hardware: rounded keys and panels

    // --- type --------------------------------------------------------------
    // Fonts every Windows PC (or Mac) has.
    readonly property bool mac: Qt.platform.os === "osx"
    property string family: classic ? "Tahoma" : mac ? "Helvetica Neue" : "Segoe UI"
    property string mono: mac ? "Menlo" : "Consolas"
    property int titleSize: s(classic ? 11 : 13)   // every control's label: sliders, knobs, gauges
    property int labelSize: s(classic ? 11 : 14)
    property int valueSize: s(classic ? 11 : 13)
    property int smallSize: s(classic ? 10 : 11)

    // --- drawing -----------------------------------------------------------
    //! A title's style: a dark edge under the letters in the classic skin.
    readonly property int titleStyle: classic ? Text.Raised : Text.Normal
    readonly property color titleStyleColor: Qt.rgba(0, 0, 0, 0.6)
    //! Antialiasing for arrows, dials and round shapes. Off: hard,
    //! nearest-neighbour edges, the kit's look. Text stays smooth.
    property bool smooth: false
    //! Whatever is lit (a slider's fill, the picked choice, an accent button,
    //! a toggle that's on, a light) glows in its colour, like a backlit
    //! display. On by default in the hardware skin, off in the others;
    //! choosing a skin sets it, and it can be switched after.
    property bool glow: hardware
    // every change of skin sets it again: on for hardware, off for the others
    onSkinChanged: glow = skin === "hardware"

    // --- motion ------------------------------------------------------------
    property int quick: 90
    property int ease:  160
}
