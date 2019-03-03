import "actor_color.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor_drawable.dart";
import "actor_artboard.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "dart:math";
import "math/mat2d.dart";
import "math/vec2d.dart";
import "math/aabb.dart";

class ActorShape extends ActorDrawable {
  List<ActorStroke> _strokes = List<ActorStroke>();
  List<ActorFill> _fills = List<ActorFill>();

  ActorFill get fill => _fills.length > 0 ? _fills.first : null;
  ActorStroke get stroke => _strokes.length > 0 ? _strokes.first : null;
  List<ActorFill> get fills => _fills;
  List<ActorStroke> get strokes => _strokes;

  void update(int dirt) {
    super.update(dirt);
    invalidateShape();
  }

  static ActorShape read(
      ActorArtboard artboard, StreamReader reader, ActorShape component) {
    if (component == null) {
      component = ActorShape();
    }

    ActorDrawable.read(artboard, reader, component);

    return component;
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorShape instanceEvent = ActorShape();
    instanceEvent.copyShape(this, resetArtboard);
    return instanceEvent;
  }

  void copyShape(ActorShape node, ActorArtboard resetArtboard) {
    copyDrawable(node, resetArtboard);
  }

  AABB computeAABB() {
    AABB aabb;
    for (List<ActorShape> clips in clipShapes) {
      for (ActorShape node in clips) {
        AABB bounds = node.computeAABB();
        if (bounds == null) {
          continue;
        }
        if (aabb == null) {
          aabb = bounds;
        } else {
          if (bounds[0] < aabb[0]) {
            aabb[0] = bounds[0];
          }
          if (bounds[1] < aabb[1]) {
            aabb[1] = bounds[1];
          }
          if (bounds[2] > aabb[2]) {
            aabb[2] = bounds[2];
          }
          if (bounds[3] > aabb[3]) {
            aabb[3] = bounds[3];
          }
        }
      }
    }
    if (aabb != null) {
      return aabb;
    }

    for (ActorNode node in children) {
      ActorBasePath path = node as ActorBasePath;
      if (path == null) {
        continue;
      }
      // This is the axis aligned bounding box in the space of the parent (this case our shape).
      AABB pathAABB = path.getPathAABB();

      if (aabb == null) {
        aabb = pathAABB;
      } else {
        // Combine.
        aabb[0] = min(aabb[0], pathAABB[0]);
        aabb[1] = min(aabb[1], pathAABB[1]);

        aabb[2] = max(aabb[2], pathAABB[2]);
        aabb[3] = max(aabb[3], pathAABB[3]);
      }
    }

    double minX = double.maxFinite;
    double minY = double.maxFinite;
    double maxX = -double.maxFinite;
    double maxY = -double.maxFinite;

    if (aabb == null) {
      return AABB.fromValues(minX, minY, maxX, maxY);
    }
    Mat2D world = worldTransform;

    if (_strokes != null) {
      double maxStroke = 0.0;
      for (ActorStroke stroke in _strokes) {
        if (stroke.width > maxStroke) {
          maxStroke = stroke.width;
        }
      }
      double padStroke = maxStroke / 2.0;
      aabb[0] -= padStroke;
      aabb[2] += padStroke;
      aabb[1] -= padStroke;
      aabb[3] += padStroke;
    }

    List<Vec2D> points = [
      Vec2D.fromValues(aabb[0], aabb[1]),
      Vec2D.fromValues(aabb[2], aabb[1]),
      Vec2D.fromValues(aabb[2], aabb[3]),
      Vec2D.fromValues(aabb[0], aabb[3])
    ];
    for (var i = 0; i < points.length; i++) {
      Vec2D pt = points[i];
      Vec2D wp = Vec2D.transformMat2D(pt, pt, world);
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

  void addStroke(ActorStroke stroke) {
    _strokes.add(stroke);
  }

  void addFill(ActorFill fill) {
    _fills.add(fill);
  }

  void initializeGraphics() {
    for (ActorStroke stroke in _strokes) {
      stroke.initializeGraphics();
    }
    for (ActorFill fill in _fills) {
      fill.initializeGraphics();
    }
  }

  @override
  int get blendModeId {
    return 0;
  }

  @override
  set blendModeId(int value) {}
}
