# Flare
<img align="right" src="https://cdn.2dimensions.com/flare_macbook.png" height="250">

[Flare](https://www.2dimensions.com/about-flare) offers powerful realtime vector design and animation for app and game designers alike. The primary goal of Flare is to allow designers to work directly with assets that run in their final product, eliminating the need to redo that work in code.

## Libraries
There are two Dart packages provided in this repository. [flare_dart](flare_dart) and [flare_flutter](flare_flutter). Most of the time you'll want only [flare_flutter](flare_flutter), especially if you're just starting out with Flare. Please read the details in [flare_flutter](flare_flutter) for how to get your Flare animations running in Flutter!

## Breaking changes in 1.1.0
Now that the base library is located in the flare_dart package, you'll need to patch up old imports that were referencing ```'package:flare_flutter/flare/...'``` to simply use ```'package:flare_dart/...'```. For example, if you were using the mat2d class from ```import 'package:flare_flutter/flare/math/mat2d.dart';``` you should now change it to ```import 'package:flare_dart/math/mat2d.dart';```

## Examples
Take a look at the provided [example applications](https://github.com/2d-inc/Flare-Flutter/tree/master/example).

## License
See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
