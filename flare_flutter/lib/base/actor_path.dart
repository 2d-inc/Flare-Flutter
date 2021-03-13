import 'dart:typed_data';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_shape.dart';
import 'package:flare_flutter/base/actor_skinnable.dart';
import 'package:flare_flutter/base/math/aabb.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/path_point.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class ActorBasePath {
  ActorShape? _shape;
  bool _isRootPath = false;
  List<List<ActorClip>?> get allClips;
  List<PathPoint> get deformedPoints => points;
  bool get isPathInWorldSpace => false;
  bool get isRootPath => _isRootPath;
  ActorNode? get parent;
  Mat2D get pathTransform;
  List<PathPoint> get points;
  ActorShape? get shape => _shape;
  Mat2D get transform;
  Mat2D get worldTransform;
  void completeResolve() {
    updateShape();
  }

  AABB getPathAABB() {
    double minX = double.maxFinite;
    double minY = double.maxFinite;
    double maxX = -double.maxFinite;
    double maxY = -double.maxFinite;

    AABB obb = getPathOBB();

    List<Vec2D> pts = [
      Vec2D.fromValues(obb[0], obb[1]),
      Vec2D.fromValues(obb[2], obb[1]),
      Vec2D.fromValues(obb[2], obb[3]),
      Vec2D.fromValues(obb[0], obb[3])
    ];

    Mat2D localTransform;
    if (isPathInWorldSpace) {
      //  convert the path coordinates into local parent space.
      localTransform = Mat2D();
      Mat2D.invert(localTransform, parent!.worldTransform);
    } else if (!_isRootPath) {
      localTransform = Mat2D();
      // Path isn't root, so get transform in shape space.
      if (Mat2D.invert(localTransform, shape!.worldTransform)) {
        Mat2D.multiply(localTransform, localTransform, worldTransform);
      }
    } else {
      localTransform = transform;
    }

    for (final Vec2D p in pts) {
      Vec2D wp = Vec2D.transformMat2D(p, p, localTransform);
      if (wp[0] < minX) {
        minX = wp[0];
      }
      if (wp[1] < minY) {
        minY = wp[1];
      }

      if (wp[0] > maxX) {
        maxX = wp[0];
      }
      if (wp[1] > maxY) {
        maxY = wp[1];
      }
    }
    return AABB.fromValues(minX, minY, maxX, maxY);
  }

  AABB getPathOBB() {
    double minX = double.maxFinite;
    double minY = double.maxFinite;
    double maxX = -double.maxFinite;
    double maxY = -double.maxFinite;

    List<PathPoint> renderPoints = points;
    for (final PathPoint point in renderPoints) {
      Vec2D t = point.translation;
      double x = t[0];
      double y = t[1];
      if (x < minX) {
        minX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y > maxY) {
        maxY = y;
      }

      if (point is CubicPathPoint) {
        Vec2D t = point.inPoint;
        x = t[0];
        y = t[1];
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y > maxY) {
          maxY = y;
        }

        t = point.outPoint;
        x = t[0];
        y = t[1];
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y > maxY) {
          maxY = y;
        }
      }
    }

    return AABB.fromValues(minX, minY, maxX, maxY);
  }

  void invalidateDrawable() {
    invalidatePath();
    if (shape != null) {
      shape!.invalidateShape();
    }
  }

  void invalidatePath();

  void updateShape() {
    if (_shape != null) {
      _shape!.removePath(this);
    }
    ActorNode? possibleShape = parent;
    while (possibleShape != null && possibleShape is! ActorShape) {
      possibleShape = possibleShape.parent;
    }
    if (possibleShape != null) {
      _shape = possibleShape as ActorShape;
      _shape!.addPath(this);
    } else {
      _shape = null;
    }
    _isRootPath = _shape == parent;
  }
}

class ActorPath extends ActorNode with ActorSkinnable, ActorBasePath {
  static const int vertexDeformDirty = 1 << 1;
  late bool _isHidden;
  late bool _isClosed;
  late List<PathPoint> _points;

  Float32List? vertexDeform;

  @override
  List<PathPoint> get deformedPoints {
    if (!isConnectedToBones || skin == null) {
      return _points;
    }

    Float32List? boneMatrices = skin!.boneMatrices;
    List<PathPoint> deformed = <PathPoint>[];
    for (final PathPoint point in _points) {
      deformed.add(point.skin(worldTransform, boneMatrices));
    }
    return deformed;
  }

  bool get isClosed {
    return _isClosed;
  }

  @override
  bool get isPathInWorldSpace => isConnectedToBones;

  @override
  Mat2D get pathTransform => isConnectedToBones ? Mat2D() : worldTransform;

  @override
  List<PathPoint> get points => _points;

