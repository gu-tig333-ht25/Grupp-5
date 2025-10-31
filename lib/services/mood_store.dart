// lib/services/mood_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../models/mood_entry.dart';
import '../services/local_profiles.dart';
import '../services/weather_service.dart';
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

    // Migrera ev. gamla data
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

    parsed.sort((a, b) => a.date.compareTo(b.date)); // ↑ sortera stigande
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
    list.sort((a, b) => a.date.compareTo(b.date));
    _byUser[_currentUserId] = list;

    await prefs.setString(
      key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  /// Lägg till flera poster i en skrivning (snabbare seed/backfill).
  Future<void> addAll(List<MoodEntry> newEntries) async {
    if (newEntries.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'mood_entries_$_currentUserId';

    final list = List<MoodEntry>.from(_byUser[_currentUserId] ?? const []);
    list.addAll(newEntries);
    list.sort((a, b) => a.date.compareTo(b.date));
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
    list.removeWhere(
      (e) =>
          e.date.toIso8601String() == entry.toJson()['date'] &&
          e.emoji == entry.emoji &&
          e.note == entry.note &&
          e.position.latitude == entry.position.latitude &&
          e.position.longitude == entry.position.longitude,
    );
    list.sort((a, b) => a.date.compareTo(b.date));
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
    SharedPreferences prefs,
    String key,
  ) async {
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

  /// Logga nytt humörinlägg med plats och väder (nu).
  Future<void> logMoodWithLocationAndWeather({
    required String emoji,
    required String note,
  }) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final weather = await WeatherService.fetchCurrent(
        LatLng(pos.latitude, pos.longitude),
      );

      final entry = MoodEntry(
        kind: EntryKind.map,
        emoji: emoji,
        note: note.trim().isEmpty ? '(Ingen anteckning)' : note.trim(),
        date: DateTime.now().toUtc(),
        position: LatLng(pos.latitude, pos.longitude),
        weather: weather,
      );

      await add(entry);
    } catch (e) {
      debugPrint('Kunde inte logga humör: $e');
      rethrow;
    }
  }

  /// Kolla om veckan redan har några loggar (lokal tid).
  bool hasAnyThisWeek(DateTime weekStartLocal) {
    final weekEndLocal = weekStartLocal.add(const Duration(days: 6));
    return entries.any((e) {
      final l = e.date.isUtc ? e.date.toLocal() : e.date;
      final d = DateTime(l.year, l.month, l.day);
      return !d.isBefore(weekStartLocal) && !d.isAfter(weekEndLocal);
    });
  }

  /// (Valfritt) Seeda denna vecka mån–ons så grafen visar variation direkt.
  Future<void> seedThisWeekDemo({
    required DateTime weekStartLocal, // måndag lokal tid
    String monEmoji = '😄',
    String tueEmoji = '😐',
    String wedEmoji = '😡',
  }) async {
    // skydda mot dubbletter
    if (hasAnyThisWeek(weekStartLocal)) return;

    const gothenburg = LatLng(57.7089, 11.9746);

    DateTime noonLocal(int addDays) => DateTime(
      weekStartLocal.year,
      weekStartLocal.month,
      weekStartLocal.day + addDays,
      12,
      0,
      0,
    );

    // konvertera tydligt från lokal till UTC
    DateTime toUtc(DateTime local) => local.toLocal().toUtc();

    final seeds = <MoodEntry>[
      MoodEntry(
        kind: EntryKind.map,
        emoji: monEmoji,
        note: '(Seed) Måndag',
        date: toUtc(noonLocal(0)),
        position: gothenburg,
        weather: null,
      ),
      MoodEntry(
        kind: EntryKind.map,
        emoji: tueEmoji,
        note: '(Seed) Tisdag',
        date: toUtc(noonLocal(1)),
        position: gothenburg,
        weather: null,
      ),
      MoodEntry(
        kind: EntryKind.map,
        emoji: wedEmoji,
        note: '(Seed) Onsdag',
        date: toUtc(noonLocal(2)),
        position: gothenburg,
        weather: null,
      ),
    ];

    await addAll(seeds);
  }
}
