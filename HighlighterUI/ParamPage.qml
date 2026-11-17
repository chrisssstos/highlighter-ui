import QtQuick
import QtQuick.Controls.Basic as B

/// A scrolling column for a panel's controls, on the page colour. Give each
/// control width: parent.width (or less).
Flickable {
    id: root

    default property alias content: column.data
    property int padding: Theme.s(16)
    property alias spacing: column.spacing

    //! Scrolls so item, anywhere inside the page, comes to the top, or as
    //! near as the page's length allows: gliding there, and following it
    //! while groups above or around it fold open or shut (so it lands where
    //! it ends up); at once with animated false.
    function show(item, animated) {
        if (!item)
            return
        if (animated === false) {
            glide.stop()
            root.contentY = root.topFor(item)
            return
        }
        root.glideTarget = item
        root.glideFrom = root.contentY
        glide.restart()
    }
    function topFor(item) {
        const top = item.mapToItem(column, 0, 0).y + root.padding - Theme.s(8)
        return Math.max(0, Math.min(top, root.contentHeight - root.height))
    }
    property Item glideTarget: null
    property real glideFrom: 0
    property real glideAt: 1
    onGlideAtChanged: if (glide.running && root.glideTarget) root.contentY = root.glideFrom + (root.topFor(root.glideTarget) - root.glideFrom) * root.glideAt
    NumberAnimation {
        id: glide
        target: root
        property: "glideAt"
        from: 0; to: 1
        // Past a group's own fold, so it has settled before the glide ends.
        duration: Math.max(400, Theme.ease * 2.5)
        easing.type: Easing.InOutCubic
    }
    // A hand on the page takes over.
    onMovementStarted: glide.stop()

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + 2 * padding
    boundsBehavior: Flickable.StopAtBounds
    B.ScrollBar.vertical: ParamScrollBar {}

    Rectangle {
        parent: root; z: -1; anchors.fill: parent; color: Theme.page
    }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - 2 * root.padding - Theme.s(6)
        spacing: Theme.controlGap
    }
}
