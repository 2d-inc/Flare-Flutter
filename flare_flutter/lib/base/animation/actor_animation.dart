// ignore_for_file: prefer_constructors_over_static_methods
import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_event.dart';
import 'package:flare_flutter/base/animation/keyframe.dart';
import 'package:flare_flutter/base/animation/property_types.dart';
import 'package:flare_flutter/base/stream_reader.dart';

typedef KeyFrame? KeyFrameReader(
    StreamReader reader, ActorComponent? component);

class ActorAnimation {
  final String _name;
  final int _fps;
  final double _duration;
  final bool _isLooping;
  final List<ComponentAnimation> _components = <ComponentAnimation>[];
  final List<ComponentAnimation> _triggerComponents = <ComponentAnimation>[];

  ActorAnimation(String name, int fps, double duration, bool isLooping)
      : _name = name,
        _fps = fps,
        _duration = duration,
        _isLooping = isLooping;

  List<ComponentAnimation> get animatedComponents => _components;

  double get duration => _duration;

  int get fps => _fps;

  bool get isLooping => _isLooping;

  String get name => _name;

  /// Apply the specified time to all the components of this animation.
  /// This operation will result in the application of the keyframe values
  /// at the given time, and perform interpolation if needed.
  ///
  /// @time is the current time for this animation
  /// @artboard is the artboard that contains it
  /// @mix is a value [0,1]
  ///   This is a blending parameter to allow smoothing between concurrent
  ///   animations.
  ///   By setting mix to 1, the current animation will fully  replace the
  ///   existing values. By ramping up mix with values between 0 and 1, the
  ///   transition from one animation to the next will be more gradual as it
  ///   gets mixed in, preventing poppying effects.
  void apply(double time, ActorArtboard artboard, double mix) {
    for (final ComponentAnimation componentAnimation in _components) {
      componentAnimation.apply(time, artboard.components, mix);
    }
  }

  void triggerEvents(List<ActorComponent> components, double fromTime,
      double toTime, List<AnimationEventArgs> triggerEvents) {
    for (int i = 0; i < _triggerComponents.length; i++) {
      ComponentAnimation keyedComponent = _triggerComponents[i];
      for (final PropertyAnimation? property in keyedComponent.properties) {
        switch (property!.propertyType) {
          case PropertyTypes.trigger:
            List<KeyFrame?> keyFrames = property.keyFrames!;

            int kfl = keyFrames.length;
            if (kfl == 0) {
              continue;
            }

            int idx = 0;
            // Binary find the keyframe index.
            {
              int mid = 0;
              double element = 0.0;
              int start = 0;
              int end = kfl - 1;

              while (start <= end) {
                mid = (start + end) >> 1;
                element = keyFrames[mid]!.time;
                if (element < toTime) {
                  start = mid + 1;
                } else if (element > toTime) {
                  end = mid - 1;
                } else {
                  start = mid;
                  break;
                }
              }

              idx = start;
            }

            if (idx == 0) {
              if (kfl > 0 && keyFrames[0]!.time == toTime) {
                ActorComponent component =
                    components[keyedComponent.componentIndex];
                triggerEvents.add(AnimationEventArgs(component.name, component,
                    property.propertyType, toTime, 0.0));
              }
            } else {
              for (int k = idx - 1; k >= 0; k--) {
                KeyFrame frame = keyFrames[k]!;

                if (frame.time > fromTime) {
                  ActorComponent component =
                      components[keyedComponent.componentIndex];
                  triggerEvents.add(AnimationEventArgs(
                      component.name,
                      component,
                      property.propertyType,
                      frame.time,
                      toTime - frame.time));
                  /*triggered.push({
										name:component._Name,
										component:component,
										propertyType:property._Type,
										keyFrameTime:frame._Time,
										elapsed:toTime-frame._Time
									});*/
                } else {
                  break;
                }
              }
            }
            break;
          default:
            break;
        }
      }
    }
  }

  static ActorAnimation read(
      StreamReader reader, List<ActorComponent?> components) {
    ActorAnimation animation = ActorAnimation(
        reader.readString('name'),
        reader.readUint8('fps'),
        reader.readFloat32('duration'),
        reader.readBool('isLooping'));
    reader.openArray('keyed');
    int numKeyedComponents = reader.readUint16Length();

    List<ComponentAnimation> animatedComponents = <ComponentAnimation>[];
    for (int i = 0; i < numKeyedComponents; i++) {
      ComponentAnimation componentAnimation =
          ComponentAnimation.read(reader, components);
      animatedComponents.add(componentAnimation);
    }
    reader.closeArray();

    for (int i = 0; i < numKeyedComponents; i++) {
      ComponentAnimation componentAnimation = animatedComponents[i];

      ActorComponent? actorComponent =
          components[componentAnimation.componentIndex];
      if (actorComponent != null) {
        if (actorComponent is ActorEvent) {
          animation._triggerComponents.add(componentAnimation);
        } else {
          animation._components.add(componentAnimation);
        }
      }
    }

    return animation;
  }
}

