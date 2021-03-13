import 'dart:collection';
import 'dart:typed_data';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_blur.dart';
import 'package:flare_flutter/base/actor_bone_base.dart';
import 'package:flare_flutter/base/actor_color.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_constraint.dart';
import 'package:flare_flutter/base/actor_drawable.dart';
import 'package:flare_flutter/base/actor_image.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_node_solo.dart';
import 'package:flare_flutter/base/actor_path.dart';
import 'package:flare_flutter/base/actor_rectangle.dart';
import 'package:flare_flutter/base/actor_shadow.dart';
import 'package:flare_flutter/base/actor_star.dart';
import 'package:flare_flutter/base/animation/interpolation/cubic.dart';
import 'package:flare_flutter/base/animation/interpolation/hold.dart';
import 'package:flare_flutter/base/animation/interpolation/interpolator.dart';
import 'package:flare_flutter/base/animation/interpolation/linear.dart';
import 'package:flare_flutter/base/path_point.dart';
import 'package:flare_flutter/base/stream_reader.dart';

HashMap<int, InterpolationTypes> interpolationTypesLookup =
    HashMap<int, InterpolationTypes>.fromIterables([
  0,
  1,
  2
], [
  InterpolationTypes.hold,
  InterpolationTypes.linear,
  InterpolationTypes.cubic
]);

class DrawOrderIndex {
  final int componentIndex;
  final int order;

  DrawOrderIndex(this.componentIndex, this.order);
}

enum InterpolationTypes { hold, linear, cubic }

abstract class KeyFrame {
  late double _time;

  double get time {
    return _time;
  }

  void apply(ActorComponent? component, double mix);

  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix);
  void setNext(KeyFrame? frame);
  static bool read(StreamReader reader, KeyFrame frame) {
    frame._time = reader.readFloat64('time');

    return true;
  }
}

class KeyFrameActiveChild extends KeyFrame {
  late int _value;

  @override
  void apply(ActorComponent? component, double mix) {
    ActorNodeSolo soloNode = component as ActorNodeSolo;
    soloNode.activeChildIndex = _value;
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    apply(component, mix);
  }

  @override
  void setNext(KeyFrame? frame) {
    // No Interpolation
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameActiveChild frame = KeyFrameActiveChild();
    if (!KeyFrame.read(reader, frame)) {
      return null;
    }
    frame._value = reader.readFloat32('value').toInt();
    return frame;
  }
}

class KeyFrameBlurX extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorBlur node = component as ActorBlur;
    node.blurX = node.blurX * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameBlurX frame = KeyFrameBlurX();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameBlurY extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorBlur node = component as ActorBlur;
    node.blurY = node.blurY * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameBlurY frame = KeyFrameBlurY();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameBooleanProperty extends KeyFrame {
  @override
  void apply(ActorComponent? component, double mix) {}

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    apply(component, mix);
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameBooleanProperty frame = KeyFrameBooleanProperty();
    if (!KeyFrame.read(reader, frame)) {
      return null;
    }
    reader.readBool('value');
    return frame;
  }
}

class KeyFrameCollisionEnabledProperty extends KeyFrame {
  @override
  void apply(ActorComponent? component, double mix) {}

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    apply(component, mix);
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameCollisionEnabledProperty frame = KeyFrameCollisionEnabledProperty();
    if (!KeyFrame.read(reader, frame)) {
      return null;
    }
    reader.readBool('value');
    return frame;
  }
}

