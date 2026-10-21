import QtQuick
import QtQuick.Effects

/// The glow round something lit in the hardware skin, as on a backlit
/// display: a smooth halo in its colour, fading out (a RectangularShadow:
/// one quad, the falloff drawn in the shader, so no banding). Put it behind
/// the lit thing (z below it), the same size.
Item {
    id: glow
    property color color: Theme.accent
    //! 0..1: how bright.
    property real strength: 1
    //! The lit thing's corner radius.
    property real radius: Theme.radius
    visible: Theme.hardware && strength > 0

    RectangularShadow {
        anchors.fill: parent
        color: glow.color
        blur: Theme.s(16)
        spread: Theme.s(2)
        radius: glow.radius
        opacity: 0.85 * glow.strength
        cached: true
    }
}
