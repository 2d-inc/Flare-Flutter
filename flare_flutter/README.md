# Flare-Flutter
Flutter runtime for Flare, depends on flare_dart.

## Installation
Add `flare_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). If you plan on writing a custom controller or want access to more of the guts of the library, you will want to also include `flare_dart` which is the base library responsible for loading, instancing, animating, and doing all the work that happens before rendering in `flare_flutter`. The examples include use cases for both scenarios.

## Exporting for Flutter
Export from Flare with the *"Export to Engine"* menu. In the Engine dropdown, choose *Flutter*, and in the Format dropdown your favorite form of compression.

## Adding Assets
Once you've exported your file, add the **.flr** file to your project's [Flutter assets](https://flutter.io/assets-and-images/). 

## Example
Take a look at the provided [example applications](https://github.com/2d-inc/Flare-Flutter/tree/master/example) for how to use the FlutterActor widget with an exported Flutter character.

## Usage
The easiest way to get started is by using the provided **FlareActor** widget. This is a stateless Flutter widget that allows for one Flare file with one active animation playing to be embedded in your Flutter App. 


You can change the currently playing animation by changing the animation property's name. 


You can also specify the mixSeconds to determine how long it takes for the animation to interpolate from the previous one. A value of 0 means that it will just pop to the new animation. A value of 0.5 will mean it takes half of a second to fully mix the new animation on top of the old one.

```
import 'package:flare_flutter/flare_actor.dart';
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new FlareActor("assets/Filip.flr", alignment:Alignment.center, fit:BoxFit.contain, animation:"idle");
  }
}
```

## Contributing
1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request.

## License
See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