class AnimationEventArgs {
  final String _name;
  final ActorComponent _component;
  final int _propertyType;
  final double _keyFrameTime;
  final double _elapsedTime;

  AnimationEventArgs(String name, ActorComponent component, int type,
      double keyframeTime, double elapsedTime)
      : _name = name,
        _component = component,
        _propertyType = type,
        _keyFrameTime = keyframeTime,
        _elapsedTime = elapsedTime;

  ActorComponent get component {
    return _component;
  }

  double get elapsedTime {
    return _elapsedTime;
  }

  double get keyFrameTime {
    return _keyFrameTime;
  }

  String get name {
    return _name;
  }

  int get propertyType {
    return _propertyType;
  }
}

class ComponentAnimation {
  final int _componentIndex;
  final List<PropertyAnimation?> _properties = <PropertyAnimation?>[];

  ComponentAnimation(int componentIndex) : _componentIndex = componentIndex;

  int get componentIndex {
    return _componentIndex;
  }

  List<PropertyAnimation?> get properties {
    return _properties;
  }

  void apply(double time, List<ActorComponent?> components, double mix) {
    for (final PropertyAnimation? propertyAnimation in _properties) {
      if (propertyAnimation != null) {
        propertyAnimation.apply(time, components[_componentIndex], mix);
      }
    }
  }

  static ComponentAnimation read(
      StreamReader reader, List<ActorComponent?> components) {
    reader.openObject('component');
    ComponentAnimation componentAnimation =
        ComponentAnimation(reader.readId('component'));
    int numProperties = reader.readUint16Length();
    for (int i = 0; i < numProperties; i++) {
      assert(componentAnimation._componentIndex < components.length);
      componentAnimation._properties.add(PropertyAnimation.read(
          reader, components[componentAnimation._componentIndex]));
    }
    reader.closeObject();

    return componentAnimation;
  }
}

class PropertyAnimation {
  final int _type;
  List<KeyFrame?>? _keyFrames;

  PropertyAnimation(int type) : _type = type;

  List<KeyFrame?>? get keyFrames {
    return _keyFrames;
  }

  int get propertyType {
    return _type;
  }

  void apply(double time, ActorComponent? component, double mix) {
    if (_keyFrames!.isEmpty) {
      return;
    }

    int idx = 0;
    // Binary find the keyframe index.
    {
      int mid = 0;
      double element = 0.0;
      int start = 0;
      int end = _keyFrames!.length - 1;

      while (start <= end) {
        mid = (start + end) >> 1;
        element = _keyFrames![mid]!.time;
        if (element < time) {
          start = mid + 1;
        } else if (element > time) {
          end = mid - 1;
        } else {
          start = mid;
          break;
        }
      }

      idx = start;
    }

    if (idx == 0) {
      _keyFrames![0]!.apply(component, mix);
    } else {
      if (idx < _keyFrames!.length) {
        KeyFrame? fromFrame = _keyFrames![idx - 1];
        KeyFrame toFrame = _keyFrames![idx]!;
        if (time == toFrame.time) {
          toFrame.apply(component, mix);
        } else {
          fromFrame!.applyInterpolation(component, time, toFrame, mix);
        }
      } else {
        _keyFrames![idx - 1]!.apply(component, mix);
      }
    }
  }

