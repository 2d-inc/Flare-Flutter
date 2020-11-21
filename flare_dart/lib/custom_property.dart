import 'package:flare_dart/actor_artboard.dart';
import 'package:flare_dart/actor_component.dart';
import 'package:flare_dart/stream_reader.dart';

/// Generic class for CustomProperties in the Rive editor.
/// They are represented by a single value of generic type T,
/// where T can be a [int], [double], [String] or [bool].
///
/// Trying to [read()] a CustomProperty with any other type will result 
/// in an [UnsupportedError].
class CustomProperty<T> extends ActorComponent {
  T _value;

  CustomProperty._();

  T get value => _value;
  set value(T newValue) {
    if (newValue != _value) {
      _value = newValue;
    }
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    var instance = CustomProperty<T>._();
    instance.copyComponent(this, resetArtboard);
    instance._value = _value;
    return instance;
  }

  @override
  void completeResolve() {}

  @override
  void onDirty(int dirt) {}

  @override
  void update(int dirt) {}

  static CustomProperty<T> readCustomProperty<T>(
      ActorArtboard artboard, StreamReader reader) {
    var component = CustomProperty<T>._();
    ActorComponent.read(artboard, reader, component);
    switch (T) {
      case int:
        component._value = reader.readInt32("int") as T;
        break;
      case double:
        component._value = reader.readFloat32("float") as T;
        break;
      case String:
        component._value = reader.readString("string") as T;
        break;
      case bool:
        component._value = reader.readBool("bool") as T;
        break;
      default:
        throw UnsupportedError(
            "Custom Property for type $T is not currently supported");
    }
    return component;
  }

  @override
  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);
    if (parentIdx >= 0) {
      parent.addCustomProperty(this);
    }
  }
}
