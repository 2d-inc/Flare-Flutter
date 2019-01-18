import 'package:flutter/material.dart';
import 'package:favorite/page_title.dart';
import 'package:favorite/page_about.dart';

class Page extends StatelessWidget
{
    static const double cardWidth = 175;
    static const double cardHeight = 250;
    static const double titleWidth = 160;
    static const double titleHeight = 200;
    
    @override
    Widget build(BuildContext context)
    {
        return Scaffold(
                backgroundColor: Colors.white,
                body: SafeArea(
                        top: true,
                        bottom:  false,
                        child: Stack(
                        children: 
                        [
                            Container(
                                margin: const EdgeInsets.only(top:60, left:30),
                                color: const Color.fromRGBO(245, 245, 245, 1),
                                padding: const EdgeInsets.only(top: 18.0),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: 
                                    [
                                        Expanded(
                                            child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children:
                                                [
                                                    Expanded(
                                                        child: Column(
                                                            children: 
                                                            [
                                                                PageTitle(titleWidth: titleWidth, titleHeight: titleHeight),
                                                                PageAbout()
                                                            ],
                                                        ),
                                                    )
                                                ]
                                            )
                                        )
                                    ]
                                ),
                            ),
                            Positioned(
                                top: 20,
                                left: 20,
                                child: Container(
                                    width: cardWidth,
                                    height: cardHeight,
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage("assets/copertina.jpg"),
                                            fit: BoxFit.cover
                                        ),
                                        borderRadius: BorderRadius.circular(7.5),
                                        boxShadow: 
                                        [
                                            BoxShadow(
                                                color: Colors.black45,
                                                offset: const Offset(5,5),
                                                blurRadius: 20
                                            )
                                        ]
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
        );
    }
}