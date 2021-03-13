import 'dart:math';
import 'dart:typed_data';

import 'package:flare_flutter/base/math/transform_components.dart';
import 'package:flare_flutter/base/math/vec2d.dart';

class Mat2D {
  final Float32List _buffer;

  Mat2D() : _buffer = Float32List.fromList([1.0, 0.0, 0.0, 1.0, 0.0, 0.0]);

  Mat2D.clone(Mat2D copy) : _buffer = Float32List.fromList(copy.values);

  Float64List get mat4 {
    return Float64List.fromList([
      _buffer[0],
      _buffer[1],
      0.0,
      0.0,
      _buffer[2],
      _buffer[3],
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      _buffer[4],
      _buffer[5],
      0.0,
      1.0
    ]);
  }

  Float32List get values {
    return _buffer;
  }

  double operator [](int index) {
    return _buffer[index];
  }

  void operator []=(int index, double value) {
    _buffer[index] = value;
  }

  @override
  String toString() {
    return _buffer.toString();
  }

  static bool areEqual(Mat2D a, Mat2D b) {
    return a[0] == b[0] &&
        a[1] == b[1] &&
        a[2] == b[2] &&
        a[3] == b[3] &&
        a[4] == b[4] &&
        a[5] == b[5];
  }

  static void cCopy(Mat2D o, Mat2D a) {
    o[0] = a[0];
    o[1] = a[1];
    o[2] = a[2];
    o[3] = a[3];
    o[4] = a[4];
    o[5] = a[5];
  }

  static void compose(Mat2D m, TransformComponents result) {
    double r = result[4];

    if (r != 0.0) {
      Mat2D.fromRotation(m, r);
    } else {
      Mat2D.identity(m);
    }
    m[4] = result[0];
    m[5] = result[1];
    Mat2D.scale(m, m, result.scale);

    double sk = result[5];
    if (sk != 0.0) {
      m[2] = m[0] * sk + m[2];
      m[3] = m[1] * sk + m[3];
    }
  }

  static void copy(Mat2D o, Mat2D f) {
    o[0] = f[0];
    o[1] = f[1];
    o[2] = f[2];
    o[3] = f[3];
    o[4] = f[4];
    o[5] = f[5];
  }

  static void copyFromList(Mat2D o, Float32List f) {
    o[0] = f[0];
    o[1] = f[1];
    o[2] = f[2];
    o[3] = f[3];
    o[4] = f[4];
    o[5] = f[5];
  }

  static void decompose(Mat2D m, TransformComponents result) {
    double m0 = m[0], m1 = m[1], m2 = m[2], m3 = m[3];

    double rotation = atan2(m1, m0);
    double denom = m0 * m0 + m1 * m1;
    double scaleX = sqrt(denom);
    double scaleY = (scaleX == 0) ? 0 : ((m0 * m3 - m2 * m1) / scaleX);
    double skewX = atan2(m0 * m2 + m1 * m3, denom);

    result[0] = m[4];
    result[1] = m[5];
    result[2] = scaleX;
    result[3] = scaleY;
    result[4] = rotation;
    result[5] = skewX;
  }

  static void fromRotation(Mat2D o, double rad) {
    double s = sin(rad);
    double c = cos(rad);
    o[0] = c;
    o[1] = s;
    o[2] = -s;
    o[3] = c;
    o[4] = 0.0;
    o[5] = 0.0;
  }

  static void getScale(Mat2D m, Vec2D s) {
    double x = m[0];
    double y = m[1];
    s[0] = x.sign * sqrt(x * x + y * y);

    x = m[2];
    y = m[3];
    s[1] = y.sign * sqrt(x * x + y * y);
  }

  static void identity(Mat2D mat) {
    mat[0] = 1.0;
    mat[1] = 0.0;
    mat[2] = 0.0;
    mat[3] = 1.0;
    mat[4] = 0.0;
    mat[5] = 0.0;
  }

  static bool invert(Mat2D o, Mat2D a) {
    double aa = a[0], ab = a[1], ac = a[2], ad = a[3], atx = a[4], aty = a[5];

    double det = aa * ad - ab * ac;
    if (det == 0.0) {
      return false;
    }
    det = 1.0 / det;

    o[0] = ad * det;
    o[1] = -ab * det;
    o[2] = -ac * det;
    o[3] = aa * det;
    o[4] = (ac * aty - ad * atx) * det;
    o[5] = (ab * atx - aa * aty) * det;
    return true;
  }

  static void multiply(Mat2D o, Mat2D a, Mat2D b) {
    double a0 = a[0],
        a1 = a[1],
        a2 = a[2],
        a3 = a[3],
        a4 = a[4],
        a5 = a[5],
        b0 = b[0],
        b1 = b[1],
        b2 = b[2],
        b3 = b[3],
        b4 = b[4],
        b5 = b[5];
    o[0] = a0 * b0 + a2 * b1;
    o[1] = a1 * b0 + a3 * b1;
    o[2] = a0 * b2 + a2 * b3;
    o[3] = a1 * b2 + a3 * b3;
    o[4] = a0 * b4 + a2 * b5 + a4;
    o[5] = a1 * b4 + a3 * b5 + a5;
  }

  static void scale(Mat2D o, Mat2D a, Vec2D v) {
    double a0 = a[0],
        a1 = a[1],
        a2 = a[2],
        a3 = a[3],
        a4 = a[4],
        a5 = a[5],
        v0 = v[0],
        v1 = v[1];
    o[0] = a0 * v0;
    o[1] = a1 * v0;
    o[2] = a2 * v1;
    o[3] = a3 * v1;
    o[4] = a4;
    o[5] = a5;
  }
}
