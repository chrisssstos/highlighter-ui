import QtQuick

/// A titled section that always stays open, with no bracket (only a group
/// that folds has one): the controls
/// for one thing on screen (the signage card, the call to action). Use a
/// ParamGroup instead when there are enough sections that some should fold
/// away. Give its children width: parent.width.
ParamGroup {
    collapsible: false
    open: true
}
