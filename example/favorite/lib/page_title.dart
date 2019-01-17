import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  const PageTitle({
    Key key,
    @required this.titleWidth,
    @required this.titleHeight,
  }) : super(key: key);

  final double titleWidth;
  final double titleHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
            margin: EdgeInsets.only(left: titleWidth),
            width: titleWidth,
            height: titleHeight,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                [
                    Text(
                        "This Must Be\nthe Place",
                        style: TextStyle(
                            fontFamily: "Montserrat",
                            fontSize: 20, 
                            fontWeight: FontWeight.bold
                        ),
                    ),
                    Container(
                        margin: const EdgeInsets.only(top: 18, bottom: 36),
                        child: Text(
                            "By Paolo Sorrentino",
                            style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 12.0,
                                color: Colors.black45
                            ),
                        ),
                    ),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:
                        [
                            Text("1042 ",
                                style: TextStyle(
                                    color: const Color.fromARGB(255, 2, 101, 252),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Montserrat",
                                    fontSize: 12.0,
                                ),
                                ),
                            Text("Views",
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontFamily: "Montserrat",
                                    fontSize: 12.0,
                                )
                            ),
                            Container(
                                margin: const EdgeInsets.only(left: 18),
                                child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black45)
                            )
                        ]
                    )
                ]
            )
        );
  }
}