#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

// The warp maths for QML (the editor): the same as WarpMesh draws with.
// Points are lists of {x, y}, normalised to the output (see warpmath.h).
class Warp : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    //! the identity grid, columns x rows
    Q_INVOKABLE QVariantList grid(int columns, int rows) const;
    //! where (u, v) of the input lands
    Q_INVOKABLE QVariantMap map(const QVariantList &points, int columns, int rows, bool perspective, qreal u, qreal v) const;
    //! the slice's outline, clockwise from the top left, `steps` points a side
    Q_INVOKABLE QVariantList outline(const QVariantList &points, int columns, int rows, bool perspective, int steps) const;
    //! the warp's lines: each a list of points, `lines` across and down, `steps` points each
    Q_INVOKABLE QVariantList lines(const QVariantList &points, int columns, int rows, bool perspective, int lines, int steps) const;
    //! the same warp on a columns2 x rows2 grid of points
    Q_INVOKABLE QVariantList resample(const QVariantList &points, int columns, int rows, bool perspective, int columns2, int rows2) const;
};
