import 'package:checkbox/smiley_switch.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final List<bool> options = [false, true, false, true, true];
  bool _snapToEnd = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: options
                  .asMap()
                  .map((i, isOn) => MapEntry(
                      i,
                      SmileySwitch(isOn, snapToEnd: _snapToEnd, onToggle: () {
                        setState(() {
                          _snapToEnd = false;
                          options[i] = !isOn;
                        });
                      })))
                  .values
                  .toList()
                  .cast<Widget>() +
              [
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  color: Colors.pinkAccent,
                  child: const Text('Back'),
                )
              ],
        ),
      ),
    );
  }
}
