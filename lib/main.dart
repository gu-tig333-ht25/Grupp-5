import 'package:flutter/material.dart';
import 'screens/profil.dart';


void main() => runApp(const MoodMapApp());


class MoodMapApp extends StatefulWidget {
 const MoodMapApp({super.key});


 @override
 State<MoodMapApp> createState() => _MoodMapAppState();
}


class _MoodMapAppState extends State<MoodMapApp> {
 bool _isDarkMode = false;


 void _toggleTheme(bool isDark) {
   setState(() {
     _isDarkMode = isDark;
   });
 }


 @override
 Widget build(BuildContext context) {
   return MaterialApp(
     debugShowCheckedModeBanner: false,
     title: 'MoodMap',
     theme: ThemeData.light(),
     darkTheme: ThemeData.dark(),
     themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,


     // Här berättar du för appen vilka sidor som finns
     initialRoute: '/profil',
     routes: {
       '/profil': (context) => ProfilePage(
             isDarkMode: _isDarkMode,
             onThemeChanged: _toggleTheme,
           ),
       '/':      (context) => const Placeholder(),  // Hem
       '/logga': (context) => const Placeholder(),  // Logga
       '/karta': (context) => const Placeholder(),  // Karta
       '/stat':  (context) => const Placeholder(),  // Statistik
     },
   );
 }
}