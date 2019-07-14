# Flare
<img align="right" src="https://cdn.2dimensions.com/flare_macbook.png" height="250">

[Flare](https://www.2dimensions.com/about-flare) offers powerful realtime vector design and animation for app and game designers alike. The primary goal of Flare is to allow designers to work directly with assets that run in their final product, eliminating the need to redo that work in code.

## Libraries
There are two Dart packages provided in this repository. [flare_dart](flare_dart) and [flare_flutter](flare_flutter). Most of the time you'll want only [flare_flutter](flare_flutter), especially if you're just starting out with Flare. Please read the details in [flare_flutter](flare_flutter) for how to get your Flare animations running in Flutter!

## Flutter Channel
This repository has three primary branches: 
- stable
  - This is the branch we publish to pub from. 
  - This branch and the associated pub packages are guaranteed to work on the flutter stable channel.
  ```
  flare_flutter: ^1.5.4
  ```
- dev
  - This branch has the latest changes should work with the flutter dev channel.
  - You can point to this branch directly from your pubspec with the following syntax.
  ```
  flare_flutter:
    git: 
      url: git://github.com/2d-inc/Flare-Flutter.git
      ref: dev
      path: flare_flutter
  ```
- master
  - This is the branch we work off of for development and the community submits PRs to.
  - The references in the pubspec here are local, meaning that the intention is to use this library as local reference:
  ```
  flare_flutter:
    path: ~/my/repos/flare_flutter
  ```

## Examples
Take a look at the provided [example applications](https://github.com/2d-inc/Flare-Flutter/tree/master/example).

## License
See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
