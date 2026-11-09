import QtQuick
import OutputMapper

/// The outputs: the source (the app's content item, sourceWidth x
/// sourceHeight) rendered once, offscreen, and every slice of `map` drawn
/// from it onto its output, warped and masked. Fill the output window with
/// it; the source item is hidden from view (it is only seen through the
/// slices). With `map.testCard`, a test card is mapped in place of the content.
Item {
    id: root

    required property Item source
    required property OutputMap map
    //! some textures come upside down; set if the content shows flipped
    property bool flipSource: false
    //! cells of each slice's mesh (more: smoother bends)
    property int subdivisions: 32

    //! the rendered source, for anything else here that wants to read it
    readonly property alias texture: rendered
    //! the source small, for the editor's views to grab (grabbing the
    //! source itself would render it all again)
    readonly property alias thumbnail: thumb
    //! the thumbnail's size, of the source's
    property real thumbnailScale: 1 / 6

    ShaderEffectSource {
        id: rendered
        sourceItem: root.source
        hideSource: true
        // paused while the test card is up (the content stays hidden)
        live: !root.map.testCard
        visible: false
        smooth: true
        textureSize: Qt.size(root.map.sourceWidth, root.map.sourceHeight)
        textureMirroring: ShaderEffectSource.MirrorVertically
    }

    // the test card, mapped like the content; made only while it is up
    Loader {
        id: cardLoader
        active: root.map.testCard
        sourceComponent: Item {
            readonly property alias texture: cardTexture
            TestCard {
                id: card
                width: root.map.sourceWidth
                height: root.map.sourceHeight
                map: root.map
            }
            ShaderEffectSource {
                id: cardTexture
                sourceItem: card
                hideSource: true
                visible: false
                smooth: true
                textureSize: Qt.size(root.map.sourceWidth, root.map.sourceHeight)
                textureMirroring: ShaderEffectSource.MirrorVertically
            }
        }
    }
    readonly property Item _drawn: cardLoader.item ? cardLoader.item.texture : rendered

    Repeater {
        model: root.map.slices.length
        Item {
            id: slot
            required property int index
            readonly property var s: { root.map.revision; return root.map.slices[index] }
            readonly property var o: { root.map.outputs; return root.map.outputOf(s) ?? { x: 0, y: 0, width: 0, height: 0 } }
            x: o.x; y: o.y; width: o.width; height: o.height
            visible: !!s && s.enabled && width > 0
            // a slice stays on its own output (its mask's surround too)
            clip: true

            WarpMesh {
                anchors.fill: parent
                source: root._drawn
                flipSource: root.flipSource
                subdivisions: root.subdivisions
                sourceRect: slot.s ? Qt.rect(slot.s.input.x / root.map.sourceWidth, slot.s.input.y / root.map.sourceHeight,
                                             slot.s.input.width / root.map.sourceWidth, slot.s.input.height / root.map.sourceHeight)
                                   : Qt.rect(0, 0, 1, 1)
                columns: slot.s?.columns ?? 2
                rows: slot.s?.rows ?? 2
                perspective: slot.s?.perspective ?? true
                points: slot.s?.points ?? []
            }
            MaskShape {
                anchors.fill: parent
                points: slot.s?.mask ?? []
            }
        }
    }

    // the thumbnail: the texture drawn small, beside the window (never seen)
    WarpMesh {
        id: thumb
        x: -width - 16
        width: Math.max(1, Math.round(root.map.sourceWidth * root.thumbnailScale))
        height: Math.max(1, Math.round(root.map.sourceHeight * root.thumbnailScale))
        source: rendered
        refreshSource: false
        subdivisions: 1
        points: Warp.grid(2, 2)
    }

    // what the editor is doing, on the outputs themselves
    Repeater {
        model: root.map.showOnOutput ? root.map.slices.length : 0
        SliceOverlay {
            required property int index
            readonly property var s: { root.map.revision; return root.map.slices[index] }
            readonly property var o: { root.map.outputs; return root.map.outputOf(s) ?? { x: 0, y: 0, width: 0, height: 0 } }
            x: o.x; y: o.y; width: o.width; height: o.height
            visible: width > 0
            slice: s
            selected: index === root.map.selected
            selectedPoint: root.map.selectedPoint
            maskMode: root.map.maskMode
            unit: Math.max(1, Math.min(width, height) / 540)
        }
    }
}
