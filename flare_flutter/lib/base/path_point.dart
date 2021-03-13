import 'dart:collection';
import 'dart:typed_data';

import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/stream_reader.dart';

HashMap<int, PointType> pointTypeLookup =
    HashMap<int, PointType>.fromIterables([
  0,
  1,
  2,
  3
], [
  PointType.straight,
  PointType.mirror,
  PointType.disconnected,
  PointType.asymmetric
]);

class CubicPathPoint extends PathPoint {
  Vec2D _in = Vec2D();
  Vec2D _out = Vec2D();

  CubicPathPoint(PointType type) : super(type);

  CubicPathPoint.fromValues(Vec2D translation, Vec2D inPoint, Vec2D outPoint)
      : super(PointType.disconnected) {
    _translation = translation;
    _in = inPoint;
    _out = outPoint;
  }

  Vec2D get inPoint {
    return _in;
  }

  Vec2D get outPoint {
    return _out;
  }

  void copyCubic(CubicPathPoint from) {
    super.copy(from);
    Vec2D.copy(_in, from._in);
    Vec2D.copy(_out, from._out);
  }

  @override
  PathPoint makeInstance() {
    CubicPathPoint node = CubicPathPoint(_type);
    node.copyCubic(this);
    return node;
  }

  @override
  int readPoint(StreamReader reader, bool isConnectedToBones) {
    Vec2D.copyFromList(_in, reader.readFloat32Array(2, 'in'));
    Vec2D.copyFromList(_out, reader.readFloat32Array(2, 'out'));
    if (isConnectedToBones) {
      return 24;
    }
    return 0;
  }

  @override
  PathPoint skin(Mat2D world, Float32List? bones) {
    CubicPathPoint point = CubicPathPoint(pointType);

    double px =
        world[0] * translation[0] + world[2] * translation[1] + world[4];
    double py =
        world[1] * translation[0] + world[3] * translation[1] + world[5];

    {
      double a = 0.0, b = 0.0, c = 0.0, d = 0.0, e = 0.0, f = 0.0;

      for (int i = 0; i < 4; i++) {
        int boneIndex = _weights![i].floor();
        double weight = _weights![i + 4];
        if (weight > 0) {
          int bb = boneIndex * 6;

          a += bones![bb] * weight;
          b += bones[bb + 1] * weight;
          c += bones[bb + 2] * weight;
          d += bones[bb + 3] * weight;
          e += bones[bb + 4] * weight;
          f += bones[bb + 5] * weight;
        }
      }

      Vec2D pos = point.translation;
      pos[0] = a * px + c * py + e;
      pos[1] = b * px + d * py + f;
    }

    {
      double a = 0.0, b = 0.0, c = 0.0, d = 0.0, e = 0.0, f = 0.0;
      px = world[0] * _in[0] + world[2] * _in[1] + world[4];
      py = world[1] * _in[0] + world[3] * _in[1] + world[5];

      for (int i = 8; i < 12; i++) {
        int boneIndex = _weights![i].floor();
        double weight = _weights![i + 4];
        if (weight > 0) {
          int bb = boneIndex * 6;

          a += bones![bb] * weight;
          b += bones[bb + 1] * weight;
          c += bones[bb + 2] * weight;
          d += bones[bb + 3] * weight;
          e += bones[bb + 4] * weight;
          f += bones[bb + 5] * weight;
        }
      }

      Vec2D pos = point.inPoint;
      pos[0] = a * px + c * py + e;
      pos[1] = b * px + d * py + f;
    }

    {
      double a = 0.0, b = 0.0, c = 0.0, d = 0.0, e = 0.0, f = 0.0;
      px = world[0] * _out[0] + world[2] * _out[1] + world[4];
      py = world[1] * _out[0] + world[3] * _out[1] + world[5];

      for (int i = 16; i < 20; i++) {
        int boneIndex = _weights![i].floor();
        double weight = _weights![i + 4];
        if (weight > 0) {
          int bb = boneIndex * 6;

          a += bones![bb] * weight;
          b += bones[bb + 1] * weight;
          c += bones[bb + 2] * weight;
          d += bones[bb + 3] * weight;
          e += bones[bb + 4] * weight;
          f += bones[bb + 5] * weight;
        }
      }

      Vec2D pos = point.outPoint;
      pos[0] = a * px + c * py + e;
      pos[1] = b * px + d * py + f;
    }

    return point;
  }

