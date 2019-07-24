## [1.5.5] - 2019-07-24 11:44:36

 - Adding artboard option to FlareActor. Use this to change which artboard gets displayed by the FlareActor widget.
 - Fixed incorrect signature of load method. If you were deriving FlareRenderBox, you'll need to update it to match. It's a minor change from void to Future<void>.
 - Added some documentation to the FlareActor parameters.

## [1.5.4] - 2019-07-08 21:10:50

 - Using Uint16List for vertex indices now that Flutter Stable has been updated.

## [1.5.3] - 2019-07-06 11:09:44

 - Fixing an intialization error when a node has null children.
 - FlareActor widget can now size itself via the sizeFromArtboard named parameter, based on feedback from issue #104.

## [1.5.2] - 2019-06-20 16:33:52

 Using latest version of flare_dart which has fixes for rounded rectangles and clipping paths.


## [1.5.1] - 2019-05-20 10:38:30

Added missing call to setViewTransform for controllers. This is now done more efficiently as it is only called when the view transform changes.

## [1.5.0] - 2019-04-23 19:41:56

- New system in place to prevent breaking stable builds.
- Revert compute load for stable, please see https://github.com/2d-inc/Flare-Flutter for how to use the latest bleeding edge work with dev/master Flutter channels.

## [1.4.0] - 2019-04-23 19:41:56

- Improving load jank by loading the Flare file in an Isolate. This now requires calling Actor.loadImages once the Flare file has been loaded. FlareActor already handles this for you.
- Bug fix for opacity values going out of 0-1 range.

## [1.3.13] - 2019-04-22 09:39:15

Fixes a condition where elapsed time counters were not resetting to 0 when animation stopped. This would cause the elapsed time to be really high when starting to play a subsequent animation.

## [1.3.12] - 2019-04-13 18:12:09

Fixes a condition where animations would not advance if they were using an animation driven by FlareActor and one from FlareController.

## [1.3.11] - 2019-04-13 17:38:08

We've updated the advance logic (which drives the animations and custom controllers) to work in tandem with painting. This prevents advancing from continuing when the widget is no longer painting. It solves the issue of animations advancing when navigated away from a page containing a FlareActor widget. This was due to the widget still being attached to the widget tree, which would cause the FlareActor to think it would need to continue advancing.

N.B. Breaking Change: if you are implementing FlareController, consider using it as a mixin to avoid having to add your own isActive ValueNotifier. For most cases simply swapping the ```extends FlareController``` to ```with FlareController``` will suffice.

## [1.3.10] - 2019-04-11 09:36:58

Reloading when re-attaching a FlareRenderBox widget.

## [1.3.9] - 2019-04-10 16:53:20

Adding arguments for mix and mixSeconds to FlareControls.play().

## [1.3.8] - 2019-04-08 08:48:57

Using the latest Flare Dart which fixed an issue with trim path instances.

## [1.3.7] - 2019-04-06 19:28:48

New features for caching, custom renderers, and better support for overriding paint operations (allows for mutating paint to add things like color filters).

## [1.3.6] - 2019-03-26 15:56:34

Making new snapToEnd functionality default to false to support backwards compatibility.

## [1.3.5] - 2019-03-25 20:05:16

Updating flare_dart dependency which fixes a critical draw order issue.

## [1.3.4] - 2019-03-18 19:46:52

Ensure rendering state is restored after ActorImage is clipped.

## [1.3.3] - 2019-03-12 09:23:54

Apply clip to ActorImage.

## [1.3.2] - 2019-03-07 12:46:33

Use the displayColor value exposed by the ActorColor instead of the color value.

## [1.3.1] - 2019-03-07 11:23:40

Fixes for issues:
https://github.com/2d-inc/Flare-Flutter/issues/51
https://github.com/2d-inc/Flare-Flutter/issues/50
https://github.com/2d-inc/Flare-Flutter/issues/49

The list of animation layers was not getting cleared out when loading a new Flare file. This was causing animations from different files to be applied on Flare files that didn't own the animations.
