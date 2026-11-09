#pragma once

#include <QPointer>
#include <QQuickItem>
#include <QRectF>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class QSGTextureProvider;

// One slice drawn to its output: a rectangle of a texture (sourceRect, 0..1
// of `source`, which must give a texture: a ShaderEffectSource, or an item
// with layer.enabled) through the warp its points describe (see warpmath.h),
// over this item's whole area. Drawing it is one textured mesh, so any
// number of slices can read the same source, rendered once.
class WarpMesh : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickItem *source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QRectF sourceRect READ sourceRect WRITE setSourceRect NOTIFY sourceRectChanged)
    Q_PROPERTY(int columns READ columns WRITE setColumns NOTIFY warpChanged)
    Q_PROPERTY(int rows READ rows WRITE setRows NOTIFY warpChanged)
    Q_PROPERTY(QVariantList points READ points WRITE setPoints NOTIFY warpChanged)
    Q_PROPERTY(bool perspective READ perspective WRITE setPerspective NOTIFY warpChanged)
    //! the mesh drawn: this many cells each way (more: smoother bends)
    Q_PROPERTY(int subdivisions READ subdivisions WRITE setSubdivisions NOTIFY warpChanged)
    //! the source's texture upside down (some texture providers are)
    Q_PROPERTY(bool flipSource READ flipSource WRITE setFlipSource NOTIFY sourceRectChanged)
    //! bring a layer source up to date before drawing (off: only read it, as
    //! a second reader in the same frame, or one drawn inside a grab, must)
    Q_PROPERTY(bool refreshSource READ refreshSource WRITE setRefreshSource NOTIFY sourceChanged)

public:
    explicit WarpMesh(QQuickItem *parent = nullptr);

    QQuickItem *source() const { return m_source; }
    void setSource(QQuickItem *source);
    QRectF sourceRect() const { return m_sourceRect; }
    void setSourceRect(const QRectF &rect);
    int columns() const { return m_columns; }
    void setColumns(int columns);
    int rows() const { return m_rows; }
    void setRows(int rows);
    QVariantList points() const { return m_points; }
    void setPoints(const QVariantList &points);
    bool perspective() const { return m_perspective; }
    void setPerspective(bool perspective);
    int subdivisions() const { return m_subdivisions; }
    void setSubdivisions(int subdivisions);
    bool flipSource() const { return m_flipSource; }
    void setFlipSource(bool flip);
    bool refreshSource() const { return m_refreshSource; }
    void setRefreshSource(bool refresh);

signals:
    void sourceChanged();
    void sourceRectChanged();
    void warpChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *old, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void changed();

    QPointer<QQuickItem> m_source;
    QPointer<QSGTextureProvider> m_provider;
    QRectF m_sourceRect{ 0, 0, 1, 1 };
    int m_columns = 2;
    int m_rows = 2;
    QVariantList m_points;
    bool m_perspective = true;
    int m_subdivisions = 32;
    bool m_flipSource = false;
    bool m_refreshSource = true;
    bool m_meshDirty = true;
};
