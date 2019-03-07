## [1.3.2] - 2019-03-07 12:46:33

Use the displayColor value exposed by the ActorColor instead of the color value.

## [1.3.1] - 2019-03-07 11:23:40

Fixes for issues:
https://github.com/2d-inc/Flare-Flutter/issues/51
https://github.com/2d-inc/Flare-Flutter/issues/50
https://github.com/2d-inc/Flare-Flutter/issues/49

The list of animation layers was not getting cleared out when loading a new Flare file. This was causing animations from different files to be applied on Flare files that didn't own the animations.
