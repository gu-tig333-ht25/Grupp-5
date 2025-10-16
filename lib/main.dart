import 'package:flutter/material.dart';
import 'screens/mood_log_page.dart'; // <--- Importera din sida

void main() {
  runApp(const MoodApp());
}

class MoodApp extends StatelessWidget {
  const MoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mood Map',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const MoodLogPage(), // <--- Din sida visas här
    );
  }
}