class KeyFrameConstraintStrength extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorConstraint constraint = component as ActorConstraint;
    constraint.strength = constraint.strength * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameConstraintStrength frame = KeyFrameConstraintStrength();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameCornerRadius extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorRectangle node = component as ActorRectangle;
    node.radius = node.radius * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameCornerRadius frame = KeyFrameCornerRadius();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameDrawOrder extends KeyFrame {
  late List<DrawOrderIndex> _orderedNodes;

  @override
  void apply(ActorComponent? component, double mix) {
    ActorArtboard artboard = component!.artboard;

    for (final DrawOrderIndex doi in _orderedNodes) {
      ActorComponent? component = artboard[doi.componentIndex];
      if (component is ActorDrawable) {
        component.drawOrder = doi.order;
      }
    }
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    apply(component, mix);
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameDrawOrder frame = KeyFrameDrawOrder();
    if (!KeyFrame.read(reader, frame)) {
      return null;
    }
    reader.openArray('drawOrder');
    int numOrderedNodes = reader.readUint16Length();
    frame._orderedNodes = <DrawOrderIndex>[];
    for (int i = 0; i < numOrderedNodes; i++) {
      reader.openObject('order');
      DrawOrderIndex drawOrder = DrawOrderIndex(
          reader.readId('component'), reader.readUint16('order'));
      reader.closeObject();
      frame._orderedNodes.add(drawOrder);
    }
    reader.closeArray();
    return frame;
  }
}

class KeyFrameFillColor extends KeyFrameWithInterpolation {
  late Float32List _value;

  Float32List get value {
    return _value;
  }

  @override
  void apply(ActorComponent? component, double mix) {
    ActorColor ac = component as ActorColor;
    int l = _value.length;
    Float32List wr = ac.color;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr[i] = _value[i];
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        wr[i] = wr[i] * mixi + _value[i] * mix;
      }
    }
    ac.markPaintDirty();
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    ActorColor ac = component as ActorColor;
    Float32List wr = ac.color;
    Float32List to = (toFrame as KeyFrameFillColor)._value;
    int l = _value.length;

    double f =
        _interpolator.getEasedMix((time - _time) / (toFrame.time - _time));
    double fi = 1.0 - f;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr[i] = _value[i] * fi + to[i] * f;
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        double v = _value[i] * fi + to[i] * f;

        wr[i] = wr[i] * mixi + v * mix;
      }
    }
    ac.markPaintDirty();
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameFillColor frame = KeyFrameFillColor();
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return null;
    }

    frame._value = reader.readFloat32Array(4, 'value');
    return frame;
  }
}

class KeyFrameFloatProperty extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {}

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameFloatProperty frame = KeyFrameFloatProperty();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameGradient extends KeyFrameWithInterpolation {
  late Float32List _value;
  Float32List get value => _value;

  @override
  void apply(ActorComponent? component, double mix) {
    GradientColor gradient = component as GradientColor;

    int ridx = 0;
    int wi = 0;

    if (mix == 1.0) {
      gradient.start[0] = _value[ridx++];
      gradient.start[1] = _value[ridx++];
      gradient.end[0] = _value[ridx++];
      gradient.end[1] = _value[ridx++];

      while (ridx < _value.length && wi < gradient.colorStops.length) {
        gradient.colorStops[wi++] = _value[ridx++];
      }
    } else {
      double imix = 1.0 - mix;
      gradient.start[0] = gradient.start[0] * imix + _value[ridx++] * mix;
      gradient.start[1] = gradient.start[1] * imix + _value[ridx++] * mix;
      gradient.end[0] = gradient.end[0] * imix + _value[ridx++] * mix;
      gradient.end[1] = gradient.end[1] * imix + _value[ridx++] * mix;

      while (ridx < _value.length && wi < gradient.colorStops.length) {
        gradient.colorStops[wi] =
            gradient.colorStops[wi] * imix + _value[ridx++];
        wi++;
      }
    }
    gradient.markPaintDirty();
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    GradientColor gradient = component as GradientColor;
    Float32List v = (toFrame as KeyFrameGradient)._value;

    double f =
        _interpolator.getEasedMix((time - _time) / (toFrame.time - _time));
    double fi = 1.0 - f;

    int ridx = 0;
    int wi = 0;

    if (mix == 1.0) {
      gradient.start[0] = _value[ridx] * fi + v[ridx++] * f;
      gradient.start[1] = _value[ridx] * fi + v[ridx++] * f;
      gradient.end[0] = _value[ridx] * fi + v[ridx++] * f;
      gradient.end[1] = _value[ridx] * fi + v[ridx++] * f;

      while (ridx < v.length && wi < gradient.colorStops.length) {
        gradient.colorStops[wi++] = _value[ridx] * fi + v[ridx++] * f;
      }
    } else {
      double imix = 1.0 - mix;

      // Mix : first interpolate the KeyFrames,
      //  and then mix on top of the current value.
      double val = _value[ridx] * fi + v[ridx] * f;
      gradient.start[0] = gradient.start[0] * imix + val * mix;
      ridx++;

      val = _value[ridx] * fi + v[ridx] * f;
      gradient.start[1] = gradient.start[1] * imix + val * mix;
      ridx++;

      val = _value[ridx] * fi + v[ridx] * f;
      gradient.end[0] = gradient.end[0] * imix + val * mix;
      ridx++;

      val = _value[ridx] * fi + v[ridx] * f;
      gradient.end[1] = gradient.end[1] * imix + val * mix;
      ridx++;

      while (ridx < v.length && wi < gradient.colorStops.length) {
        val = _value[ridx] * fi + v[ridx] * f;
        gradient.colorStops[wi] = gradient.colorStops[wi] * imix + val * mix;

        ridx++;
        wi++;
      }
    }
    gradient.markPaintDirty();
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameGradient frame = KeyFrameGradient();
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return null;
    }
    int len = reader.readUint16('length');
    frame._value = reader.readFloat32Array(len, 'value');
    return frame;
  }
}