  @override
  PathPoint transformed(Mat2D transform) {
    CubicPathPoint result = super.transformed(transform) as CubicPathPoint;
    Vec2D.transformMat2D(result.inPoint, result.inPoint, transform);
    Vec2D.transformMat2D(result.outPoint, result.outPoint, transform);
    return result;
  }
}

abstract class PathPoint {
  PointType _type;
  Vec2D _translation = Vec2D();
  Float32List? _weights;

  PathPoint(PointType type) : _type = type;

  PointType get pointType {
    return _type;
  }

  Vec2D get translation {
    return _translation;
  }

  void copy(PathPoint from) {
    _type = from._type;
    Vec2D.copy(_translation, from._translation);
    if (from._weights != null) {
      _weights = Float32List.fromList(from._weights!);
    }
  }

  PathPoint makeInstance();

  void read(StreamReader reader, bool isConnectedToBones) {
    Vec2D.copyFromList(_translation, reader.readFloat32Array(2, 'translation'));

    int weightLength = readPoint(reader, isConnectedToBones);
    if (weightLength != 0) {
      _weights = reader.readFloat32Array(weightLength, 'weights');
    }
  }

  int readPoint(StreamReader reader, bool isConnectedToBones);

  PathPoint skin(Mat2D world, Float32List? bones);

  PathPoint transformed(Mat2D transform) {
    PathPoint result = makeInstance();
    Vec2D.transformMat2D(result.translation, result.translation, transform);
    return result;
  }
}

enum PointType { straight, mirror, disconnected, asymmetric }

class StraightPathPoint extends PathPoint {
  double radius = 0.0;

  StraightPathPoint() : super(PointType.straight);

  StraightPathPoint.fromTranslation(Vec2D translation)
      : super(PointType.straight) {
    _translation = translation;
  }

  StraightPathPoint.fromValues(Vec2D translation, this.radius)
      : super(PointType.straight) {
    _translation = translation;
  }

  void copyStraight(StraightPathPoint from) {
    super.copy(from);
    radius = from.radius;
  }

  @override
  PathPoint makeInstance() {
    StraightPathPoint node = StraightPathPoint();
    node.copyStraight(this);
    return node;
  }

  @override
  int readPoint(StreamReader reader, bool isConnectedToBones) {
    radius = reader.readFloat32('radius');
    if (isConnectedToBones) {
      return 8;
    }
    return 0;
  }

  @override
  PathPoint skin(Mat2D world, Float32List? bones) {
    StraightPathPoint point = StraightPathPoint()..radius = radius;

    double px =
        world[0] * translation[0] + world[2] * translation[1] + world[4];
    double py =
        world[1] * translation[0] + world[3] * translation[1] + world[5];

    double a = 0.0, b = 0.0, c = 0.0, d = 0.0, e = 0.0, f = 0.0;

    for (int i = 0; i < 4; i++) {
      int boneIndex = _weights![i].floor();
      double weight = _weights![i + 4];
      if (weight > 0) {
        int bb = boneIndex * 6;

        a += bones![bb] * weight;
        b += bones[bb + 1] * weight;
        c += bones[bb + 2] * weight;
        d += bones[bb + 3] * weight;
        e += bones[bb + 4] * weight;
        f += bones[bb + 5] * weight;
      }
    }

    Vec2D pos = point.translation;
    pos[0] = a * px + c * py + e;
    pos[1] = b * px + d * py + f;

    return point;
  }
}
