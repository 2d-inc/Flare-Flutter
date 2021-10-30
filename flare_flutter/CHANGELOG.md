## [3.0.2] - 2021-07-29 14:39:32

- Fixing an anti-aliasing bug introduced when migrating to null safety.

## [3.0.1] - 2021-06-03 15:01:30

- Maintenance release supporting upcoming changes to Flutter.
## [3.0.0] - 2021-03-29 17:05:59

- Identical to [3.0.0-nullsafety.1] but has now been tested by users and is now ready for usage.


## [3.0.0-nullsafety.1] - 2021-03-17 15:33:25

- Fix for nullsafety issue reported https://github.com/2d-inc/Flare-Flutter/issues/297 where the _paint object wasn't getting initialized.

## [3.0.0-nullsafety.0] - 2021-03-12 17:00:11

- Implementing null safety.

## [2.0.6] - 2020-08-05 15:54:45

- Fix timestep calculation based on feedback from #262.

## [2.0.5] - 2020-07-06 11:22:33

- New feature to disable anti-aliasing to help improve performance on certain devices.

## [2.0.4] - 2020-06-28 20:40:00

- Fix issue with drop/inner shadows that are within shadow offset of the artboard bounds (this would cause the shadow to get clipped).

## [2.0.3] - 2020-04-10 14:02:55

- Fix issue with mask color matrices not having their translation column in 0-255 space (Skia expects these in 0-1 but Flutter specifically makes a distinction for the translation column). 

## [2.0.2] - 2020-04-03 20:14:35

- Fix issue with transform affects stroke and paths connected to bones.

## [2.0.1] - 2020-01-16 10:41:07

- Fix issue #203.
- New feature submitted by Yuwen Yan @ybbaigo to provide Rive (previously Flare) assets from different sources. Maintains backwards compatibility while adding FlareActor.rootBundle, FlareActor.asset, and various ways to acquire a FlareAsset.

## [1.8.3] - 2019-12-17 04:56:04

- Mark layers for drawable items by first computing which drawables are in the layer. Removes race conditions with layers not being set correctly.

## [1.8.2] - 2019-12-16 09:19:22

- Clear out layers when instancing artboards to prevent animations from other artboards being applied.

## [1.8.1] - 2019-12-09 19:33:06

- Disable blur effects if they are less than a certain threshold. Skia seems to drop the whole layer if it's too close to zero (but not zero).

## [1.8.0] - 2019-12-05 17:34:01

- Support for layer effects including masking, drop shadows, inner shadows, and blurs.

## [1.7.3] - 2019-11-20 16:37:18

- Fixed gradient transformations for shapes with transformAffectsStroke set to true.

## [1.7.2] - 2019-11-18 16:30:39

- Fixing FlareControls to allow for completing layered animations. FlareControls would previously remove an animation once another one played after it had fully mixed in. This would cause popping when animations didn't touch the exact same keyframes.

## [1.7.1] - 2019-11-07 15:03:39

- Backing out changeImageFromNetwork until new PaintingBinding.instance.instantiateImageCodec signature lands in stable.
- You can manually implement this function if you need it. Example here: https://gist.github.com/luigi-rosso/c50277341bd2681be072a575acbeb1fc#file-dynamic_image_swapping-dart-L60

## [1.7.0] - 2019-11-07 12:16:35

- Adding support for runtime image swapping.

## [1.6.5] - 2019-11-06 17:29:43

- Fixed an issue with FlareCacheBuilder calling setState when the widget is no longer mounted.

## [1.6.4] - 2019-10-29 12:45:05

- Use latest flare_dart, fixing issue with transformAffectsStroke in instances.
- Implement features as suggested by PR https://github.com/2d-inc/Flare-Flutter/pull/177
- New FlareCacheBuilder which takes an array of Flare files to warm the cache up with, builder is called with an isWarm boolean to allow displaying different content while the files are loading. Useful for loading Flare files you know you'll be using later in this view (or sub view) context and having them display immediately.
- FlareActor will always attempt a warm load (fully sync) path when loading a Flare content, assuring that when content is warm in the cache, no visual glitches/pops occur.

## [1.6.3] - 2019-10-11 12:58:13

- Use latest flare_dart, fixing issue with reading clip nodes in JSON.

## [1.6.2] - 2019-10-11 12:38:33

- Use latest flare_dart, mitigating a bad path keyframe issue.

## [1.6.1] - 2019-10-09 14:20:54

- Image and Shapes share clipping logic. Fixes issue with image clipping.

## [1.6.0] - 2019-10-09 11:08:52

- Using latest flare_dart with support for difference clipping.

## [1.5.15] - 2019-10-08 13:38:55

- Fixed Pub deploy bug.

## [1.5.14] - 2019-10-08 13:38:55

- Fixing up various static analysis issues.

## [1.5.13] - 2019-10-07 11:21:29

- Using latest flare_dart with support for Nodes inside of Shapes (Paths with multiple transform spaces).

## [1.5.12] - 2019-10-04 17:56:54

- Introduce FlareTesting.setup(); call this prior to running any tests using Flare content.

## [1.5.11] - 2019-10-04 13:44:04

- Clamping trim start/end values to 0-1.

## [1.5.10] - 2019-09-30 21:20:50

- Bump flare_dart dependency.

## [1.5.9] - 2019-09-23 16:43:42

- Added support for transformAffectsStroke property on ActorShape. Internally this requires a new concrete type for the FlutterActorShape as the transformAffectsStroke property requires a slightly more complex version of FlutterActorShape. In order to keep existing animations (and future ones that don't use this) streamlined, a new FlutterActorShapeWithTransformedStroke class was added that extends from FlutterActorShape.

## [1.5.8] - 2019-09-04 08:47:31

- Bump flare_dart dependency version to get fix for iterating null children. Issue #146.

## [1.5.7] - 2019-08-26 10:39:49

- Clip the artboard based on settings from Flare.

## [1.5.6] - 2019-08-23 09:52:13

- Clamp opacity values into 0..1 range before creating color for paint.

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
