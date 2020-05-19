## [2.3.4] - 2020-04-03 20:13:58

- Fix issue with transform affects stroke and paths connected to bones.

## [2.3.3] - 2020-01-16 10:38:46

- Ensure drop shadow blurs don't accidentally get interpreted as the main blur effect on a layer. Fixes issue #203.

## [2.3.2] - 2019-12-17 04:54:38

- Mark layers for drawable items by first computing which drawables are in the layer. Removes race conditions with layers not being set correctly.

## [2.3.1] - 2019-12-16 09:17:37

- Type checking when applying trim path animation. Improves robustness and helps prevent crashes when applying animations from non-matching artboards.

## [2.3.0] - 2019-12-05 17:25:03

- Support for layer effects including masking, drop shadows, inner shadows, and blurs.

## [2.2.5] - 2019-11-20 16:36:24

- Fixed gradient transformations for shapes with transformAffectsStroke set to true.

## [2.2.4] - 2019-11-07 12:14:49

- Adding support for ActorImage.isDynamic which allows Flare to pacakge source UV coordinates for the image such that it can be swapped at runtime. This requires re-exporting files from Flare after marking the image as dynamic in the Flare UI.

## [2.2.3] - 2019-10-29 12:44:02

- Copy transformAffectsStroke from the source shape when instancing.

## [2.2.2] - 2019-10-11 12:55:44

- Call openObject before reading clip node and intersect, closeObject after. Fixes issue with reading in new clips in JSON.

## [2.2.1] - 2019-10-11 12:38:09

- Mitigate path keyframes exported for non-paths (fixing this on Flare side too).

## [2.2.0] - 2019-10-09 11:19:06

- Fix merge bug that sneaked into pub.

## [2.1.0] - 2019-10-09 11:08:05

- Adding support for difference clipping.

## [2.0.0] - 2019-10-08 13:38:26

- Fixing up various static analysis issues.
- Need to bump version to 2.0.0 due to breaking changes between flare_flutter and flare_dart caused by resolving analysis issues.

## [1.4.9] - 2019-10-07 11:20:58

- Supporting Nodes inside of Shapes, effectively adding multiple transform spaces inside of a shape.

## [1.4.8] - 2019-09-30 21:19:37

- Fixing linting problems in ActorDrawable and ActorSkin.

## [1.4.7] - 2019-09-23 16:42:53

- Added support for transformAffectsStroke property on ActorShape.

## [1.4.6] - 2019-09-04 08:48:11

- Prevent iterating null children. Fixes issue #146.

## [1.4.5] - 2019-08-23 09:51:30

Small changes to fix warnings caught by the Dart static analyzer.

## [1.4.4] - 2019-07-24 11:43:51

Adding getArtboard method to Actor class. Allows finding artboards by name.

## [1.4.3] - 2019-07-06 11:08:53

Some cleanup done while fixing issue #104 (using intrinsic artboard size as an option).

## [1.4.2] - 2019-06-20 16:30:37

Fixing issue with rounded rectangles not rendering correctly #107
Shapes that are collapsed are not when building up the clip path..

## [1.4.1] - 2019-05-20 10:40:04

Adding an areEquals method to Mat2D.

## [1.4.0] - 2019-04-23 19:43:01

Improving load times by using ByteData views when possible in favor of reading data in tight loops.

## [1.3.6] - 2019-04-08 08:46:05

Fixed an issue with instanced copies not including trim path values.

## [1.3.5] - 2019-04-06 19:04:55

Allow overriding instance nodes so that custom paint effects and operations can be applied to Images and Shapes.

## [1.3.4] - 2019-03-25 20:02:50

Validate draw order keyframe value is applying values to valid ActorDrawables. We had a condition in Flare that would export null drawOrder values, which would resolve to 0 in binary, causing the keyframe to point to a 0 indexed component. The fix is to both make the runtime library more resilient and to fix the exporter. Both have been done.

## [1.3.3] - 2019-03-12 09:24:20

Added link to Flare-Flutter in README.

## [1.3.2] - 2019-03-07 12:46:33

Split the color from ActorColor and the display color (which can be overriden by the Artboard) into two separate getters so that the animation keyframes don't overwrite the override color.