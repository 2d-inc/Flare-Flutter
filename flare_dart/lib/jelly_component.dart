import "stream_reader.dart";
import "actor_artboard.dart";
import "actor_jelly_bone.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor_bone.dart";
import "math/vec2d.dart";
import "math/mat2d.dart";
import "dart:math";
import "actor_root_bone.dart";
import "actor_constraint.dart";

class JellyComponent extends ActorComponent {
  static const int JellyMax = 16;
  static double OptimalDistance = 4.0 * (sqrt(2.0) - 1.0) / 3.0;
  static double CurveConstant = OptimalDistance * sqrt(2.0) * 0.5;
  static const double Epsilon = 0.001; // Intentionally agressive.

  static bool fuzzyEquals(Vec2D a, Vec2D b) {
    double a0 = a[0], a1 = a[1];
    double b0 = b[0], b1 = b[1];
    return ((a0 - b0).abs() <= Epsilon * max(1.0, max(a0.abs(), b0.abs())) &&
        (a1 - b1).abs() <= Epsilon * max(1.0, max(a1.abs(), b1.abs())));
  }

  static void forwardDiffBezier(double c0, double c1, double c2, double c3,
      List<Vec2D> points, int count, int offset) {
    double f = count.toDouble();

    double p0 = c0;

    double p1 = 3.0 * (c1 - c0) / f;

    f *= count;
    double p2 = 3.0 * (c0 - 2.0 * c1 + c2) / f;

    f *= count;
    double p3 = (c3 - c0 + 3.0 * (c1 - c2)) / f;

    c0 = p0;
    c1 = p1 + p2 + p3;
    c2 = 2 * p2 + 6 * p3;
    c3 = 6 * p3;

    for (int a = 0; a <= count; a++) {
      points[a][offset] = c0;
      c0 += c1;
      c1 += c2;
      c2 += c3;
    }
  }

  List<Vec2D> normalizeCurve(List<Vec2D> curve, int numSegments) {
    List<Vec2D> points = List<Vec2D>();
    int curvePointCount = curve.length;
    List<double> distances = List<double>(curvePointCount);
    distances[0] = 0.0;
    for (int i = 0; i < curvePointCount - 1; i++) {
      Vec2D p1 = curve[i];
      Vec2D p2 = curve[i + 1];
      distances[i + 1] = distances[i] + Vec2D.distance(p1, p2);
    }
    double totalDistance = distances[curvePointCount - 1];

    double segmentLength = totalDistance / numSegments;
    int pointIndex = 1;
    for (int i = 1; i <= numSegments; i++) {
      double distance = segmentLength * i;

      while (pointIndex < curvePointCount - 1 &&
          distances[pointIndex] < distance) {
        pointIndex++;
      }

      double d = distances[pointIndex];
      double lastCurveSegmentLength = d - distances[pointIndex - 1];
      double remainderOfDesired = d - distance;
      double ratio = remainderOfDesired / lastCurveSegmentLength;
      double iratio = 1.0 - ratio;

      Vec2D p1 = curve[pointIndex - 1];
      Vec2D p2 = curve[pointIndex];
      points.add(Vec2D.fromValues(
          p1[0] * ratio + p2[0] * iratio, p1[1] * ratio + p2[1] * iratio));
    }

    return points;
  }

  double _easeIn;
  double _easeOut;
  double _scaleIn;
  double _scaleOut;
  int _inTargetIdx;
  int _outTargetIdx;
  ActorNode _inTarget;
  ActorNode _outTarget;
  List<ActorJellyBone> _bones;
  Vec2D _inPoint;
  Vec2D _inDirection;
  Vec2D _outPoint;
  Vec2D _outDirection;

  Vec2D _cachedTip;
  Vec2D _cachedOut;
  Vec2D _cachedIn;
  double _cachedScaleIn;
  double _cachedScaleOut;

  List<Vec2D> _jellyPoints;

  ActorNode get inTarget => _inTarget;
  ActorNode get outTarget => _inTarget;

  JellyComponent() {
    _inPoint = Vec2D();
    _inDirection = Vec2D();
    _outPoint = Vec2D();
    _outDirection = Vec2D();
    _cachedTip = Vec2D();
    _cachedOut = Vec2D();
    _cachedIn = Vec2D();

    _jellyPoints = List<Vec2D>(JellyMax + 1);
    for (var i = 0; i <= JellyMax; i++) {
      _jellyPoints[i] = Vec2D();
    }
  }
  ActorComponent makeInstance(ActorArtboard artboard) {
    JellyComponent instance = JellyComponent();
    instance.copyJelly(this, artboard);
    return instance;
  }

