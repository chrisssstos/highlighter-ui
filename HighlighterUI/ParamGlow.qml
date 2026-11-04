import QtQuick
import QtQuick.Effects
import "ParamMath.js" as PM

/// Light from a lit part, as if the lime were the light source: a blur of
/// the part's own shape (a bar, an outline, text, an arc), so the glow
/// follows it. How far it reaches and how bright it is follow how much
/// light there is: a thin line or small text gets a short faint glow, a
/// full bar a wide strong one. Use it as the lit part's layer effect:
///
///     layer.enabled: Theme.glow && lit
///     layer.effect: ParamGlow { w: fill.width; h: fill.height }
///
/// Give `thick` for something drawn in strokes (text, an outline, an arc):
/// the stroke's width, not the box round it.
MultiEffect {
    id: glow

    //! The lit part's size.
    property real w: 0
    property real h: 0
    //! How thick its light is: the part itself for a solid block, the
    //! stroke for a line, an outline or text.
    property real thick: Math.min(w, h)
    property color glowColor: Theme.accent
    //! 0..1, on top of what its size gives.
    property real strength: 1

    // how far the light reaches: mostly from its thickness, a little from its size
    readonly property real reach: PM.clamp(Theme.s(5) + glow.thick * 0.8 + Math.sqrt(Math.max(0, glow.w * glow.h)) * 0.05,
                                           Theme.s(5), Theme.s(40))
    // and how bright: a blur spreads a thin light thin, so it starts high
    readonly property real intensity: PM.clamp(0.75 + glow.thick / Theme.s(80), 0.75, 1)

    shadowEnabled: true
    shadowColor: glow.glowColor
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    shadowBlur: 1
    blurMax: Math.min(64, Math.max(2, Math.round(glow.reach)))
    shadowOpacity: glow.intensity * glow.strength
    autoPaddingEnabled: true
}
