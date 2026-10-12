import QtQuick

/// One frame of a slider's illustration (ParamFrames): the root of a custom
/// frame. It is told where in the range it stands (t, 0 at `from` to 1 at
/// `to`) and whether it is the value's frame (lit), and carries the three
/// colours its ParamSegments draw in. Put ParamSegments in it, laid out on
/// its width and height, each lit by its own `on`:
///
///     illustration: Component {
///         ParamFrame {
///             ParamSegment { x: 2; y: 2; width: parent.width * t; height: 3; on: true }
///         }
///     }
Item {
    //! Where this frame stands in the range, 0..1.
    property real t: 0
    //! Whether it is the frame nearest the value.
    property bool lit: false
    //! The value's frame draws in ink, the others in dim; segments that are
    //! off are printed faint, in ghost.
    property color ink: "#fbf27a"
    readonly property color dim: "#a9b6a4"
    readonly property color ghost: "#677160"
}
