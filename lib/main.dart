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
      title: "Clash Of Bakid",
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Clash Of Bakid"),
          backgroundColor: Colors.blue,
        ),
        body: Center(child: Text("Game Babak 1")),
      ),
    );
  }
}
