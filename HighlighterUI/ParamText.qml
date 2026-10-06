import QtQuick

/// The panel's own text: a note under some controls, a status, a path, or
/// (caps) a column's name over rows of controls. Wraps unless told not to;
/// give it width: parent.width.
Text {
    id: root

    //! "dim" (notes, the default), "normal" (a status, a row's name) or
    //! "faint" (paths, asides).
    property string tone: "dim"
    //! Smaller: an aside.
    property bool small: false
    //! Small spaced capitals, as a column's name over rows.
    property bool caps: false
    property bool mono: false

    wrapMode: Text.WordWrap
    color: root.tone === "normal" ? Theme.text : root.tone === "faint" ? Theme.textFaint : Theme.textDim
    font.family: root.mono ? Theme.mono : Theme.family
    font.pixelSize: root.caps || root.small ? Theme.smallSize : Theme.labelSize
    font.weight: root.caps ? Font.Bold : Font.Normal
    font.letterSpacing: root.caps ? Theme.s(1) : 0
    font.capitalization: root.caps ? Font.AllUppercase : Font.MixedCase
}