  void copyPath(ActorPath node, ActorArtboard resetArtboard) {
    copyNode(node, resetArtboard);
    copySkinnable(node, resetArtboard);
    _isHidden = node._isHidden;
    _isClosed = node._isClosed;

    int pointCount = node._points.length;

    _points = <PathPoint>[];
    for (int i = 0; i < pointCount; i++) {
      _points.add(node._points[i].makeInstance());
    }

    if (node.vertexDeform != null) {
      vertexDeform = Float32List.fromList(node.vertexDeform!);
    }
  }

  @override
  void invalidatePath() {
    // Up to the implementation.
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorPath instanceEvent = ActorPath();
    instanceEvent.copyPath(this, resetArtboard);
    return instanceEvent;
  }

  void makeVertexDeform() {
    if (vertexDeform != null) {
      return;
    }
    int length = points.fold<int>(0, (int previous, PathPoint point) {
      return previous + 2 + (point.pointType == PointType.straight ? 1 : 4);
    });
    Float32List vertices = Float32List(length);
    int readIdx = 0;
    for (final PathPoint point in points) {
      vertices[readIdx++] = point.translation[0];
      vertices[readIdx++] = point.translation[1];
      if (point.pointType == PointType.straight) {
        // radius
        vertices[readIdx++] = (point as StraightPathPoint).radius;
      } else {
        // in/out
        CubicPathPoint cubicPoint = point as CubicPathPoint;
        vertices[readIdx++] = cubicPoint.inPoint[0];
        vertices[readIdx++] = cubicPoint.inPoint[1];
        vertices[readIdx++] = cubicPoint.outPoint[0];
        vertices[readIdx++] = cubicPoint.outPoint[1];
      }
    }
    vertexDeform = vertices;
  }

  void markVertexDeformDirty() =>
      artboard.addDirt(this, vertexDeformDirty, false);

  @override
  void onDirty(int dirt) {
    super.onDirty(dirt);
    // We transformed, make sure parent is invalidated.
    if (shape != null) {
      shape!.invalidateShape();
    }
  }

  @override
  void resolveComponentIndices(List<ActorComponent?> components) {
    super.resolveComponentIndices(components);
    resolveSkinnable(components);
  }

  @override
  void update(int dirt) {
    if (vertexDeform != null &&
        (dirt & vertexDeformDirty) == vertexDeformDirty) {
      int readIdx = 0;
      for (final PathPoint point in _points) {
        point.translation[0] = vertexDeform![readIdx++];
        point.translation[1] = vertexDeform![readIdx++];
        switch (point.pointType) {
          case PointType.straight:
            (point as StraightPathPoint).radius = vertexDeform![readIdx++];
            break;

          default:
            CubicPathPoint cubicPoint = point as CubicPathPoint;
            cubicPoint.inPoint[0] = vertexDeform![readIdx++];
            cubicPoint.inPoint[1] = vertexDeform![readIdx++];
            cubicPoint.outPoint[0] = vertexDeform![readIdx++];
            cubicPoint.outPoint[1] = vertexDeform![readIdx++];
            break;
        }
      }
    }
    invalidateDrawable();

    super.update(dirt);
  }

  static ActorPath read(
      ActorArtboard artboard, StreamReader reader, ActorPath component) {
    ActorNode.read(artboard, reader, component);
    ActorSkinnable.read(artboard, reader, component);

    component._isHidden = !reader.readBool('isVisible');
    component._isClosed = reader.readBool('isClosed');

    reader.openArray('points');
    int pointCount = reader.readUint16Length();
    component._points = <PathPoint>[];
    for (int i = 0; i < pointCount; i++) {
      reader.openObject('point');
      PathPoint point;
      PointType? type = pointTypeLookup[reader.readUint8('pointType')];
      switch (type) {
        case PointType.straight:
          {
            point = StraightPathPoint();
            break;
          }
        default:
          {
            point = CubicPathPoint(type!);
            break;
          }
      }

      point.read(reader, component.isConnectedToBones);

      reader.closeObject();
      component._points.add(point);
    }
    reader.closeArray();
    return component;
  }
}

abstract class ActorProceduralPath extends ActorNode with ActorBasePath {
  double? _width;
  double? _height;

  double get height => _height!;
  set height(double w) {
    if (w != _height) {
      _height = w;
      invalidateDrawable();
    }
  }

  @override
  Mat2D get pathTransform => worldTransform;

  double get width => _width!;

  set width(double w) {
    if (w != _width) {
      _width = w;
      invalidateDrawable();
    }
  }

  void copyPath(ActorProceduralPath node, ActorArtboard resetArtboard) {
    copyNode(node, resetArtboard);
    _width = node.width;
    _height = node.height;
  }

  @override
  void onDirty(int dirt) {
    super.onDirty(dirt);
    // We transformed, make sure parent is invalidated.
    if (shape != null) {
      shape!.invalidateShape();
    }
  }
}
