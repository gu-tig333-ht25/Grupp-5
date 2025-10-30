import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'mood_log_page.dart';
import 'map_page.dart';
import 'stats_page.dart';
import 'profil.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    MoodLogPage(),
    MapPage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: "Hem"),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: "Logga"),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: "Karta"),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: "Statistik"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'mood_log_page.dart';
import 'map_page.dart';
import 'stats_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    MoodLogPage(),
    MapPage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: "Hem"),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: "Logga"),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: "Karta"),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: "Statistik"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }
}
