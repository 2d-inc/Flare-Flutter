import 'package:flutter/material.dart';
import 'package:favorite/buttons_row.dart';

class PageAbout extends StatelessWidget {
  const PageAbout({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: 
                [
                    ButtonsRow(),
                    Container(
                        height: 0.75,
                        color: const Color.fromRGBO(151, 151, 151, 0.29)
                    ),
                    Container(
                        margin: const EdgeInsets.symmetric(vertical: 18.0),
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
                        child: SingleChildScrollView(
                            child: Text("Piccolo romanzo on the road, manuale sentimentale di classici rock, retrospettiva appassionata di cinematografia. Nella breve fuga improvvisata di un giovane impiegato di un mobilificio, si compongono i tasselli di una società schizofrenica, governata dalla iper-razionalità dei numeri e da un utilitarismo sfrenato. Partendo da un pretesto prettamente cinematografico - il furto di una valigetta presumibilmente piena di soldi - si dipanano disavventure e inseguimenti rocamboleschi. Sullo sfondo, lungi dai grandi spazi western, le strade e i dirupi della maremma toscana si prestano a un'odissea minimal, mentre Radio Maremma Rock passa i pezzi che hanno fatto la storia della musica internazionale. Con la sua fuga poco convenzionale, Giacomo, donchisciotte moderno, si fa beffe delle regole di tutti i giorni per concedersi al sogno più coraggioso: quello di rendere felici chi ci è accanto.",
                                style: TextStyle(
                                        color: Colors.black45,
                                        fontSize: 14.0,
                                        fontFamily: "Montserrat",
                                        height: 1.4
                                    )
                            )
                        )
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children:
                        [
                            Container(
                                margin: const EdgeInsets.only(top: 18),
                                child: RaisedButton(
                                    onPressed: () => print("READ!"),
                                    elevation: 0,
                                    child: Text("Read Now",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "Montserrat",
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12
                                        )
                                    ),
                                    padding: const EdgeInsets.all(15),
                                    color: const Color.fromARGB(255, 2, 101, 252),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7.5)
                                    )
                                ),
                            )
                        ]
                    )
                ],
            )
        )
    );
  }
}