class KeyFrameImageVertices extends KeyFrameWithInterpolation {
  late Float32List _vertices;

  Float32List get vertices {
    return _vertices;
  }

  @override
  void apply(ActorComponent? component, double mix) {
    ActorImage imageNode = component as ActorImage;
    int l = _vertices.length;
    Float32List? wr = imageNode.animationDeformedVertices;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr![i] = _vertices[i];
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        wr![i] = wr[i] * mixi + _vertices[i] * mix;
      }
    }

    imageNode.invalidateDrawable();
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    ActorImage imageNode = component as ActorImage;
    Float32List? wr = imageNode.animationDeformedVertices;
    Float32List to = (toFrame as KeyFrameImageVertices)._vertices;
    int l = _vertices.length;

    double f =
        _interpolator.getEasedMix((time - _time) / (toFrame.time - _time));

    double fi = 1.0 - f;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr![i] = _vertices[i] * fi + to[i] * f;
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        double v = _vertices[i] * fi + to[i] * f;

        wr![i] = wr[i] * mixi + v * mix;
      }
    }

    imageNode.invalidateDrawable();
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameImageVertices frame = KeyFrameImageVertices();
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return null;
    }

    ActorImage imageNode = component as ActorImage;
    frame._vertices =
        reader.readFloat32Array(imageNode.vertexCount * 2, 'value');

    imageNode.doesAnimationVertexDeform = true;

    return frame;
  }
}

class KeyFrameInnerRadius extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    if (component == null) return;

    ActorStar star = component as ActorStar;
    star.innerRadius = star.innerRadius * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameInnerRadius frame = KeyFrameInnerRadius();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

abstract class KeyFrameInt extends KeyFrameWithInterpolation {
  late double _value;

  double get value {
    return _value;
  }

  @override
  void apply(ActorComponent? component, double mix) {
    setValue(component, _value, mix);
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    KeyFrameNumeric to = toFrame as KeyFrameNumeric;
    double f = _interpolator.getEasedMix((time - _time) / (to._time - _time));
    setValue(component, _value * (1.0 - f) + to._value * f, mix);
  }

  void setValue(ActorComponent? component, double value, double mix);

