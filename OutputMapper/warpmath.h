#pragma once

#include <QPointF>
#include <QVariantList>
#include <QList>

// The warp of a slice: a grid of control points (columns x rows, row by row
// from the top left), each where that spot of the slice's input lands on its
// output, normalised to the output (0..1 across, 0..1 down; outside is fine).
//
//  - 2 x 2 with `perspective`: a true corner pin (a homography), so a flat
//    rectangle seen at an angle stays straight-edged and evenly spaced.
//  - otherwise a smooth surface through every point (Catmull-Rom, its ends
//    carried on straight): 2 x 2 is then a plain bilinear stretch, 3 x 3 and
//    up bend the slice to a bowed or uneven screen.
namespace warpmath {

struct Grid {
    int columns = 2;
    int rows = 2;
    bool perspective = true;
    QList<QPointF> points; // columns * rows

    bool valid() const { return columns >= 2 && rows >= 2 && points.size() == columns * rows; }
    QPointF at(int c, int r) const { return points[r * columns + c]; }
};

//! from QML: a list of {x, y} objects (or points)
Grid fromVariant(const QVariantList &points, int columns, int rows, bool perspective);
QVariantList toVariant(const QList<QPointF> &points);

//! the identity grid: every point where it is in the input
QList<QPointF> identity(int columns, int rows);

//! where (u, v) of the input (each 0..1) lands
QPointF map(const Grid &g, qreal u, qreal v);

//! the grid's points again, as a columns x rows grid laid over the same warp
QList<QPointF> resample(const Grid &g, int columns, int rows);

} // namespace warpmath
