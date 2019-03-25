import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/settings');
              },
              color: Colors.pinkAccent,
              child: const Text('Settings'),
            )
          ],
        ),
      ),
    );
  }
}