  static bool read(StreamReader reader, KeyFrameInt frame) {
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return false;
    }
    frame._value = reader.readInt32('value').toDouble();
    return true;
  }
}

class KeyFrameIntProperty extends KeyFrameInt {
  @override
  void setValue(ActorComponent? component, double value, double mix) {}

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameIntProperty frame = KeyFrameIntProperty();
    if (KeyFrameInt.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameLength extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorBoneBase? bone = component as ActorBoneBase?;
    if (bone == null) {
      return;
    }
    bone.length = bone.length * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameLength frame = KeyFrameLength();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

abstract class KeyFrameNumeric extends KeyFrameWithInterpolation {
  late double _value;

  double get value {
    return _value;
  }

  @override
  void apply(ActorComponent? component, double mix) {
    setValue(component, _value, mix);
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    KeyFrameNumeric to = toFrame as KeyFrameNumeric;
    double f = _interpolator.getEasedMix((time - _time) / (to._time - _time));
    setValue(component, _value * (1.0 - f) + to._value * f, mix);
  }

  void setValue(ActorComponent? component, double value, double mix);

  static bool read(StreamReader reader, KeyFrameNumeric frame) {
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return false;
    }
    frame._value = reader.readFloat32('value');
    if (frame._value.isNaN) {
      // Do we want to warn the user the animation contains invalid values?
      frame._value = 1.0;
    }
    return true;
  }
}

class KeyFrameOpacity extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorNode node = component as ActorNode;
    node.opacity = node.opacity * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameOpacity frame = KeyFrameOpacity();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFramePaintOpacity extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorPaint node = component as ActorPaint;
    node.opacity = node.opacity * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFramePaintOpacity frame = KeyFramePaintOpacity();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFramePathVertices extends KeyFrameWithInterpolation {
  late Float32List _vertices;

  Float32List get vertices {
    return _vertices;
  }

  @override
  void apply(ActorComponent? component, double mix) {
    ActorPath path = component as ActorPath;
    int l = _vertices.length;
    Float32List? wr = path.vertexDeform;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr![i] = _vertices[i];
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        wr![i] = wr[i] * mixi + _vertices[i] * mix;
      }
    }

    path.markVertexDeformDirty();
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    ActorPath path = component as ActorPath;
    Float32List? wr = path.vertexDeform;
    Float32List to = (toFrame as KeyFramePathVertices)._vertices;
    int l = _vertices.length;

    double f =
        _interpolator.getEasedMix((time - _time) / (toFrame.time - _time));
    double fi = 1.0 - f;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr![i] = _vertices[i] * fi + to[i] * f;
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        double v = _vertices[i] * fi + to[i] * f;

        wr![i] = wr[i] * mixi + v * mix;
      }
    }

    path.markVertexDeformDirty();
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFramePathVertices frame = KeyFramePathVertices();
    if (!KeyFrameWithInterpolation.read(reader, frame) ||
        component is! ActorPath) {
      return null;
    }

    ActorPath pathNode = component;

    int length = pathNode.points.fold<int>(0, (int previous, PathPoint point) {
      return previous + 2 + (point.pointType == PointType.straight ? 1 : 4);
    });
    frame._vertices = Float32List(length);
    int readIdx = 0;
    reader.openArray('value');
    for (final PathPoint point in pathNode.points) {
      frame._vertices[readIdx++] = reader.readFloat32('translationX');
      frame._vertices[readIdx++] = reader.readFloat32('translationY');
      if (point.pointType == PointType.straight) {
        // radius
        frame._vertices[readIdx++] = reader.readFloat32('radius');
      } else {
        // in/out
        frame._vertices[readIdx++] = reader.readFloat32('inValueX');
        frame._vertices[readIdx++] = reader.readFloat32('inValueY');
        frame._vertices[readIdx++] = reader.readFloat32('outValueX');
        frame._vertices[readIdx++] = reader.readFloat32('outValueY');
      }
    }
    reader.closeArray();

    pathNode.makeVertexDeform();
    return frame;
  }
}

