#include "warpmesh.h"
#include "warpmath.h"

#include <QSGGeometryNode>
#include <QSGTextureMaterial>
#include <QSGTextureProvider>
#include <QSGDynamicTexture>
#include <QQuickWindow>

namespace {

// The mesh node. It keeps its source (the texture provider), not a texture:
// each frame it takes the provider's texture as it is then (an Image's is
// replaced, and freed, with each new picture), and asks a layer's
// (ShaderEffectSource) to be brought up to date, unless told not to (a
// second reader in a grab).
class WarpNode : public QSGGeometryNode
{
public:
    WarpNode()
    {
        setFlag(UsePreprocess, true);
        setFlag(OwnsGeometry, true);
        setMaterial(&m_material);
        setOpaqueMaterial(&m_opaque);
        for (QSGOpaqueTextureMaterial *m : std::initializer_list<QSGOpaqueTextureMaterial *>{ &m_material, &m_opaque }) {
            m->setFiltering(QSGTexture::Linear);
            m->setHorizontalWrapMode(QSGTexture::ClampToEdge);
            m->setVerticalWrapMode(QSGTexture::ClampToEdge);
        }
    }

    QPointer<QSGTextureProvider> provider;
    bool refresh = true;
    int cells = -1; // the mesh's subdivisions (its triangles only change with them)

    //! the provider's texture as it is now
    QSGTexture *takeTexture()
    {
        QSGTexture *t = provider ? provider->texture() : nullptr;
        // a small Image's texture is a piece of a shared atlas: the mesh wants
        // the picture on its own (0..1 across it)
        if (t && t->isAtlasTexture()) t = t->removedFromAtlas();
        if (t != m_material.texture()) {
            m_material.setTexture(t);
            m_opaque.setTexture(t);
            markDirty(DirtyMaterial);
        }
        return t;
    }

    void preprocess() override
    {
        QSGTexture *t = takeTexture();
        if (refresh)
            if (auto *d = qobject_cast<QSGDynamicTexture *>(t))
                d->updateTexture();
    }

private:
    QSGTextureMaterial m_material;
    QSGOpaqueTextureMaterial m_opaque;
};

} // namespace

WarpMesh::WarpMesh(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void WarpMesh::changed()
{
    m_meshDirty = true;
    update();
}

void WarpMesh::setSource(QQuickItem *source)
{
    if (m_source == source) return;
    // the provider is left to updatePaintNode (the render thread owns it)
    m_source = source;
    emit sourceChanged();
    update();
}

void WarpMesh::setSourceRect(const QRectF &rect)
{
    if (m_sourceRect == rect) return;
    m_sourceRect = rect;
    emit sourceRectChanged();
    changed();
}

void WarpMesh::setColumns(int columns)
{
    columns = std::max(2, columns);
    if (m_columns == columns) return;
    m_columns = columns;
    emit warpChanged();
    changed();
}

void WarpMesh::setRows(int rows)
{
    rows = std::max(2, rows);
    if (m_rows == rows) return;
    m_rows = rows;
    emit warpChanged();
    changed();
}

void WarpMesh::setPoints(const QVariantList &points)
{
    if (m_points == points) return; // the same points: no new mesh
    m_points = points;
    emit warpChanged();
    changed();
}

void WarpMesh::setPerspective(bool perspective)
{
    if (m_perspective == perspective) return;
    m_perspective = perspective;
    emit warpChanged();
    changed();
}

void WarpMesh::setSubdivisions(int subdivisions)
{
    subdivisions = std::clamp(subdivisions, 1, 200);
    if (m_subdivisions == subdivisions) return;
    m_subdivisions = subdivisions;
    emit warpChanged();
    changed();
}

void WarpMesh::setFlipSource(bool flip)
{
    if (m_flipSource == flip) return;
    m_flipSource = flip;
    emit sourceRectChanged();
    changed();
}

void WarpMesh::setRefreshSource(bool refresh)
{
    if (m_refreshSource == refresh) return;
    m_refreshSource = refresh;
    emit sourceChanged();
    update();
}

void WarpMesh::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    if (newGeometry.size() != oldGeometry.size()) changed();
}

QSGNode *WarpMesh::updatePaintNode(QSGNode *old, UpdatePaintNodeData *)
{
    auto *node = static_cast<WarpNode *>(old);

    // the source's provider (render thread); its texture is read each frame
    QSGTextureProvider *provider = m_source && m_source->isTextureProvider() ? m_source->textureProvider() : nullptr;
    if (provider != m_provider) {
        if (m_provider) disconnect(m_provider, nullptr, this, nullptr);
        m_provider = provider;
        if (provider)
            connect(provider, &QSGTextureProvider::textureChanged, this, &QQuickItem::update, Qt::QueuedConnection);
    }
    if (!provider || !provider->texture() || width() <= 0 || height() <= 0) {
        delete node;
        return nullptr;
    }

    if (!node) {
        node = new WarpNode;
        m_meshDirty = true;
    }
    node->provider = provider;
    node->refresh = m_refreshSource;
    node->takeTexture(); // the texture now, for this frame's batching

    if (m_meshDirty) {
        m_meshDirty = false;
        const warpmath::Grid grid = warpmath::fromVariant(m_points, m_columns, m_rows, m_perspective);
        const int n = m_subdivisions;
        const int perRow = n + 1;
        // the triangles only change with the subdivisions: otherwise only the vertices move
        QSGGeometry *geometry = node->geometry();
        if (node->cells != n || !geometry) {
            geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), perRow * perRow, n * n * 6,
                                       QSGGeometry::UnsignedIntType);
            geometry->setDrawingMode(QSGGeometry::DrawTriangles);
            quint32 *idx = geometry->indexDataAsUInt();
            for (int j = 0; j < n; ++j) {
                for (int i = 0; i < n; ++i) {
                    const quint32 a = j * perRow + i, b = a + 1, c = a + perRow, d = c + 1;
                    *idx++ = a; *idx++ = b; *idx++ = c;
                    *idx++ = b; *idx++ = d; *idx++ = c;
                }
            }
            node->setGeometry(geometry);
            node->cells = n;
        }
        auto *v = geometry->vertexDataAsTexturedPoint2D();
        const QRectF s = m_sourceRect;
        const qreal w = width(), h = height();
        // an input reaching past the source: only the part on it is drawn
        // (the rest stays black, rather than the source's edge smeared out)
        const qreal u0 = s.width() > 0 ? std::clamp(-s.x() / s.width(), 0.0, 1.0) : 0;
        const qreal u1 = s.width() > 0 ? std::clamp((1 - s.x()) / s.width(), 0.0, 1.0) : 1;
        const qreal t0 = s.height() > 0 ? std::clamp(-s.y() / s.height(), 0.0, 1.0) : 0;
        const qreal t1 = s.height() > 0 ? std::clamp((1 - s.y()) / s.height(), 0.0, 1.0) : 1;
        for (int j = 0; j <= n; ++j) {
            for (int i = 0; i <= n; ++i) {
                const qreal u = u0 + (u1 - u0) * i / n, t = t0 + (t1 - t0) * j / n;
                const QPointF p = grid.valid() ? warpmath::map(grid, u, t) : QPointF(u, t);
                qreal ty = s.y() + t * s.height();
                if (m_flipSource) ty = 1 - ty;
                v[j * perRow + i].set(float(p.x() * w), float(p.y() * h), float(s.x() + u * s.width()), float(ty));
            }
        }
        node->markDirty(QSGNode::DirtyGeometry);
    }
    return node;
}
