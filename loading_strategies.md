# Loading Strategies
This is an experimental branch attempting to reduce pop and swimming of UI as Flare files load. 

## Three Strategies
There are three strategies that can be employed. The first and third will work on the master/dev/stable branches too. 

If neither of those work, then take a look at the second solution here. It warms up the cache but then also forces the entire load path to be synchronous. That requires the code in this branch. You'll need to set-up a submodule in your project referencing this branch and you'll need to update your pubspec to find flare_flutter in the path to the submodule.

## Strategy 1 - Warming up the Flare Cache
Prior to running the app, make sure Flare files are placed in cache. This requires changing the main function and adding some logic prior to initialization.
```dart
final AssetProvider assetProvider = AssetFlare(bundle: rootBundle, name: 'assets/file.flr');

Future<void> _warmupAnimations() async {
await cachedActor(assetProvider);
}

void main() {
  // Newer versions of Flutter require initializing widget-flutter binding
  // prior to warming up the cache.
  WidgetsFlutterBinding.ensureInitialized();

  // Don't prune the Flare cache, keep loaded Flare files warm and ready
  // to be re-displayed.
  FlareCache.doesPrune = false;

  // Warm the cache up.
  warmupFlare().then((_) {
    // Finally start the app.
    runApp(MyApp());
  });
}
```

You'll note that this will keep all Flare files warmed up in the cache via ```FlareCache.doesPrune = false;```. See Strategy 3 for a way to get around that. 

## Stratgey 2 - Warmup + Sync
This strategy requires cloning (best via submodule) this branch into your project and using it as the path for flare_flutter in your pubspec. Note that the branch is called ```sync_load```.

You'll need to do everything in **Strategy 1** but then also add the ```loadSync: true``` named parameter to the FlareActor:
```dart
FlareActor(
  "assets/file.flr",
  alignment: Alignment.center,
  fit: BoxFit.contain,
  sizeFromArtboard: true,
  animation: "idle",

  // Load the Flare file synchronously.
  loadSync: true,
)
``` 

## Strategy 3 - Disconnect Widget and Artboard
There are other ways of ensuring that a Flare file is loaded prior to displaying a widget, but this requires a more sophisticated app design where you split the widget from the loading of the file.

This is the most sophisticated and cleanest design of the three, but also requires a little more code and a better understanding of how Flare works with Flutter. [This diagram](https://github.com/2d-inc/android_summit#flare-architecture) shows a little bit of how everything is composed.

The default FlareActor takes a filename as a parameter. This means it has to internally load (or get from cache) a Flare file. Another approach is to have the app code directly load the Flare file as necessary and pass a reference to the artboard (what gets drawn at runtime) to a widget that can immediately start drawing the Flare contents. The Flare-Flutter runtime provides you with all you need to create that widget. There are a few examples out there (FlareActor is one of them) but there's a pretty well isolated one we created for an issue someone ran into.

Take a look at this issue and provided solution:
https://github.com/2d-inc/Flare-Flutter/issues/111#issuecomment-508190690

You'll see that we use a custom FlareArtboard widget to display the Flare file, and instead of passing it a filename, we pass it the artboard object (FlutterActorArtboard) directly, which is already in memory and ready to be drawn.

We pre-load it by getting it frome cache and holding a reference indefinitely in:
https://github.com/luigi-rosso/flare_flutter_shared_artboard/blob/b08a67539728efbaf9814158315ad6d443c56c26/lib/main.dart#L11
