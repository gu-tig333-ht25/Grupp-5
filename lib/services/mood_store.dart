import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../models/mood_entry.dart';
import '../services/local_profiles.dart';
import '../services/weather_service.dart'; // ✅ vi använder denna nu
import '../models/weather.dart';
import 'package:geolocator/geolocator.dart';

class MoodStore extends ChangeNotifier {
  final LocalProfiles _profiles = LocalProfiles();
  final Map<String, List<MoodEntry>> _byUser = {};

  String _currentUserId = 'alex';

  List<MoodEntry> get entries =>
      List.unmodifiable(_byUser[_currentUserId] ?? const []);

  /// Ladda loggar för aktiv användare.
  Future<void> load() async {
    final uid = await _profiles.getCurrentUserId() ?? 'alex';
    _currentUserId = uid;

    final prefs = await SharedPreferences.getInstance();
    final perUserKey = 'mood_entries_$uid';
    List<MoodEntry> parsed = await _readListSafely(prefs, perUserKey);

    // Försök migrera gamla data
    if (parsed.isEmpty) {
      const oldKey = 'mood_entries_v1';
      final migrated = await _readListSafely(prefs, oldKey);
      if (migrated.isNotEmpty) {
        await prefs.setString(
          perUserKey,
          jsonEncode(migrated.map((e) => e.toJson()).toList()),
        );
        await prefs.remove(oldKey);
        parsed = migrated;
      }
    }

    _byUser[uid] = parsed;
    notifyListeners();
  }

  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    await load();
  }

  Future<void> add(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mood_entries_$_currentUserId';

    final list = List<MoodEntry>.from(_byUser[_currentUserId] ?? const []);
    list.add(entry);
    _byUser[_currentUserId] = list;

    await prefs.setString(
      key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> remove(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mood_entries_$_currentUserId';

    final list = List<MoodEntry>.from(_byUser[_currentUserId] ?? const []);
    list.remove(entry);
    _byUser[_currentUserId] = list;

    await prefs.setString(
      key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    _byUser[_currentUserId] = [];
    notifyListeners();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mood_entries_$_currentUserId');
    _byUser[_currentUserId] = [];
    notifyListeners();
  }

  // ------- helpers -------
  Future<List<MoodEntry>> _readListSafely(
      SharedPreferences prefs, String key) async {
    try {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final out = <MoodEntry>[];
      for (final item in decoded) {
        try {
          final map = (item as Map).cast<String, dynamic>();
          map.putIfAbsent('kind', () => 'map'); // bakåtkomp
          out.add(MoodEntry.fromJson(map));
        } catch (e) {
          debugPrint('Hoppar över trasig post i $key: $e');
        }
      }
      return out;
    } catch (e) {
      debugPrint('Kunde inte läsa $key: $e');
      return [];
    }
  }

  /// Logga nytt humörinlägg med plats och väder.
  Future<void> logMoodWithLocationAndWeather({
    required String emoji,
    required String note,
  }) async {
    try {
      // 🔹 Hämta nuvarande plats
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 🔹 Hämta aktuellt väder från OpenWeather (via WeatherService)
      final weather = await WeatherService.fetchCurrent(
        LatLng(pos.latitude, pos.longitude),
      );

      // 🔹 Skapa och spara nytt humörinlägg
      final entry = MoodEntry(
        emoji: emoji,
        note: note.trim().isEmpty ? '(Ingen anteckning)' : note.trim(),
        date: DateTime.now().toUtc(),
        position: LatLng(pos.latitude, pos.longitude),
        weather: weather,
        kind: EntryKind.map,
      );

      await add(entry);
    } catch (e) {
      debugPrint('Kunde inte logga humör: $e');
      rethrow;
    }
  }
}