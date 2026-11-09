#include "warpmath.h"

#include <QVariantMap>
#include <algorithm>
#include <cmath>

namespace warpmath {

Grid fromVariant(const QVariantList &points, int columns, int rows, bool perspective)
{
    Grid g;
    g.columns = columns;
    g.rows = rows;
    g.perspective = perspective;
    g.points.reserve(points.size());
    for (const QVariant &p : points) {
        if (p.canConvert<QVariantMap>() && p.typeId() != QMetaType::QPointF) {
            const QVariantMap m = p.toMap();
            g.points.append(QPointF(m.value("x").toDouble(), m.value("y").toDouble()));
        } else {
            g.points.append(p.toPointF());
        }
    }
    return g;
}

QVariantList toVariant(const QList<QPointF> &points)
{
    QVariantList out;
    out.reserve(points.size());
    for (const QPointF &p : points)
        out.append(QVariantMap{ { "x", p.x() }, { "y", p.y() } });
    return out;
}

QList<QPointF> identity(int columns, int rows)
{
    QList<QPointF> out;
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < columns; ++c)
            out.append(QPointF(qreal(c) / (columns - 1), qreal(r) / (rows - 1)));
    return out;
}

namespace {

// The unit square onto the quad q0 (top left), q1 (top right), q2 (bottom
// right), q3 (bottom left): Heckbert's square-to-quad.
QPointF homography(const QPointF &q0, const QPointF &q1, const QPointF &q2, const QPointF &q3, qreal u, qreal v)
{
    const qreal sx = q0.x() - q1.x() + q2.x() - q3.x();
    const qreal sy = q0.y() - q1.y() + q2.y() - q3.y();
    qreal a, b, c, d, e, f, g = 0, h = 0;
    if (std::abs(sx) < 1e-12 && std::abs(sy) < 1e-12) {
        a = q1.x() - q0.x(); b = q2.x() - q1.x(); c = q0.x();
        d = q1.y() - q0.y(); e = q2.y() - q1.y(); f = q0.y();
    } else {
        const qreal dx1 = q1.x() - q2.x(), dx2 = q3.x() - q2.x();
        const qreal dy1 = q1.y() - q2.y(), dy2 = q3.y() - q2.y();
        const qreal det = dx1 * dy2 - dx2 * dy1;
        if (std::abs(det) < 1e-12) // folded over: fall back to the bilinear stretch
            return (q0 * (1 - u) + q1 * u) * (1 - v) + (q3 * (1 - u) + q2 * u) * v;
        g = (sx * dy2 - dx2 * sy) / det;
        h = (dx1 * sy - sx * dy1) / det;
        a = q1.x() - q0.x() + g * q1.x(); b = q3.x() - q0.x() + h * q3.x(); c = q0.x();
        d = q1.y() - q0.y() + g * q1.y(); e = q3.y() - q0.y() + h * q3.y(); f = q0.y();
    }
    const qreal w = g * u + h * v + 1;
    return QPointF((a * u + b * v + c) / w, (d * u + e * v + f) / w);
}

// Catmull-Rom through p1 and p2, t 0..1 between them.
QPointF catmull(const QPointF &p0, const QPointF &p1, const QPointF &p2, const QPointF &p3, qreal t)
{
    const qreal t2 = t * t, t3 = t2 * t;
    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
}

// The point i of a line of n, the ends carried on straight beyond it.
QPointF along(const QList<QPointF> &line, int i)
{
    const int n = line.size();
    if (i < 0) return 2 * line[0] - line[1];
    if (i >= n) return 2 * line[n - 1] - line[n - 2];
    return line[i];
}

// A line of points, at s 0..1 along it.
QPointF spline(const QList<QPointF> &line, qreal s)
{
    const int n = line.size();
    const qreal x = std::clamp(s, 0.0, 1.0) * (n - 1);
    const int i = std::min(int(x), n - 2);
    const qreal t = x - i;
    if (n == 2) return line[0] * (1 - t) + line[1] * t;
    return catmull(along(line, i - 1), line[i], line[i + 1], along(line, i + 2), t);
}

} // namespace

QPointF map(const Grid &g, qreal u, qreal v)
{
    if (!g.valid()) return QPointF(u, v);
    if (g.columns == 2 && g.rows == 2 && g.perspective)
        return homography(g.at(0, 0), g.at(1, 0), g.at(1, 1), g.at(0, 1), u, v);
    // each row at u, then down the column those make at v
    QList<QPointF> column;
    column.reserve(g.rows);
    QList<QPointF> row;
    row.reserve(g.columns);
    for (int r = 0; r < g.rows; ++r) {
        row.clear();
        for (int c = 0; c < g.columns; ++c) row.append(g.at(c, r));
        column.append(spline(row, u));
    }
    return spline(column, v);
}

QList<QPointF> resample(const Grid &g, int columns, int rows)
{
    QList<QPointF> out;
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < columns; ++c)
            out.append(map(g, qreal(c) / (columns - 1), qreal(r) / (rows - 1)));
    return out;
}

} // namespace warpmath
