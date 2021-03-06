import 'package:flutter/material.dart';
import 'package:view_met/splash.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'View MET',
      theme: ThemeData(
        iconTheme: IconThemeData(
            color: Colors.white
        ),
        primarySwatch: Colors.red,
      ),
      home: SplashPage(),
    );
  }
}
