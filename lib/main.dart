import 'package:flutter/material.dart';
import 'sign_in.dart';
import 'introduction/introduction.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proud Me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          secondary: Color(0xfff5b342)
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Introduction()
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