  static PropertyAnimation? read(
      StreamReader reader, ActorComponent? component) {
    StreamReader? propertyBlock = reader.readNextBlock(propertyTypesMap);
    if (propertyBlock == null) {
      return null;
    }
    PropertyAnimation propertyAnimation =
        PropertyAnimation(propertyBlock.blockType);

    KeyFrameReader? keyFrameReader;
    switch (propertyAnimation._type) {
      case PropertyTypes.posX:
        keyFrameReader = KeyFramePosX.read;
        break;
      case PropertyTypes.posY:
        keyFrameReader = KeyFramePosY.read;
        break;
      case PropertyTypes.scaleX:
        keyFrameReader = KeyFrameScaleX.read;
        break;
      case PropertyTypes.scaleY:
        keyFrameReader = KeyFrameScaleY.read;
        break;
      case PropertyTypes.rotation:
        keyFrameReader = KeyFrameRotation.read;
        break;
      case PropertyTypes.opacity:
        keyFrameReader = KeyFrameOpacity.read;
        break;
      case PropertyTypes.drawOrder:
        keyFrameReader = KeyFrameDrawOrder.read;
        break;
      case PropertyTypes.length:
        keyFrameReader = KeyFrameLength.read;
        break;
      case PropertyTypes.imageVertices:
        keyFrameReader = KeyFrameImageVertices.read;
        break;
      case PropertyTypes.constraintStrength:
        keyFrameReader = KeyFrameConstraintStrength.read;
        break;
      case PropertyTypes.trigger:
        keyFrameReader = KeyFrameTrigger.read;
        break;
      case PropertyTypes.intProperty:
        keyFrameReader = KeyFrameIntProperty.read;
        break;
      case PropertyTypes.floatProperty:
        keyFrameReader = KeyFrameFloatProperty.read;
        break;
      case PropertyTypes.stringProperty:
        keyFrameReader = KeyFrameStringProperty.read;
        break;
      case PropertyTypes.booleanProperty:
        keyFrameReader = KeyFrameBooleanProperty.read;
        break;
      case PropertyTypes.collisionEnabled:
        keyFrameReader = KeyFrameCollisionEnabledProperty.read;
        break;
      case PropertyTypes.activeChildIndex:
        keyFrameReader = KeyFrameActiveChild.read;
        break;
      case PropertyTypes.sequence:
        keyFrameReader = KeyFrameSequence.read;
        break;
      case PropertyTypes.pathVertices:
        keyFrameReader = KeyFramePathVertices.read;
        break;
      case PropertyTypes.fillColor:
        keyFrameReader = KeyFrameFillColor.read;
        break;
      case PropertyTypes.color:
        keyFrameReader = KeyFrameShadowColor.read;
        break;
      case PropertyTypes.offsetX:
        keyFrameReader = KeyFrameShadowOffsetX.read;
        break;
      case PropertyTypes.offsetY:
        keyFrameReader = KeyFrameShadowOffsetY.read;
        break;
      case PropertyTypes.blurX:
        keyFrameReader = KeyFrameBlurX.read;
        break;
      case PropertyTypes.blurY:
        keyFrameReader = KeyFrameBlurY.read;
        break;
      case PropertyTypes.fillGradient:
        keyFrameReader = KeyFrameGradient.read;
        break;
      case PropertyTypes.strokeGradient:
        keyFrameReader = KeyFrameGradient.read;
        break;
      case PropertyTypes.fillRadial:
        keyFrameReader = KeyFrameRadial.read;
        break;
      case PropertyTypes.strokeRadial:
        keyFrameReader = KeyFrameRadial.read;
        break;
      case PropertyTypes.strokeColor:
        keyFrameReader = KeyFrameStrokeColor.read;
        break;
      case PropertyTypes.strokeWidth:
        keyFrameReader = KeyFrameStrokeWidth.read;
        break;
      case PropertyTypes.strokeOpacity:
      case PropertyTypes.fillOpacity:
        keyFrameReader = KeyFramePaintOpacity.read;
        break;
      case PropertyTypes.shapeWidth:
        keyFrameReader = KeyFrameShapeWidth.read;
        break;
      case PropertyTypes.shapeHeight:
        keyFrameReader = KeyFrameShapeHeight.read;
        break;
      case PropertyTypes.cornerRadius:
        keyFrameReader = KeyFrameCornerRadius.read;
        break;
      case PropertyTypes.innerRadius:
        keyFrameReader = KeyFrameInnerRadius.read;
        break;
      case PropertyTypes.strokeStart:
        keyFrameReader = KeyFrameStrokeStart.read;
        break;
      case PropertyTypes.strokeEnd:
        keyFrameReader = KeyFrameStrokeEnd.read;
        break;
      case PropertyTypes.strokeOffset:
        keyFrameReader = KeyFrameStrokeOffset.read;
        break;
    }

    if (keyFrameReader == null) {
      return null;
    }

    propertyBlock.openArray('frames');
    int keyFrameCount = propertyBlock.readUint16Length();
    propertyAnimation._keyFrames = <KeyFrame?>[];
    KeyFrame? lastKeyFrame;
    for (int i = 0; i < keyFrameCount; i++) {
      propertyBlock.openObject('frame');
      KeyFrame? frame = keyFrameReader(propertyBlock, component);
      propertyAnimation._keyFrames!.add(frame);
      if (lastKeyFrame != null) {
        lastKeyFrame.setNext(frame);
      }
      lastKeyFrame = frame;
      propertyBlock.closeObject();
    }
    propertyBlock.closeArray();
    //}

    return propertyAnimation;
  }
}
