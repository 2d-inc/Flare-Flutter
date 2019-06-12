// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'contacts.dart';

class CupertinoRefreshControlDemo extends StatefulWidget {
  static const String routeName = '/cupertino/refresh';

  @override
  _CupertinoRefreshControlDemoState createState() =>
      _CupertinoRefreshControlDemoState();
}

class _CupertinoRefreshControlDemoState
    extends State<CupertinoRefreshControlDemo> with FlareController {
  List<List<String>> randomizedContacts;

  ActorAnimation _loadingAnimation;
  ActorAnimation _successAnimation;
  ActorAnimation _pullAnimation;
  ActorAnimation _cometAnimation;

  RefreshIndicatorMode _refreshState;
  double _pulledExtent;
  double _refreshTriggerPullDistance;
  double _refreshIndicatorExtent;
  double _successTime = 0.0;
  double _loadingTime = 0.0;
  double _cometTime = 0.0;

  void initialize(FlutterActorArtboard actor) {
    _pullAnimation = actor.getAnimation("pull");
    _successAnimation = actor.getAnimation("success");
    _loadingAnimation = actor.getAnimation("loading");
    _cometAnimation = actor.getAnimation("idle comet");
  }

  void setViewTransform(Mat2D viewTransform) {}

  bool advance(FlutterActorArtboard artboard, double elapsed) {
    double animationPosition = _pulledExtent / _refreshTriggerPullDistance;
    animationPosition *= animationPosition;
    _cometTime += elapsed;
    _cometAnimation.apply(_cometTime % _cometAnimation.duration, artboard, 1.0);
    _pullAnimation.apply(
        _pullAnimation.duration * animationPosition, artboard, 1.0);
    if (_refreshState == RefreshIndicatorMode.refresh ||
        _refreshState == RefreshIndicatorMode.armed) {
      _successTime += elapsed;
      if (_successTime >= _successAnimation.duration) {
        _loadingTime += elapsed;
      }
    } else {
      _successTime = _loadingTime = 0.0;
    }
    if (_successTime >= _successAnimation.duration) {
      _loadingAnimation.apply(
          _loadingTime % _loadingAnimation.duration, artboard, 1.0);
    } else if (_successTime > 0.0) {
      _successAnimation.apply(_successTime, artboard, 1.0);
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    repopulateList();
  }

  void repopulateList() {
    final Random random = Random();
    randomizedContacts = List<List<String>>.generate(100, (int index) {
      return contacts[random.nextInt(contacts.length)]
        // Randomly adds a telephone icon next to the contact or not.
        ..add(random.nextBool().toString());
    });
  }

  Widget buildRefreshWidget(
      BuildContext context,
      RefreshIndicatorMode refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent) {
    _refreshState = refreshState;
    _pulledExtent = pulledExtent;
    _refreshTriggerPullDistance = refreshTriggerPullDistance;
    _refreshIndicatorExtent = refreshIndicatorExtent;

    return FlareActor("assets/Space Demo.flr",
        alignment: Alignment.center,
        animation: "idle",
        fit: BoxFit.cover,
        controller: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: '.SF UI Text',
        inherit: false,
        fontSize: 17.0,
        color: CupertinoColors.black,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverNavigationBar(
                backgroundColor: Color.fromRGBO(110, 90, 160, 1.0),
                middle: Container(height: 0, width: 0),
                largeTitle: IconButton(
                  color: Colors.white,
                  alignment: Alignment.centerLeft,
                  icon: Icon(Icons.menu),
                  onPressed: () {},
                ),
                previousPageTitle: 'Cupertino',
              ),
              CupertinoSliverRefreshControl(
                refreshTriggerPullDistance: 190.0,
                refreshIndicatorExtent: 190.0,
                builder: buildRefreshWidget,
                onRefresh: () {
                  return Future<void>.delayed(const Duration(seconds: 5))
                    ..then<void>((_) {
                      if (mounted) {
                        setState(() => repopulateList());
                      }
                    });
                },
              ),
              SliverSafeArea(
                top: false, // Top safe area is consumed by the navigation bar.
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return ListItem(
                        name: randomizedContacts[index][0],
                        place: randomizedContacts[index][1],
                        date: randomizedContacts[index][2],
                        called: randomizedContacts[index][3] == 'true',
                      );
                    },
                    childCount: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
