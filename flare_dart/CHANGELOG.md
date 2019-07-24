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