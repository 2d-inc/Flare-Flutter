import 'dart:math';
import 'dart:typed_data';

import 'package:flare_flutter/base/math/vec2d.dart';

class AABB {
  final Float32List _buffer;

  AABB() : _buffer = Float32List.fromList([0.0, 0.0, 0.0, 0.0]);

  AABB.clone(AABB a) : _buffer = Float32List.fromList(a.values);

  AABB.fromValues(double a, double b, double c, double d)
      : _buffer = Float32List.fromList([a, b, c, d]);

  Vec2D get maximum {
    return Vec2D.fromValues(_buffer[2], _buffer[3]);
  }

  Vec2D get minimum {
    return Vec2D.fromValues(_buffer[0], _buffer[1]);
  }

  Float32List get values {
    return _buffer;
  }

  double operator [](int idx) {
    return _buffer[idx];
  }

  void operator []=(int idx, double v) {
    _buffer[idx] = v;
  }

  @override
  String toString() {
    return _buffer.toString();
  }

  static Vec2D center(Vec2D out, AABB a) {
    out[0] = (a[0] + a[2]) * 0.5;
    out[1] = (a[1] + a[3]) * 0.5;
    return out;
  }

  static AABB combine(AABB out, AABB a, AABB b) {
    out[0] = min(a[0], b[0]);
    out[1] = min(a[1], b[1]);
    out[2] = max(a[2], b[2]);
    out[3] = max(a[3], b[3]);
    return out;
  }

  static bool contains(AABB a, AABB b) {
    return a[0] <= b[0] && a[1] <= b[1] && b[2] <= a[2] && b[3] <= a[3];
  }

  static AABB copy(AABB out, AABB a) {
    out[0] = a[0];
    out[1] = a[1];
    out[2] = a[2];
    out[3] = a[3];
    return out;
  }

  static Vec2D extents(Vec2D out, AABB a) {
    out[0] = (a[2] - a[0]) * 0.5;
    out[1] = (a[3] - a[1]) * 0.5;
    return out;
  }

  static bool isValid(AABB a) {
    double dx = a[2] - a[0];
    double dy = a[3] - a[1];
    return dx >= 0 &&
        dy >= 0 &&
        a[0] <= double.maxFinite &&
        a[1] <= double.maxFinite &&
        a[2] <= double.maxFinite &&
        a[3] <= double.maxFinite;
  }

  static double perimeter(AABB a) {
    double wx = a[2] - a[0];
    double wy = a[3] - a[1];
    return 2.0 * (wx + wy);
  }

  static Vec2D size(Vec2D out, AABB a) {
    out[0] = a[2] - a[0];
    out[1] = a[3] - a[1];
    return out;
  }

  static bool testOverlap(AABB a, AABB b) {
    double d1x = b[0] - a[2];
    double d1y = b[1] - a[3];

    double d2x = a[0] - b[2];
    double d2y = a[1] - b[3];

    if (d1x > 0.0 || d1y > 0.0) {
      return false;
    }

    if (d2x > 0.0 || d2y > 0.0) {
      return false;
    }

    return true;
  }
}
