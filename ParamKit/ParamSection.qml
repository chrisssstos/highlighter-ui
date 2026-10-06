import QtQuick

/// A titled section in a lime bracket that always stays open: the controls
/// for one thing on screen (the signage card, the call to action). Use a
/// ParamGroup instead when there are enough sections that some should fold
/// away. Give its children width: parent.width.
ParamGroup {
    collapsible: false
    open: true
}
