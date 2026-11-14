import 'package:flutter/material.dart';
import 'package:flutter_application_f4_mobile/View/Home/home_screen.dart';
//koimport 'package:flutter_application_f4_mobile/View/shoppingcard_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F2 CAMPING',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home:  HomeScreen(),
    );
  }
}