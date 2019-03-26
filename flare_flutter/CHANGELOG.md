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