  void copyJelly(JellyComponent component, ActorArtboard artboard) {
    super.copyComponent(component, artboard);
    _easeIn = component._easeIn;
    _easeOut = component._easeOut;
    _scaleIn = component._scaleIn;
    _scaleOut = component._scaleOut;
    _inTargetIdx = component._inTargetIdx;
    _outTargetIdx = component._outTargetIdx;
  }

  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);

    if (_inTargetIdx != 0) {
      _inTarget = components[_inTargetIdx] as ActorNode;
    }
    if (_outTargetIdx != 0) {
      _outTarget = components[_outTargetIdx] as ActorNode;
    }

    List<ActorConstraint> dependencyConstraints = <ActorConstraint>[];
    ActorBone bone = parent as ActorBone;
    if (bone != null) {
      artboard.addDependency(this, bone);
      dependencyConstraints += bone.allConstraints;
      ActorBone firstBone = bone.firstBone;
      if (firstBone != null) {
        artboard.addDependency(this, firstBone);
        dependencyConstraints += firstBone.allConstraints;

        // If we don't have an out target and the child jelly does have an in target
        // we are dependent on that target's position.
        if (_outTarget == null &&
            firstBone.jelly != null &&
            firstBone.jelly.inTarget != null) {
          artboard.addDependency(this, firstBone.jelly.inTarget);
          dependencyConstraints += firstBone.jelly.inTarget.allConstraints;
        }
      }
      if (bone.parent is ActorBone) {
        ActorBone parentBone = bone.parent;
        JellyComponent parentBoneJelly = parentBone.jelly;
        if (parentBoneJelly != null && parentBoneJelly.outTarget != null) {
          artboard.addDependency(this, parentBoneJelly.outTarget);
          dependencyConstraints += parentBoneJelly.outTarget.allConstraints;
        }
      }
    }

    if (_inTarget != null) {
      artboard.addDependency(this, _inTarget);
      dependencyConstraints += _inTarget.allConstraints;
    }
    if (_outTarget != null) {
      artboard.addDependency(this, _outTarget);
      dependencyConstraints += _outTarget.allConstraints;
    }

    // We want to depend on any and all constraints that our dependents have.
    Set<ActorConstraint> constraints =
        Set<ActorConstraint>.from(dependencyConstraints);
    for (ActorConstraint constraint in constraints) {
      artboard.addDependency(this, constraint);
    }
  }

  void completeResolve() {
    //super.completeResolve();
    ActorBone bone = parent as ActorBone;
    bone.jelly = this;

    // Get jellies.
    List<ActorNode> children = bone.children;
    if (children == null) {
      return;
    }

    _bones = List<ActorJellyBone>();
    for (ActorNode child in children) {
      if (child is ActorJellyBone) {
        _bones.add(child);
        // Make sure the jelly doesn't update until the jelly component has updated
        artboard.addDependency(child, this);
      }
    }
  }

  static JellyComponent read(
      ActorArtboard artboard, StreamReader reader, JellyComponent node) {
    if (node == null) {
      node = JellyComponent();
    }
    ActorComponent.read(artboard, reader, node);

    node._easeIn = reader.readFloat32("easeIn");
    node._easeOut = reader.readFloat32("easeOut");
    node._scaleIn = reader.readFloat32("scaleIn");
    node._scaleOut = reader.readFloat32("scaleOut");
    node._inTargetIdx = reader.readId("inTargetId");
    node._outTargetIdx = reader.readId("outTargetId");

    return node;
  }

  void updateJellies() {
    if (_bones == null) {
      return;
    }
    ActorBone bone = parent as ActorBone;
    // We are in local bone space.
    Vec2D tipPosition = Vec2D.fromValues(bone.length, 0.0);

    if (fuzzyEquals(_cachedTip, tipPosition) &&
        fuzzyEquals(_cachedOut, _outPoint) &&
        fuzzyEquals(_cachedIn, _inPoint) &&
        _cachedScaleIn == _scaleIn &&
        _cachedScaleOut == _scaleOut) {
      return;
    }

    Vec2D.copy(_cachedTip, tipPosition);
    Vec2D.copy(_cachedOut, _outPoint);
    Vec2D.copy(_cachedIn, _inPoint);
    _cachedScaleIn = _scaleIn;
    _cachedScaleOut = _scaleOut;

    Vec2D q0 = Vec2D();
    Vec2D q1 = _inPoint;
    Vec2D q2 = _outPoint;
    Vec2D q3 = tipPosition;

    forwardDiffBezier(q0[0], q1[0], q2[0], q3[0], _jellyPoints, JellyMax, 0);
    forwardDiffBezier(q0[1], q1[1], q2[1], q3[1], _jellyPoints, JellyMax, 1);

    List<Vec2D> normalizedPoints = normalizeCurve(_jellyPoints, _bones.length);

    Vec2D lastPoint = _jellyPoints[0];

    double scale = _scaleIn;
    double scaleInc = (_scaleOut - _scaleIn) / (_bones.length - 1);
    for (int i = 0; i < normalizedPoints.length; i++) {
      ActorJellyBone jelly = _bones[i];
      Vec2D p = normalizedPoints[i];

      jelly.translation = lastPoint;
      jelly.length = Vec2D.distance(p, lastPoint);
      jelly.scaleY = scale;
      scale += scaleInc;

      Vec2D diff = Vec2D.subtract(Vec2D(), p, lastPoint);
      jelly.rotation = atan2(diff[1], diff[0]);
      lastPoint = p;
    }
  }

  @override
  void onDirty(int dirt) {
    // Intentionally empty. Doesn't throw dirt around.
  }

  @override
  void update(int dirt) {
    ActorBone bone = parent as ActorBone;
    ActorNode parentBone = bone.parent;
    JellyComponent parentBoneJelly;
    if (parentBone is ActorBone) {
      parentBoneJelly = parentBone.jelly;
    }

    Mat2D inverseWorld = Mat2D();
    if (!Mat2D.invert(inverseWorld, bone.worldTransform)) {
      return;
    }

    if (_inTarget != null) {
      Vec2D translation = _inTarget.getWorldTranslation(Vec2D());
      Vec2D.transformMat2D(_inPoint, translation, inverseWorld);
      Vec2D.normalize(_inDirection, _inPoint);
    } else if (parentBone != null) {
      ActorBone firstBone;
      if (parentBone is ActorBone) {
        firstBone = parentBone.firstBone;
      } else if (parentBone is ActorRootBone) {
        firstBone = parentBone.firstBone;
      }
      if (firstBone == bone &&
          parentBoneJelly != null &&
          parentBoneJelly._outTarget != null) {
        Vec2D translation =
            parentBoneJelly._outTarget.getWorldTranslation(Vec2D());
        Vec2D localParentOut =
            Vec2D.transformMat2D(Vec2D(), translation, inverseWorld);
        Vec2D.normalize(localParentOut, localParentOut);
        Vec2D.negate(_inDirection, localParentOut);
      } else {
        Vec2D d1 = Vec2D.fromValues(1.0, 0.0);
        Vec2D d2 = Vec2D.fromValues(1.0, 0.0);

        Vec2D.transformMat2(d1, d1, parentBone.worldTransform);
        Vec2D.transformMat2(d2, d2, bone.worldTransform);

        Vec2D sum = Vec2D.add(Vec2D(), d1, d2);
        Vec2D.transformMat2(_inDirection, sum, inverseWorld);
        Vec2D.normalize(_inDirection, _inDirection);
      }
      _inPoint[0] = _inDirection[0] * _easeIn * bone.length * CurveConstant;
      _inPoint[1] = _inDirection[1] * _easeIn * bone.length * CurveConstant;
    } else {
      _inDirection[0] = 1.0;
      _inDirection[1] = 0.0;
      _inPoint[0] = _inDirection[0] * _easeIn * bone.length * CurveConstant;
    }

    if (_outTarget != null) {
      Vec2D translation = _outTarget.getWorldTranslation(Vec2D());
      Vec2D.transformMat2D(_outPoint, translation, inverseWorld);
      Vec2D tip = Vec2D.fromValues(bone.length, 0.0);
      Vec2D.subtract(_outDirection, _outPoint, tip);
      Vec2D.normalize(_outDirection, _outDirection);
    } else if (bone.firstBone != null) {
      ActorBone firstBone = bone.firstBone;
      JellyComponent firstBoneJelly = firstBone.jelly;
      if (firstBoneJelly != null && firstBoneJelly._inTarget != null) {
        Vec2D translation =
            firstBoneJelly._inTarget.getWorldTranslation(Vec2D());
        Vec2D worldChildInDir = Vec2D.subtract(
            Vec2D(), firstBone.getWorldTranslation(Vec2D()), translation);
        Vec2D.transformMat2(_outDirection, worldChildInDir, inverseWorld);
      } else {
        Vec2D d1 = Vec2D.fromValues(1.0, 0.0);
        Vec2D d2 = Vec2D.fromValues(1.0, 0.0);

        Vec2D.transformMat2(d1, d1, firstBone.worldTransform);
        Vec2D.transformMat2(d2, d2, bone.worldTransform);

        Vec2D sum = Vec2D.add(Vec2D(), d1, d2);
        Vec2D negativeSum = Vec2D.negate(Vec2D(), sum);
        Vec2D.transformMat2(_outDirection, negativeSum, inverseWorld);
        Vec2D.normalize(_outDirection, _outDirection);
      }
      Vec2D.normalize(_outDirection, _outDirection);
      Vec2D scaledOut = Vec2D.scale(
          Vec2D(), _outDirection, _easeOut * bone.length * CurveConstant);
      _outPoint[0] = bone.length;
      _outPoint[1] = 0.0;
      Vec2D.add(_outPoint, _outPoint, scaledOut);
    } else {
      _outDirection[0] = -1.0;
      _outDirection[1] = 0.0;

      Vec2D scaledOut = Vec2D.scale(
          Vec2D(), _outDirection, _easeOut * bone.length * CurveConstant);
      _outPoint[0] = bone.length;
      _outPoint[1] = 0.0;
      Vec2D.add(_outPoint, _outPoint, scaledOut);
    }

    updateJellies();
  }
}
