#include "warpmesh.h"
#include "warpmath.h"

#include <QSGGeometryNode>
#include <QSGTextureMaterial>
#include <QSGTextureProvider>
#include <QSGDynamicTexture>
#include <QQuickWindow>

namespace {

// The mesh node. A layer's texture (ShaderEffectSource) is only brought up to
// date when something asks; this asks every frame it is drawn.
class WarpNode : public QSGGeometryNode
{
public:
    explicit WarpNode(bool refresh)
    {
        setFlag(UsePreprocess, refresh);
        setFlag(OwnsGeometry, true);
        setMaterial(&m_material);
        setOpaqueMaterial(&m_opaque);
        m_material.setFiltering(QSGTexture::Linear);
        m_opaque.setFiltering(QSGTexture::Linear);
        m_material.setHorizontalWrapMode(QSGTexture::ClampToEdge);
        m_material.setVerticalWrapMode(QSGTexture::ClampToEdge);
        m_opaque.setHorizontalWrapMode(QSGTexture::ClampToEdge);
        m_opaque.setVerticalWrapMode(QSGTexture::ClampToEdge);
    }

    void setTexture(QSGTexture *t)
    {
        if (m_material.texture() == t) return;
        m_material.setTexture(t);
        m_opaque.setTexture(t);
        markDirty(DirtyMaterial);
    }
    QSGTexture *texture() const { return m_material.texture(); }

    void preprocess() override
    {
        if (auto *d = qobject_cast<QSGDynamicTexture *>(texture()))
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
    if (m_provider) disconnect(m_provider, nullptr, this, nullptr);
    m_source = source;
    m_provider = nullptr;
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

    // the texture, from the source's provider (render thread)
    QSGTextureProvider *provider = m_source && m_source->isTextureProvider() ? m_source->textureProvider() : nullptr;
    if (provider != m_provider) {
        if (m_provider) disconnect(m_provider, nullptr, this, nullptr);
        m_provider = provider;
        if (provider)
            connect(provider, &QSGTextureProvider::textureChanged, this, &QQuickItem::update, Qt::QueuedConnection);
    }
    QSGTexture *texture = provider ? provider->texture() : nullptr;
    const warpmath::Grid grid = warpmath::fromVariant(m_points, m_columns, m_rows, m_perspective);
    if (!texture || width() <= 0 || height() <= 0) {
        delete node;
        return nullptr;
    }

    if (node && node->flags().testFlag(QSGNode::UsePreprocess) != m_refreshSource) {
        delete node;
        node = nullptr;
    }
    if (!node) {
        node = new WarpNode(m_refreshSource);
        m_meshDirty = true;
    }
    node->setTexture(texture);

    if (m_meshDirty) {
        m_meshDirty = false;
        const int n = m_subdivisions;
        const int perRow = n + 1;
        auto *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), perRow * perRow, n * n * 6,
                                         QSGGeometry::UnsignedIntType);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        auto *v = geometry->vertexDataAsTexturedPoint2D();
        const QRectF s = m_sourceRect;
        const qreal w = width(), h = height();
        for (int j = 0; j <= n; ++j) {
            for (int i = 0; i <= n; ++i) {
                const qreal u = qreal(i) / n, t = qreal(j) / n;
                const QPointF p = grid.valid() ? warpmath::map(grid, u, t) : QPointF(u, t);
                qreal ty = s.y() + t * s.height();
                if (m_flipSource) ty = 1 - ty;
                v[j * perRow + i].set(float(p.x() * w), float(p.y() * h), float(s.x() + u * s.width()), float(ty));
            }
        }
        quint32 *idx = geometry->indexDataAsUInt();
        for (int j = 0; j < n; ++j) {
            for (int i = 0; i < n; ++i) {
                const quint32 a = j * perRow + i, b = a + 1, c = a + perRow, d = c + 1;
                *idx++ = a; *idx++ = b; *idx++ = c;
                *idx++ = b; *idx++ = d; *idx++ = c;
            }
        }
        node->setGeometry(geometry);
        node->markDirty(QSGNode::DirtyGeometry);
    }
    return node;
}
