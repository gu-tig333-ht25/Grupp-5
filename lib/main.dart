import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // importerar homescreen

void main() {
  runApp(const MoodMapApp());
}

class MoodMapApp extends StatelessWidget {
  const MoodMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoodMap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Sans-serif',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const HomeScreen(), // startar appen på homescreen 
    );
  }
}
