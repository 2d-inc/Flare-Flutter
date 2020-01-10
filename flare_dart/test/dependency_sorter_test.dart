import 'dart:typed_data';

import 'package:flare_dart/actor_artboard.dart';
import 'package:flare_dart/actor_color.dart';
import 'package:flare_dart/actor_component.dart';
import 'package:flare_dart/actor_drop_shadow.dart';
import 'package:flare_dart/actor_inner_shadow.dart';
import 'package:flare_dart/actor_layer_effect_renderer.dart';
import 'package:flare_dart/actor_node.dart';
import 'package:flare_dart/actor.dart';
import 'package:flare_dart/dependency_sorter.dart';

import 'package:test/test.dart';

class DummyActor extends Actor {
  @override
  Future<bool> loadAtlases(List<Uint8List> rawAtlases) {
    throw UnimplementedError();
  }

  @override
  ColorFill makeColorFill() {
    throw UnimplementedError();
  }

  @override
  ColorStroke makeColorStroke() {
    throw UnimplementedError();
  }

  @override
  ActorDropShadow makeDropShadow() {
    throw UnimplementedError();
  }

  @override
  GradientFill makeGradientFill() {
    throw UnimplementedError();
  }

  @override
  GradientStroke makeGradientStroke() {
    throw UnimplementedError();
  }

  @override
  ActorInnerShadow makeInnerShadow() {
    throw UnimplementedError();
  }

  @override
  ActorLayerEffectRenderer makeLayerEffectRenderer() {
    throw UnimplementedError();
  }

  @override
  RadialGradientFill makeRadialFill() {
    throw UnimplementedError();
  }

