// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A cubic polynomial mapping of the unit interval.
///
/// The [Cubic] class implements third-order Bézier curves.
class Cubic {
  /// Creates a cubic curve.
  ///
  /// The [a], [b], [c], and [d] arguments must not be null.
  const Cubic(this.a, this.b, this.c, this.d)
      : assert(a != null),
        assert(b != null),
        assert(c != null),
        assert(d != null);

  /// The x coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  final double a;

  /// The y coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  final double b;

  /// The x coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  final double c;

  /// The y coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  final double d;

  static const double _cubicErrorBound = 0.001;

  double _evaluateCubic(double a, double b, double m) {
    return 3 * a * (1 - m) * (1 - m) * m +
           3 * b * (1 - m) *           m * m +
                                       m * m * m;
  }

  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    double start = 0.0;
    double end = 1.0;
    while (true) {
      final double midpoint = (start + end) / 2;
      final double estimate = _evaluateCubic(a, c, midpoint);
      if ((t - estimate).abs() < _cubicErrorBound)
        return _evaluateCubic(b, d, midpoint);
      if (estimate < t)
        start = midpoint;
      else
        end = midpoint;
    }
  }

  @override
  String toString() {
    return '$runtimeType(${a.toStringAsFixed(2)}, ${b.toStringAsFixed(2)}, ${c.toStringAsFixed(2)}, ${d.toStringAsFixed(2)})';
  }
}