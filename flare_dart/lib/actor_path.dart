import "dart:typed_data";
import "actor_artboard.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor_shape.dart";
import "actor_skinnable.dart";
import "math/aabb.dart";
import "math/mat2d.dart";
import "math/vec2d.dart";
import "path_point.dart";
import "stream_reader.dart";

abstract class ActorBasePath {
  ActorShape _shape;
  ActorShape get shape => _shape;
  bool _isRootPath = false;
  bool get isRootPath => _isRootPath;
  List<PathPoint> get points;
  ActorNode get parent;
  void invalidatePath();
  bool get isPathInWorldSpace => false;
  Mat2D get pathTransform;
  Mat2D get transform;
  Mat2D get worldTransform;
  List<List<ActorClip>> get allClips;
  List<PathPoint> get deformedPoints => points;

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
      Mat2D.invert(localTransform, parent.worldTransform);
    } else if (!_isRootPath) {
      localTransform = Mat2D();
      // Path isn't root, so get transform in shape space.
      if (Mat2D.invert(localTransform, shape.worldTransform)) {
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

  void invalidateDrawable() {
    invalidatePath();
    if (shape != null) {
      shape.invalidateShape();
    }
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

  void updateShape() {
    if (_shape != null) {
      _shape.removePath(this);
    }
    ActorNode possibleShape = parent;
    while (possibleShape != null && possibleShape is! ActorShape) {
      possibleShape = possibleShape.parent;
    }
    if (possibleShape != null) {
      _shape = possibleShape as ActorShape;
      _shape.addPath(this);
    } else {
      _shape = null;
    }
    _isRootPath = _shape == parent;
  }

  void completeResolve() {
    updateShape();
  }
}

abstract class ActorProceduralPath extends ActorNode with ActorBasePath {
  double _width;
  double _height;

  double get width => _width;
  double get height => _height;

  @override
  Mat2D get pathTransform => worldTransform;

  set width(double w) {
    if (w != _width) {
      _width = w;
      invalidateDrawable();
    }
  }

  set height(double w) {
    if (w != _height) {
      _height = w;
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
      shape.invalidateShape();
    }
  }
}

class ActorPath extends ActorNode with ActorSkinnable, ActorBasePath {
  bool _isHidden;
  bool _isClosed;
  List<PathPoint> _points;
  Float32List vertexDeform;

  @override
  bool get isPathInWorldSpace => isConnectedToBones;

  @override
  void invalidatePath() {
    // Up to the implementation.
  }

  @override
  Mat2D get pathTransform => isConnectedToBones ? Mat2D() : worldTransform;

  static const int vertexDeformDirty = 1 << 1;

  @override
  List<PathPoint> get points => _points;

  @override
  List<PathPoint> get deformedPoints {
    if (!isConnectedToBones || skin == null) {
      return _points;
    }

    Float32List boneMatrices = skin.boneMatrices;
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
  void onDirty(int dirt) {
    super.onDirty(dirt);
    // We transformed, make sure parent is invalidated.
    if (shape != null) {
      shape.invalidateShape();
    }
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

  void markVertexDeformDirty() {
    if (artboard == null) {
      return;
    }
    artboard.addDirt(this, vertexDeformDirty, false);
  }

  @override
  void update(int dirt) {
    if (vertexDeform != null &&
        (dirt & vertexDeformDirty) == vertexDeformDirty) {
      int readIdx = 0;
      for (final PathPoint point in _points) {
        point.translation[0] = vertexDeform[readIdx++];
        point.translation[1] = vertexDeform[readIdx++];
        switch (point.pointType) {
          case PointType.straight:
            (point as StraightPathPoint).radius = vertexDeform[readIdx++];
            break;

          default:
            CubicPathPoint cubicPoint = point as CubicPathPoint;
            cubicPoint.inPoint[0] = vertexDeform[readIdx++];
            cubicPoint.inPoint[1] = vertexDeform[readIdx++];
            cubicPoint.outPoint[0] = vertexDeform[readIdx++];
            cubicPoint.outPoint[1] = vertexDeform[readIdx++];
            break;
        }
      }
    }
    invalidateDrawable();

    super.update(dirt);
  }

  static ActorPath read(
      ActorArtboard artboard, StreamReader reader, ActorPath component) {
    component ??= ActorPath();
    ActorNode.read(artboard, reader, component);
    ActorSkinnable.read(artboard, reader, component);

    component._isHidden = !reader.readBool("isVisible");
    component._isClosed = reader.readBool("isClosed");

    reader.openArray("points");
    int pointCount = reader.readUint16Length();
    component._points = List<PathPoint>(pointCount);
    for (int i = 0; i < pointCount; i++) {
      reader.openObject("point");
      PathPoint point;
      PointType type = pointTypeLookup[reader.readUint8("pointType")];
      switch (type) {
        case PointType.straight:
          {
            point = StraightPathPoint();
            break;
          }
        default:
          {
            point = CubicPathPoint(type);
            break;
          }
      }
      if (point == null) {
        throw UnsupportedError("Invalid point type " + type.toString());
      } else {
        point.read(reader, component.isConnectedToBones);
      }
      reader.closeObject();

      component._points[i] = point;
    }
    reader.closeArray();
    return component;
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorPath instanceEvent = ActorPath();
    instanceEvent.copyPath(this, resetArtboard);
    return instanceEvent;
  }

  @override
  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);
    resolveSkinnable(components);
  }

  void copyPath(ActorPath node, ActorArtboard resetArtboard) {
    copyNode(node, resetArtboard);
    copySkinnable(node, resetArtboard);
    _isHidden = node._isHidden;
    _isClosed = node._isClosed;

    int pointCount = node._points.length;

    _points = List<PathPoint>(pointCount);
    for (int i = 0; i < pointCount; i++) {
      _points[i] = node._points[i].makeInstance();
    }

    if (node.vertexDeform != null) {
      vertexDeform = Float32List.fromList(node.vertexDeform);
    }
  }
}
