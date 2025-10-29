import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/mood_store.dart';
import 'screens/home_screen.dart';
import 'screens/mood_log_page.dart';
import 'screens/map_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('sv_SE');

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
  int _rebuildKey = 0;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

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
      theme: _lightTheme,
      darkTheme: _darkTheme,
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
        selectedItemColor: Theme.of(context).colorScheme.primary,
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

/* ---------------------- Färgtema från skärmdump ---------------------- */

final _lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFFF9F3),
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFCBAA9C), // knappar etc
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFF3E9),
    onPrimaryContainer: Color(0xFF1E1E1E),

    secondary: Color(0xFFE0D5CD),
    onSecondary: Color(0xFF1E1E1E),
    secondaryContainer: Color(0xFFF3EDE8),
    onSecondaryContainer: Color(0xFF1E1E1E),

    background: Color(0xFFFFF9F3),
    onBackground: Color(0xFF1E1E1E),

    surface: Color(0xFFFFF3E9),
    onSurface: Color(0xFF1E1E1E),

    error: Colors.red,
    onError: Colors.white,
  ),
);

final _darkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF141414),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7D6E69), // knappar etc
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF2D2D2D),
    onPrimaryContainer: Colors.white,

    secondary: Color(0xFF4C4C4C),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF1D1D1D),
    onSecondaryContainer: Color(0xFFEAEAEA),

    background: Color(0xFF141414),
    onBackground: Colors.white,

    surface: Color(0xFF1D1D1D),
    onSurface: Colors.white,

    error: Colors.red,
    onError: Colors.black,
  ),
);