  @override
  RadialGradientStroke makeRadialStroke() {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readOutOfBandAsset(String filename, context) {
    throw UnimplementedError();
  }
}

String orderString(List<ActorComponent> order) {
  String output = order.fold(
      '',
      (previousValue, actorComponent) =>
          previousValue + ' ' + actorComponent.name);
  return output.trim();
}

void main() {
  group("Simple Cycle:", () {
    ActorArtboard artboard;
    final actor = DummyActor();
    artboard = ActorArtboard(actor);
    final nodeA = ActorNode()..name = 'A';
    final nodeB = ActorNode()..name = 'B';
    final nodeC = ActorNode()..name = 'C';
    final nodeD = ActorNode()..name = 'D';

    ///
    /// [root] <- [A] <- [B] <- [D]
    ///            A      |      A
    ///            |      +------+
    ///           [C]
    artboard.addDependency(nodeA, artboard.root);
    artboard.addDependency(nodeB, nodeA);
    artboard.addDependency(nodeC, nodeA);
    artboard.addDependency(nodeD, nodeB);
    artboard.addDependency(nodeB, nodeD);

    test("DependencySorter cannot order", () {
      expect(DependencySorter().sort(artboard.root), equals(null));
    });

    test("TarjansDependencySorter orders", () {
      var order = TarjansDependencySorter().sort(artboard.root);
      expect(order.length, equals(3));
      expect(orderString(order), equals('Unnamed A C'));
    });
  });
  group("No cycle:", () {
    final actor = DummyActor();
    final artboard = ActorArtboard(actor);
    final nodeA = ActorNode()..name = 'A';
    final nodeB = ActorNode()..name = 'B';
    final nodeC = ActorNode()..name = 'C';
    final nodeD = ActorNode()..name = 'D';

    ///
    /// [root] <- [A] <- [B] <- [D]
    ///            A      A
    ///            |      |
    ///           [C]-----+
    artboard.addDependency(nodeA, artboard.root);
    artboard.addDependency(nodeB, nodeA);
    artboard.addDependency(nodeC, nodeA);
    artboard.addDependency(nodeD, nodeB);
    artboard.addDependency(nodeC, nodeB);

    test("DependencySorter orders", () {
      var order = DependencySorter().sort(artboard.root);
      expect(order, isNotNull);
      expect(orderString(order), 'Unnamed A B C D');
    });

    test("DependencySorter orders", () {
      var order = TarjansDependencySorter().sort(artboard.root);
      expect(order, isNotNull);
      expect(orderString(order), 'Unnamed A B C D');
    });
  });

  group("Complex Cycle A:", () {
    final actor = DummyActor();
    final artboard = ActorArtboard(actor);
    final nodeA = ActorNode()..name = 'A';
    final nodeB = ActorNode()..name = 'B';
    final nodeC = ActorNode()..name = 'C';
    final nodeD = ActorNode()..name = 'D';

    ///
    ///                   +------+
    ///                   |      v
    /// [root] <- [A] <- [B] <- [D]
    ///            A             |
    ///            |             |
    ///           [C]<-----------+
    ///
    artboard.addDependency(nodeA, artboard.root);
    artboard.addDependency(nodeB, nodeA);
    artboard.addDependency(nodeD, nodeB);
    artboard.addDependency(nodeB, nodeD);
    artboard.addDependency(nodeC, nodeA);
    artboard.addDependency(nodeD, nodeC);

    test("DependencySorter cannot order", () {
      expect(DependencySorter().sort(artboard.root), equals(null));
    });

    test("TarjansDependencySorter orders", () {
      var order = TarjansDependencySorter().sort(artboard.root);
      expect(order, isNotNull);
      expect(orderString(order), equals('Unnamed A C'));
    });
  });

  group("Complex Cycle B, F is isolated:", () {
    ActorArtboard artboard;

    final actor = DummyActor();
    artboard = ActorArtboard(actor);
    final nodeA = ActorNode()..name = 'A';
    final nodeB = ActorNode()..name = 'B';
    final nodeC = ActorNode()..name = 'C';
    final nodeD = ActorNode()..name = 'D';
    final nodeE = ActorNode()..name = 'E';
    final nodeF = ActorNode()..name = 'F';

    ///
    ///                   +-------------+
    ///                   |             |
    ///                   |     [F]     |
    ///                   |      v      v
    /// [root] <- [A] <- [B] <- [C] <- [D]
    ///            A             |
    ///            |             |
    ///           [E]<-----------+
    ///
    artboard.addDependency(nodeA, artboard.root);
    artboard.addDependency(nodeB, nodeA);
    artboard.addDependency(nodeC, nodeB);
    artboard.addDependency(nodeD, nodeC);
    artboard.addDependency(nodeB, nodeD);
    artboard.addDependency(nodeE, nodeA);
    artboard.addDependency(nodeC, nodeE);
    artboard.addDependency(nodeF, nodeC);

    test("TarjansDependencySorter orders", () {
      var dependencySorter = TarjansDependencySorter();
      var order = dependencySorter.sort(artboard.root);
      expect(orderString(order), equals('Unnamed A E'));
      expect(dependencySorter.cycleNodes, containsAll([nodeB, nodeC, nodeD]));
      expect(dependencySorter.cycleNodes, contains(nodeF),
          skip: "Node F is isolated by a cycle, and does not "
              " exist in 'order' or in 'cycleNodes'");
    });
  });

  group("Complex Cycle C, F is not isolated:", () {
    ActorArtboard artboard;

    final actor = DummyActor();
    artboard = ActorArtboard(actor);
    final nodeA = ActorNode()..name = 'A';
    final nodeB = ActorNode()..name = 'B';
    final nodeC = ActorNode()..name = 'C';
    final nodeD = ActorNode()..name = 'D';
    final nodeE = ActorNode()..name = 'E';
    final nodeF = ActorNode()..name = 'F';

    ///
    ///                   +---------------+
    ///                   |               |
    ///                   |     [F]---+   |
    ///                   |      v    |   v
    /// [root] <- [A] <- [B] <- [C] <-+- [D]
    ///            A             |    |
    ///            |             |    |
    ///           [E]<-----------+    |
    ///            A                  |
    ///            +------------------+
    artboard.addDependency(nodeA, artboard.root);
    artboard.addDependency(nodeB, nodeA);
    artboard.addDependency(nodeC, nodeB);
    artboard.addDependency(nodeD, nodeC);
    artboard.addDependency(nodeB, nodeD);
    artboard.addDependency(nodeE, nodeA);
    artboard.addDependency(nodeC, nodeE);
    artboard.addDependency(nodeF, nodeC);
    artboard.addDependency(nodeF, nodeE);

    test("TarjansDependencySorter orders", () {
      var dependencySorter = TarjansDependencySorter();
      var order = dependencySorter.sort(artboard.root);
      expect(orderString(order), equals('Unnamed A E F'));
      expect(dependencySorter.cycleNodes, containsAll([nodeB, nodeC, nodeD]));
    });
  });
}
