import 'package:flutter/material.dart';
import 'screens/mood_log_page.dart'; // importera din sida

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MoodLogPage(), // visa DIN sida
  ));
}
