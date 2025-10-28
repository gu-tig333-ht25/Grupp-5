import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_entry.dart';
import '../services/local_profiles.dart';

class MoodStore extends ChangeNotifier {
  final LocalProfiles _profiles = LocalProfiles();
  final Map<String, List<MoodEntry>> _byUser = {};

  String _currentUserId = 'alex';

  List<MoodEntry> get entries => List.unmodifiable(_byUser[_currentUserId] ?? const []);

  /// Ladda loggar för aktiv användare. Robust mot gamla/trasiga data.
  Future<void> load() async {
    final uid = await _profiles.getCurrentUserId() ?? 'alex';
    _currentUserId = uid;

    final prefs = await SharedPreferences.getInstance();
    final perUserKey = 'mood_entries_$uid';

    // 1) Läs per-användare-nyckeln
    List<MoodEntry> parsed = await _readListSafely(prefs, perUserKey);

    // 2) Om tomt, försök migrera från gammal global nyckel (om den finns)
    if (parsed.isEmpty) {
      const oldKey = 'mood_entries_v1';
      final migrated = await _readListSafely(prefs, oldKey);
      if (migrated.isNotEmpty) {
        // Spara under nya nyckeln och rensa gamla
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

  /// 🔁 Byt aktiv användare och ladda dennes loggar.
  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    await load();
  }

  /// ➕ Lägg till ett nytt humörinlägg.
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

  /// Rensa endast loggar för aktuell användare.
Future<void> clear() async {
  _byUser[_currentUserId] = [];
  notifyListeners();
}

  /// Rensa alla loggar (inkl. från lagring).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mood_entries_$_currentUserId');
    _byUser[_currentUserId] = [];
    notifyListeners();
  }

  // ------- helpers -------

  Future<List<MoodEntry>> _readListSafely(SharedPreferences prefs, String key) async {
    try {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final out = <MoodEntry>[];
      for (final item in decoded) {
        try {
          // Stötta både Map<dynamic,dynamic> och korrekt typ
          final map = (item as Map).cast<String, dynamic>();

          // Bakåtkomp: om 'kind' saknas → anta kartpost (EntryKind.map)
          map.putIfAbsent('kind', () => 'map');

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
}