class KeyFramePosX extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorNode node = component as ActorNode;
    node.x = node.x * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFramePosX frame = KeyFramePosX();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFramePosY extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorNode node = component as ActorNode;
    node.y = node.y * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFramePosY frame = KeyFramePosY();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameRadial extends KeyFrameWithInterpolation {
  late Float32List _value;
  Float32List get value => _value;

  @override
  void apply(ActorComponent? component, double mix) {
    RadialGradientColor radial = component as RadialGradientColor;

    int ridx = 0;
    int wi = 0;

    if (mix == 1.0) {
      radial.secondaryRadiusScale = value[ridx++];
      radial.start[0] = _value[ridx++];
      radial.start[1] = _value[ridx++];
      radial.end[0] = _value[ridx++];
      radial.end[1] = _value[ridx++];

      while (ridx < _value.length && wi < radial.colorStops.length) {
        radial.colorStops[wi++] = _value[ridx++];
      }
    } else {
      double imix = 1.0 - mix;
      radial.secondaryRadiusScale =
          radial.secondaryRadiusScale * imix + value[ridx++] * mix;
      radial.start[0] = radial.start[0] * imix + _value[ridx++] * mix;
      radial.start[1] = radial.start[1] * imix + _value[ridx++] * mix;
      radial.end[0] = radial.end[0] * imix + _value[ridx++] * mix;
      radial.end[1] = radial.end[1] * imix + _value[ridx++] * mix;

      while (ridx < _value.length && wi < radial.colorStops.length) {
        radial.colorStops[wi] = radial.colorStops[wi] * imix + _value[ridx++];
        wi++;
      }
    }
    radial.markPaintDirty();
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    RadialGradientColor radial = component as RadialGradientColor;
    Float32List v = (toFrame as KeyFrameRadial)._value;

    double f =
        _interpolator.getEasedMix((time - _time) / (toFrame.time - _time));
    double fi = 1.0 - f;

    int ridx = 0;
    int wi = 0;

    if (mix == 1.0) {
      radial.secondaryRadiusScale = _value[ridx] * fi + v[ridx++] * f;
      radial.start[0] = _value[ridx] * fi + v[ridx++] * f;
      radial.start[1] = _value[ridx] * fi + v[ridx++] * f;
      radial.end[0] = _value[ridx] * fi + v[ridx++] * f;
      radial.end[1] = _value[ridx] * fi + v[ridx++] * f;

      while (ridx < v.length && wi < radial.colorStops.length) {
        radial.colorStops[wi++] = _value[ridx] * fi + v[ridx++] * f;
      }
    } else {
      double imix = 1.0 - mix;

      // Mix : first interpolate the KeyFrames,
      //  and then mix on top of the current value.
      double val = _value[ridx] * fi + v[ridx] * f;
      radial.secondaryRadiusScale = _value[ridx] * fi + v[ridx++] * f;
      val = _value[ridx] * fi + v[ridx] * f;
      radial.start[0] = _value[ridx++] * imix + val * mix;
      val = _value[ridx] * fi + v[ridx] * f;
      radial.start[1] = _value[ridx++] * imix + val * mix;
      val = _value[ridx] * fi + v[ridx] * f;
      radial.end[0] = _value[ridx++] * imix + val * mix;
      val = _value[ridx] * fi + v[ridx] * f;
      radial.end[1] = _value[ridx++] * imix + val * mix;

      while (ridx < v.length && wi < radial.colorStops.length) {
        val = _value[ridx] * fi + v[ridx] * f;
        radial.colorStops[wi] = radial.colorStops[wi] * imix + val * mix;

        ridx++;
        wi++;
      }
    }
    radial.markPaintDirty();
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameRadial frame = KeyFrameRadial();
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return null;
    }
    int len = reader.readUint16('length');
    frame._value = reader.readFloat32Array(len, 'value');
    return frame;
  }
}

