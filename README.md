:warning: | Please migrate to the new [Rive Flutter runtime](https://github.com/rive-app/rive-flutter). This runtime is for the old Rive (formerly [Flare](https://flare.rive.app)) and will only receive updates for breaking issues with Flutter and egregious bugs. New features and updates are only planned for the new [Rive](https://rive.app).
| -- | -- |

# Rive 1 (previously Flare)
<img align="right" src="https://cdn.rive.app/flare_macbook.png" height="250">

[Rive 1 (previously Flare)](https://flare.rive.app/) offers powerful realtime vector design and animation for app and game designers alike. The primary goal of Flare is to allow designers to work directly with assets that run in their final product, eliminating the need to redo that work in code.

## Null Safety
Preview of null safety is now available on pub.dev with version 3.0.0. Include it in your pubspec via:
```
  dependencies:
    flare_flutter: ^3.0.0-nullsafety.0
```

## Packages
There used to be two Dart packages provided in this repository. [flare_dart](https://pub.dev/packages/flare_dart) is no longer maintained as a separate package, it has now been rolled into [flare_flutter](https://pub.dev/packages/flare_flutter). Please use only [flare_flutter](https://pub.dev/packages/flare_flutter) going forward.

## Examples
Take a look at the provided [example applications](https://github.com/2d-inc/Flare-Flutter/tree/master/example).

Please note that only the [simple](example/simple), [change_color](example/change_color), and [teddy](example/teddy) have been updated to null safety.

## License
See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
