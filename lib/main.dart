// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/maps.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C1325),
      ),
      home: MapScreen(),
    );
  }
}