class KeyFrameRotation extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorNode node = component as ActorNode;
    node.rotation = node.rotation * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameRotation frame = KeyFrameRotation();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameScaleX extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorNode node = component as ActorNode;
    node.scaleX = node.scaleX * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameScaleX frame = KeyFrameScaleX();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameScaleY extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorNode node = component as ActorNode;
    node.scaleY = node.scaleY * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameScaleY frame = KeyFrameScaleY();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameSequence extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorImage node = component as ActorImage;
    int frameIndex = value.floor() % node.sequenceFrames!.length;
    if (frameIndex < 0) {
      frameIndex += node.sequenceFrames!.length;
    }
    node.sequenceFrame = frameIndex;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameSequence frame = KeyFrameSequence();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameShadowColor extends KeyFrameWithInterpolation {
  late Float32List _value;

  Float32List get value {
    return _value;
  }

  @override
  void apply(ActorComponent? component, double mix) {
    ActorShadow shadow = component as ActorShadow;
    int l = _value.length;
    Float32List wr = shadow.color;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr[i] = _value[i];
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        wr[i] = wr[i] * mixi + _value[i] * mix;
      }
    }
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    ActorShadow shadow = component as ActorShadow;
    Float32List wr = shadow.color;
    Float32List to = (toFrame as KeyFrameShadowColor)._value;
    int l = _value.length;

    double f =
        _interpolator.getEasedMix((time - _time) / (toFrame.time - _time));

    double fi = 1.0 - f;
    if (mix == 1.0) {
      for (int i = 0; i < l; i++) {
        wr[i] = _value[i] * fi + to[i] * f;
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < l; i++) {
        double v = _value[i] * fi + to[i] * f;

        wr[i] = wr[i] * mixi + v * mix;
      }
    }
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameShadowColor frame = KeyFrameShadowColor();
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return null;
    }

    frame._value = reader.readFloat32Array(4, 'value');
    return frame;
  }
}

class KeyFrameShadowOffsetX extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorShadow node = component as ActorShadow;
    node.offsetX = node.offsetX * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameShadowOffsetX frame = KeyFrameShadowOffsetX();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameShadowOffsetY extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    ActorShadow node = component as ActorShadow;
    node.offsetY = node.offsetY * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameShadowOffsetY frame = KeyFrameShadowOffsetY();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameShapeHeight extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    if (component == null) return;

    if (component is ActorProceduralPath) {
      component.height = component.height * (1.0 - mix) + value * mix;
    }
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameShapeHeight frame = KeyFrameShapeHeight();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameShapeWidth extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    if (component == null) return;

    if (component is ActorProceduralPath) {
      component.width = component.width * (1.0 - mix) + value * mix;
    }
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameShapeWidth frame = KeyFrameShapeWidth();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameStringProperty extends KeyFrame {
  @override
  void apply(ActorComponent? component, double mix) {
    // CustomStringProperty prop = component as CustomStringProperty;
    // prop.value = _value;
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    apply(component, mix);
  }

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameStringProperty frame = KeyFrameStringProperty();
    if (!KeyFrame.read(reader, frame)) {
      return null;
    }
    reader.readString('value');
    return frame;
  }
}

class KeyFrameStrokeColor extends KeyFrameWithInterpolation {
  late Float32List _value;

  Float32List get value {
    return _value;
  }

