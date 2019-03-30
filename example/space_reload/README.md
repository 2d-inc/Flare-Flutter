# space_reload

A UI experiment with [Flare](https://www.2dimensions.com) and [Flutter](https://www.flutter.io).
<img align="right" height="500" src="https://i.imgur.com/ThYExoF.gif">

View the Flare file [here](https://www.2dimensions.com/a/pollux/files/flare/space-demo).

## Usage

To run it locally, make sure you have [Flutter installed](https://flutter.io/docs/get-started/install):
```
git clone https://github.com/2d-inc/Flare-Flutter.git
cd Flare-Flutter/example/space_reload/
flutter run
```

## Overview

This example shows how to build a custom pulldown menu in Flutter using a Flare animation.

Take a look at `refresh_control.dart` [here](lib/refresh_control.dart#L133). To build the pulldown, a [CupertinoSliverRefreshControl](https://docs.flutter.io/flutter/cupertino/CupertinoSliverRefreshControl-class.html) is used as one of the `Sliver`s that compose the `CustomScrollView`. [Here's](lib/refresh_control.dart#L90) the builder method with the background pulldown animation. At its core, this is just a `FlareActor`, the widget through which `Flare-Flutter` renders Flare files onto the screen.

`_CupertinoRefreshControlDemoState` implements the `FlareController` interface, providing a concrete implementation for `initialize()`, `setViewTransform()` and `advance()`.<br/>
These methods are used to have more granular control on how the animation behaves and reacts to events.
