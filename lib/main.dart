import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'services/mood_store.dart';
import 'screens/home_screen.dart';
import 'screens/mood_log_page.dart';
import 'screens/map_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('sv_SE');

  // 🧠 Initiera MoodStore (med profiler)
  final store = MoodStore();
  await store.load();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const MoodMapApp(),
    ),
  );
}

class MoodMapApp extends StatefulWidget {
  const MoodMapApp({super.key});

  @override
  State<MoodMapApp> createState() => _MoodMapAppState();
}

class _MoodMapAppState extends State<MoodMapApp> {
  bool _isDarkMode = false;
  int _rebuildKey = 0; // används för att uppdatera alla sidor vid profilbyte

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  // 🔁 Kallas från ProfilePage när användaren byter konto
  void _onProfileChanged() {
    setState(() {
      _rebuildKey++;
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
        key: ValueKey(_rebuildKey),
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
        onProfileChanged: _onProfileChanged,
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onProfileChanged;

  const MainNavigationPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onProfileChanged,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  void _onItemTapped(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const MoodLogScreen(),
      const MapScreen(),
      const StatistikPage(),
      ProfilePage(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        onProfileChanged: widget.onProfileChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
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