  @override
  void apply(ActorComponent? component, double mix) {
    ColorStroke node = component as ColorStroke;
    Float32List wr = node.color;
    int len = wr.length;
    if (mix == 1.0) {
      for (int i = 0; i < len; i++) {
        wr[i] = _value[i];
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < len; i++) {
        wr[i] = wr[i] * mixi + _value[i] * mix;
      }
    }
    node.markPaintDirty();
  }

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {
    ColorStroke cs = component as ColorStroke;
    Float32List wr = cs.color;
    Float32List to = (toFrame as KeyFrameStrokeColor)._value;
    int len = _value.length;

    double f =
        _interpolator.getEasedMix((time - _time) / (toFrame.time - _time));
    double fi = 1.0 - f;
    if (mix == 1.0) {
      for (int i = 0; i < len; i++) {
        wr[i] = _value[i] * fi + to[i] * f;
      }
    } else {
      double mixi = 1.0 - mix;
      for (int i = 0; i < len; i++) {
        double v = _value[i] * fi + to[i] * f;

        wr[i] = wr[i] * mixi + v * mix;
      }
    }
    cs.markPaintDirty();
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameStrokeColor frame = KeyFrameStrokeColor();
    if (!KeyFrameWithInterpolation.read(reader, frame)) {
      return null;
    }
    frame._value = reader.readFloat32Array(4, 'value');
    return frame;
  }
}

class KeyFrameStrokeEnd extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    if (component is! ActorStroke) return;

    ActorStroke star = component as ActorStroke;
    star.trimEnd = star.trimEnd * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameStrokeEnd frame = KeyFrameStrokeEnd();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameStrokeOffset extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    if (component == null) return;

    ActorStroke star = component as ActorStroke;
    star.trimOffset = star.trimOffset * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameStrokeOffset frame = KeyFrameStrokeOffset();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameStrokeStart extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    if (component is! ActorStroke) return;

    ActorStroke star = component as ActorStroke;
    star.trimStart = star.trimStart * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameStrokeStart frame = KeyFrameStrokeStart();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameStrokeWidth extends KeyFrameNumeric {
  @override
  void setValue(ActorComponent? component, double value, double mix) {
    if (component == null) return;
    ActorStroke stroke = component as ActorStroke;
    stroke.width = stroke.width * (1.0 - mix) + value * mix;
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameStrokeWidth frame = KeyFrameStrokeWidth();
    if (KeyFrameNumeric.read(reader, frame)) {
      return frame;
    }
    return null;
  }
}

class KeyFrameTrigger extends KeyFrame {
  @override
  void apply(ActorComponent? component, double mix) {}

  @override
  void applyInterpolation(
      ActorComponent? component, double time, KeyFrame toFrame, double mix) {}

  @override
  void setNext(KeyFrame? frame) {
    // Do nothing.
  }

  static KeyFrame? read(StreamReader reader, ActorComponent? component) {
    KeyFrameTrigger frame = KeyFrameTrigger();
    if (!KeyFrame.read(reader, frame)) {
      return null;
    }
    return frame;
  }
}

abstract class KeyFrameWithInterpolation extends KeyFrame {
  Interpolator _interpolator = LinearInterpolator.instance;

  Interpolator get interpolator => _interpolator;

  @override
  void setNext(KeyFrame? frame) {
    // Null out the interpolator if the next frame doesn't validate.
    // if(_interpolator != null && !_interpolator.setNextFrame(this, frame))
    // {
    // 	_interpolator = null;
    // }
  }

  static bool read(StreamReader reader, KeyFrameWithInterpolation frame) {
    if (!KeyFrame.read(reader, frame)) {
      return false;
    }
    int type = reader.readUint8('interpolatorType');

    InterpolationTypes? actualType = interpolationTypesLookup[type];
    actualType ??= InterpolationTypes.linear;

    switch (actualType) {
      case InterpolationTypes.hold:
        frame._interpolator = HoldInterpolator.instance;
        break;
      case InterpolationTypes.linear:
        frame._interpolator = LinearInterpolator.instance;
        break;
      case InterpolationTypes.cubic:
        {
          CubicInterpolator interpolator = CubicInterpolator();
          if (interpolator.read(reader)) {
            frame._interpolator = interpolator;
          }
          break;
        }
      default:
        frame._interpolator = HoldInterpolator.instance;
    }
    return true;
  }
}
