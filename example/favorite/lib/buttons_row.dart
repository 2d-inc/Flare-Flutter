import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';

class ButtonsRow extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ButtonsState();
}

class _ButtonsState extends State<ButtonsRow> {
  static final double containerSize = 20.0;
  // Wheather this element is a favorite or not.
  bool _isFav = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(children: [
            Container(
                margin: EdgeInsets.only(right: 10),
                child: Icon(Icons.rate_review, size: containerSize + 2)),
            Text(
              "Reviews",
              style: TextStyle(
                  fontSize: 11,
                  fontFamily: "Montserrat",
                  color: Colors.black45),
            ),
          ]),
          GestureDetector(
            onTap: () {
              // Toggle the state:
              // This'll cause this widget to rebuild
              // and the animation will be swapped.
              setState(() {
                _isFav = !_isFav;
              });
            },
            child: Row(children: [
              Container(
                  margin: EdgeInsets.only(right: 10),
                  width: containerSize,
                  height: containerSize,
                  child: FlareActor("assets/Favorite.flr",
                      shouldClip: false,
                      // Play the animation depending on the state.
                      animation:
                          _isFav ? "Favorite" : "Unfavorite" //_animationName
                      )),
              Text(
                "Like",
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: "Montserrat",
                    color: Colors.black45),
              ),
            ]),
          ),
          Row(children: [
            Container(
                margin: EdgeInsets.only(right: 10),
                child: Icon(Icons.share, size: containerSize + 2)),
            Text(
              "Share",
              style: TextStyle(
                  fontSize: 11,
                  fontFamily: "Montserrat",
                  color: Colors.black45),
            ),
          ]),
        ],
      ),
    );
  }
}
