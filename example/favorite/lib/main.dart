import 'package:flutter/material.dart';
import 'package:favorite/page.dart';

Color twoDGrey = Color.fromRGBO(238, 238, 238, 1);
void main() => runApp(Heart());

class Heart extends StatelessWidget 
{
    @override
    Widget build(BuildContext context) 
    {
        return MaterialApp(
            title: 'Flare + Flutter Demo',
            theme: ThemeData(
                primarySwatch: Colors.grey,
                primaryColor: Colors.white
            ),
            home: Page()
        );
    }
}
