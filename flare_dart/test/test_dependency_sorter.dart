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

    setUp(() async {
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
    });

    test("DependencySorter stops on cycle", () {
      expect(DependencySorter().sort(artboard.root), equals(null));
    });

    test("CycleDependencySorter produces best guess exluding cycle nodes", () {
      var order = CycleDependencySorter().sort(artboard.root);
      expect(order.length, equals(3));
      expect(orderString(order), equals('Unnamed A C'));
    });
  });
  group("No cycle, but double dependants", () {
    ActorArtboard artboard;

    setUp(() async {
      final actor = DummyActor();
      artboard = ActorArtboard(actor);
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
    });

    test("DependencySorter is ok", () {
      var order = DependencySorter().sort(artboard.root);
      expect(order, isNotNull);
      expect(orderString(order), 'Unnamed A B C D');
    });

    test("CycleDependencySorter is ok", () {
      var order = CycleDependencySorter().sort(artboard.root);
      expect(order, isNotNull);
      expect(order.length, equals(5));
      expect(orderString(order), equals('Unnamed A B D C'));
    });
  });

  group("Complex Cycle", () {
    ActorArtboard artboard;

    setUp(() async {
      final actor = DummyActor();
      artboard = ActorArtboard(actor);
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
    });

    test("DependencySorter is ok", () {
      expect(DependencySorter().sort(artboard.root), equals(null));
    });

    test("CycleDependencySorter is ok", () {
      var order = CycleDependencySorter().sort(artboard.root);
      expect(order, isNotNull);
      expect(order.length, equals(3));
      expect(orderString(order), equals('Unnamed A C'));
    });
  });

  group("Bad Cycle", () {
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

    test("CycleDependencySorter expected [root A E]", () {
      final actor = DummyActor();
      final artboard = ActorArtboard(actor);
      final nodeA = ActorNode()..name = 'A';
      final nodeB = ActorNode()..name = 'B';
      final nodeC = ActorNode()..name = 'C';
      final nodeD = ActorNode()..name = 'D';
      final nodeE = ActorNode()..name = 'E';
      final nodeF = ActorNode()..name = 'F';

      artboard.addDependency(nodeA, artboard.root);
      artboard.addDependency(nodeB, nodeA);
      artboard.addDependency(nodeC, nodeB);
      artboard.addDependency(nodeD, nodeC);
      artboard.addDependency(nodeB, nodeD);
      artboard.addDependency(nodeE, nodeA);
      artboard.addDependency(nodeC, nodeE);
      artboard.addDependency(nodeF, nodeC);
      var dependencySorter = CycleDependencySorter();
      var order = dependencySorter.sort(artboard.root);
      expect(order, isNotNull);
      expect(order.length, equals(3));
      expect(orderString(order), equals('Unnamed A E'));
      expect(dependencySorter.cycleNodes,
          containsAll([nodeB, nodeC, nodeD, nodeF]),
          skip: "CycleNodes will not include F, as it was"
              " found to be dependant on a cycle before being evaluated.");
    });

    test("CycleDependencySorter reorderd expected [root A E]", () {
      final actor = DummyActor();
      final artboard = ActorArtboard(actor);
      final nodeA = ActorNode()..name = 'A';
      final nodeB = ActorNode()..name = 'B';
      final nodeC = ActorNode()..name = 'C';
      final nodeD = ActorNode()..name = 'D';
      final nodeE = ActorNode()..name = 'E';
      final nodeF = ActorNode()..name = 'F';

      artboard.addDependency(nodeA, artboard.root);
      artboard.addDependency(nodeE, nodeA);
      artboard.addDependency(nodeC, nodeE);
      artboard.addDependency(nodeF, nodeC);
      artboard.addDependency(nodeB, nodeA);
      artboard.addDependency(nodeC, nodeB);
      artboard.addDependency(nodeD, nodeC);
      artboard.addDependency(nodeB, nodeD);
      var dependencySorter = CycleDependencySorter();
      var order = dependencySorter.sort(artboard.root);
      expect(order, isNotNull);
      expect(order.length, equals(3));
      expect(orderString(order), equals('Unnamed A E'));
      expect(dependencySorter.cycleNodes,
          containsAll([nodeB, nodeC, nodeD, nodeF]));
    });
  });
}
