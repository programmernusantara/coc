import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Class Of Bakid'),
          centerTitle: true,
          backgroundColor: Colors.blue[500],
        ),
        body: Center(child: Text('GAME (1)')),
      ),
    );
  }
}
