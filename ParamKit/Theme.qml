pragma Singleton
import QtQuick

/// Colours, sizes and the font every ParamKit control draws with. Change
/// scale to grow or shrink the whole panel (a window on a high DPI screen,
/// say); change the colours to reskin it.
QtObject {
    id: theme

    //! Every size in the kit is multiplied by this.
    property real scale: 1
    function s(px) { return Math.round(px * theme.scale) }

    // --- colour ------------------------------------------------------------
    property color page:      "#4b4d4c"   // the window behind everything
    property color well:      "#5d6260"   // a slider's empty track, a field's fill
    property color wellHover: "#666b69"
    property color raised:    "#545756"   // a group's body
    property color sunken:    "#3f4241"   // buttons, code, the knob's face
    property color sunkenHover: "#464948"
    property color line:      "#6a6f6d"   // quiet outlines and dividers
    property color accent:    "#b8de52"   // the lime: fills, values, focus
    property color accentDim: "#7d9a2e"   // an arrow drawn on the lime
    property color accentInk: "#2c3410"   // text drawn on the lime
    property color arrow:     "#b9c0c4"   // an arrow drawn on the well
    property color arrowHot:  "#e6ecef"
    property color text:      "#f0f1ee"
    property color textDim:   "#b3b8b5"
    property color textFaint: "#8c918f"
    property color editFill:  "#a8abae"   // a value box while it is typed in
    property color editText:  "#4a25c9"
    property color danger:    "#e0664f"

    // --- size --------------------------------------------------------------
    property int trackHeight: s(26)
    property int boxHeight:   s(20)
    property int arrowW:      s(9)
    property int arrowH:      s(12)
    property int arrowGap:    s(3)    // between an arrow and the fill's edge
    property int rowGap:      s(4)    // label to control
    property int controlGap:  s(14)   // one control to the next
    property int radius:      0

    // --- type --------------------------------------------------------------
    readonly property FontLoader inter: FontLoader { source: "fonts/Inter.ttf" }
    property string family: inter.status === FontLoader.Ready ? inter.name : "Segoe UI"
    property string mono: "Cascadia Mono"
    property int labelSize: s(13)
    property int valueSize: s(13)
    property int smallSize: s(11)

    // --- motion ------------------------------------------------------------
    property int quick: 90
    property int ease:  160
}
