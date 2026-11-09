#include "warp.h"
#include "warpmath.h"

using namespace warpmath;

QVariantList Warp::grid(int columns, int rows) const
{
    return toVariant(identity(std::max(2, columns), std::max(2, rows)));
}

QVariantMap Warp::map(const QVariantList &points, int columns, int rows, bool perspective, qreal u, qreal v) const
{
    const QPointF p = warpmath::map(fromVariant(points, columns, rows, perspective), u, v);
    return { { "x", p.x() }, { "y", p.y() } };
}

QVariantList Warp::outline(const QVariantList &points, int columns, int rows, bool perspective, int steps) const
{
    const Grid g = fromVariant(points, columns, rows, perspective);
    steps = std::max(1, steps);
    QList<QPointF> out;
    for (int i = 0; i < steps; ++i) out.append(warpmath::map(g, qreal(i) / steps, 0));
    for (int i = 0; i < steps; ++i) out.append(warpmath::map(g, 1, qreal(i) / steps));
    for (int i = 0; i < steps; ++i) out.append(warpmath::map(g, 1 - qreal(i) / steps, 1));
    for (int i = 0; i < steps; ++i) out.append(warpmath::map(g, 0, 1 - qreal(i) / steps));
    return toVariant(out);
}

QVariantList Warp::lines(const QVariantList &points, int columns, int rows, bool perspective, int lines, int steps) const
{
    const Grid g = fromVariant(points, columns, rows, perspective);
    lines = std::max(2, lines);
    steps = std::max(1, steps);
    QVariantList out;
    for (int k = 0; k < lines; ++k) {
        const qreal a = qreal(k) / (lines - 1);
        QList<QPointF> across, down;
        for (int i = 0; i <= steps; ++i) {
            const qreal t = qreal(i) / steps;
            across.append(warpmath::map(g, t, a));
            down.append(warpmath::map(g, a, t));
        }
        out.append(QVariant(toVariant(across)));
        out.append(QVariant(toVariant(down)));
    }
    return out;
}

QVariantList Warp::resample(const QVariantList &points, int columns, int rows, bool perspective, int columns2, int rows2) const
{
    return toVariant(warpmath::resample(fromVariant(points, columns, rows, perspective), std::max(2, columns2), std::max(2, rows2)));
}
