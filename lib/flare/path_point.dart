import "dart:typed_data";
import "math/vec2d.dart";
import "dart:collection";
import "stream_reader.dart";
import "math/mat2d.dart";

enum PointType {
  Straight,
  Mirror,
  Disconnected,
  Asymmetric
}

HashMap<int, PointType> pointTypeLookup = new HashMap<int,
    PointType>.fromIterables([0, 1, 2, 3], [
  PointType.Straight,
  PointType.Mirror,
  PointType.Disconnected,
  PointType.Asymmetric
]);

abstract class PathPoint {
  PointType _type;
  Vec2D _translation = new Vec2D();
  Float32List _weights;

  PathPoint(PointType type) {
    _type = type;
  }

  PointType get pointType {
    return _type;
  }

  Vec2D get translation {
    return _translation;
  }

  PathPoint makeInstance();

  copy(PathPoint from) {
    this._type = from._type;
    Vec2D.copy(_translation, from._translation);
    if (from._weights != null) {
      _weights = new Float32List.fromList(from._weights);
    }
  }

  void read(StreamReader reader, bool isConnectedToBones) {
    reader.readFloat32ArrayOffset(_translation.values, 2, 0, "translation");
    readPoint(reader, isConnectedToBones);
    if (_weights != null) {
      reader.readFloat32Array(_weights, "weights");
    }
  }

  void readPoint(StreamReader reader, bool isConnectedToBones);

  PathPoint transformed(Mat2D transform) {
    PathPoint result = makeInstance();
    Vec2D.transformMat2D(result.translation, result.translation, transform);
    return result;
  }

  PathPoint skin(Mat2D world, Float32List bones);
}

class StraightPathPoint extends PathPoint {
  double radius = 0.0;

  StraightPathPoint() : super(PointType.Straight);

  StraightPathPoint.fromTranslation(Vec2D translation)
      : super(PointType.Straight)
  {
    this._translation = translation;
  }

  StraightPathPoint.fromValues(Vec2D translation, double r)
      : super(PointType.Straight)
  {
    _translation = translation;
    radius = r;
  }

  PathPoint makeInstance() {
    StraightPathPoint node = new StraightPathPoint();
    node.copyStraight(this);
    return node;
  }

  copyStraight(StraightPathPoint from) {
    super.copy(from);
    radius = from.radius;
  }

  void readPoint(StreamReader reader, bool isConnectedToBones) {
    radius = reader.readFloat32("radius");
    if (isConnectedToBones) {
      _weights = new Float32List(8);
    }
  }

  @override
  PathPoint skin(Mat2D world, Float32List bones) {
    StraightPathPoint point = new StraightPathPoint()
      ..radius = radius;

    double px = world[0] * translation[0] + world[2] * translation[1] +
        world[4];
    double py = world[1] * translation[0] + world[3] * translation[1] +
        world[5];

    double a = 0.0,
        b = 0.0,
        c = 0.0,
        d = 0.0,
        e = 0.0,
        f = 0.0;

    for (int i = 0; i < 4; i++) {
      int boneIndex = _weights[i].floor();
      double weight = _weights[i + 4];
      if (weight > 0) {
        int bb = boneIndex * 6;

        a += bones[bb] * weight;
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

class CubicPathPoint extends PathPoint {
  Vec2D _in = new Vec2D();
  Vec2D _out = new Vec2D();

  CubicPathPoint(PointType type) : super(type);

  Vec2D get inPoint {
    return _in;
  }

  Vec2D get outPoint {
    return _out;
  }

  CubicPathPoint.fromValues(Vec2D translation, Vec2D inPoint, Vec2D outPoint)
      : super(PointType.Disconnected)
  {
    _translation = translation;
    _in = inPoint;
    _out = outPoint;
  }

  PathPoint makeInstance() {
    CubicPathPoint node = new CubicPathPoint(_type);
    node.copyCubic(this);
    return node;
  }

  copyCubic(from) {
    super.copy(from);
    Vec2D.copy(_in, from._in);
    Vec2D.copy(_out, from._out);
  }

  void readPoint(StreamReader reader, bool isConnectedToBones) {
    reader.readFloat32ArrayOffset(_in.values, 2, 0, "in");
    reader.readFloat32ArrayOffset(_out.values, 2, 0, "out");
    if (isConnectedToBones) {
      _weights = new Float32List(24);
    }
  }

  PathPoint transformed(Mat2D transform) {
    CubicPathPoint result = super.transformed(transform) as CubicPathPoint;
    Vec2D.transformMat2D(result.inPoint, result.inPoint, transform);
    Vec2D.transformMat2D(result.outPoint, result.outPoint, transform);
    return result;
  }

  @override
  PathPoint skin(Mat2D world, Float32List bones) {
    CubicPathPoint point = new CubicPathPoint(pointType);

    double px = world[0] * translation[0] + world[2] * translation[1] +
        world[4];
    double py = world[1] * translation[0] + world[3] * translation[1] +
        world[5];

    {
      double a = 0.0,
          b = 0.0,
          c = 0.0,
          d = 0.0,
          e = 0.0,
          f = 0.0;

      for (int i = 0; i < 4; i++) {
        int boneIndex = _weights[i].floor();
        double weight = _weights[i + 4];
        if (weight > 0) {
          int bb = boneIndex * 6;

          a += bones[bb] * weight;
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
      double a = 0.0,
          b = 0.0,
          c = 0.0,
          d = 0.0,
          e = 0.0,
          f = 0.0;
      px = world[0] * _in[0] + world[2] * _in[1] + world[4];
      py = world[1] * _in[0] + world[3] * _in[1] + world[5];

      for (int i = 8; i < 12; i++) {
        int boneIndex = _weights[i].floor();
        double weight = _weights[i + 4];
        if (weight > 0) {
          int bb = boneIndex * 6;

          a += bones[bb] * weight;
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
      double a = 0.0,
          b = 0.0,
          c = 0.0,
          d = 0.0,
          e = 0.0,
          f = 0.0;
      px = world[0] * _out[0] + world[2] * _out[1] + world[4];
      py = world[1] * _out[0] + world[3] * _out[1] + world[5];

      for (int i = 16; i < 20; i++) {
        int boneIndex = _weights[i].floor();
        double weight = _weights[i + 4];
        if (weight > 0) {
          int bb = boneIndex * 6;

          a += bones[bb] * weight;
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
}