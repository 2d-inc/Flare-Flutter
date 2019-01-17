# Flare Slider

<img align="right" src="https://i.imgur.com/eSRRwuh.gif" height="250">

This is an example built using the [Resizing House](https://www.2dimensions.com/a/pollux/files/flare/resizing-house/) Flare File by Guido Rosso. <br/>
It demonstrates how to build a custom controller for the animation named [`HouseController`](lib/house_controller.dart)

As shown in the gif to the right, this app provides a custom controlling logic that's applied to the animation when the user moves the slider on the screen. <br/>
As a result, the Resizing House animation will interpolate from its current state to the value specified by the slider.

## `FlareController` Overview

An instance of the `HouseController` is passed to the `FlareActor` in [`page.dart`](lib/page.dart#L53)

```
FlareActor("assets/Resizing_House.flr",
    controller: _houseController,
    fit: BoxFit.fill,
)
```

[`FlareController`](../../lib/flare_controller.dart) is the basic _abstract class_ for controlling a Flare File in Flutter. Its subclasses needs to override its three methods:

1. `initialize(FlutterActorArtboard artboard)`<br/>
This is called once: when the `FlareActor` widget is instantiated

2. `advance(FlutterActorArtboard artboard, double elapsed)`<br/>
This is called every frame: every time the artboard advances, it relays the elapsed time to the controller, which can thus perform custom actions

3. `setViewTransform(Mat2D viewTransform)`<br/>
This is also called every frame, and relays information regarding the current view matrix of the animation

HouseController provides custom implementations for [`advance()`](lib/house_controller.dart#L29) and [`initialize()`](lib/house_controller.dart#L71)