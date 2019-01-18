import 'package:flutter/material.dart';
import 'package:favorite/buttons_row.dart';

class PageAbout extends StatelessWidget {
  const PageAbout({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: 
                [
                    ButtonsRow(),
                    Container(
                        height: 0.75,
                        color: const Color.fromRGBO(151, 151, 151, 0.29),
                        margin: const EdgeInsets.symmetric(horizontal: 18.0)
                    ),
                    Container(
                        margin: const EdgeInsets.all(18.0),
                        child: Text("About",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                fontFamily: "Montserrat"
                            )
                        )
                    ),
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: SingleChildScrollView(
                              child: Text(
"""Cheyenne is a wealthy former rock star, now bored and jaded in his 20-year retirement in Dublin. He retired after two of his teenaged fans committed suicide. He travels to New York to reconcile with his estranged father during his final hours, only to arrive too late. The reason he gives for not communicating with his father for 30 years was that his father rejected him when he put on goth make-up at the age of 15. He reads his father's diary and learns about his father's persecution in Auschwitz at the hands of former SS officer Alois Lange. He visits a professional Nazi hunter named Mordecai Midler who tells him that Lange is small fry.

Cheyenne begins a journey across the United States to track down Lange. Cheyenne finds the wife of Lange, Lange's granddaughter and a businessman. He buys a large gun. At the gun shop, a bystander delivers a soliloquy about a certain type of pistol that allows people to "kill with impunity," and given that ability, "if we’re licensed to be monsters we end up having just one desire – to truly be monsters."

When Cheyenne eventually tracks Lange down with the aid of Mordecai, Lange, now blind, says that he received hate mail from Cheyenne's father for decades. Lange recounts the incident that led to Cheyenne's father's obsession with Lange, in which Cheyenne's father peed his pants from fear; Lange describes this as a "minor incident" in comparison to the true horrors of Auschwitz, but mentions that he came to admire the man's single-minded determination to dedicate his life to making his own miserable. Cheyenne takes a photo of Lange and whispers that it was an injustice for his father to die before Lange did. Cheyenne forces the old blind man to walk out into the salt flats naked, like a Holocaust victim; skin and bones and numb with fear. Cheyenne and Mordecai drive away soon afterwards, leaving him still standing in the flats.

Cheyenne travels home via airplane (something he had previously had a strong phobia of), cuts his rockstar hair and stops wearing his goth make-up, jewelry and outfits.""",
                                  style: TextStyle(
                                          color: Colors.black45,
                                          fontSize: 14.0,
                                          fontFamily: "Montserrat",
                                          height: 1.4
                                      )
                              )
                          ),
                        )
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children:
                        [
                            Container(
                                margin: const EdgeInsets.only(top: 18),
                                child: RaisedButton(
                                    onPressed: () => {},
                                    elevation: 0,
                                    child: Text("Read Now",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Montserrat",
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13
                                        )
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical:18),
                                    color: const Color.fromARGB(255, 2, 101, 252)
                                )
                            )
                        ]
                    )
                ]
            )
    );
  }
}