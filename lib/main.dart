import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/mood_log_page.dart';
import 'screens/map_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profil.dart';

void main() {
  runApp(const MoodMapApp());
}

class MoodMapApp extends StatefulWidget {
  const MoodMapApp({super.key});

  @override
  State<MoodMapApp> createState() => _MoodMapAppState();
}

class _MoodMapAppState extends State<MoodMapApp> {
  bool _isDarkMode = false;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigationPage(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const MainNavigationPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),      // Startsida
      const MoodLogPage(),     // Logga humör
      const MapScreen(),       // Karta
      const StatistikPage(),     // Statistik
      ProfilePage(             // Profil
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Hem'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_outlined), label: 'Logga'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Karta'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Statistik'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
