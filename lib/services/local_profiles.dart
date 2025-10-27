import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalProfiles {
  static const _kSeeded = 'profiles_seeded_v1';
  static const _kCurrentUserId = 'current_user_id';
  static const _kProfilePrefix = 'profile_'; // profile_<id>

  static final LocalProfiles _instance = LocalProfiles._internal();
  LocalProfiles._internal();
  factory LocalProfiles() => _instance;

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  /// Körs 1 gång: skapar två lokala profiler
  Future<void> seedIfNeeded() async {
    final p = await _prefs;
    if (p.getBool(_kSeeded) == true) return;

    await _saveProfile('alex', {
      'id': 'alex',
      'name': 'Alex Andersson',
      'email': 'alex.andersson@email.se',
      'moodCount': 0,
    });

    await _saveProfile('maya', {
      'id': 'maya',
      'name': 'Maya Nilsson',
      'email': 'maya.nilsson@email.se',
      'moodCount': 0,
    });

    await p.setBool(_kSeeded, true);
    await p.setString(_kCurrentUserId, 'alex'); // starta som Alex
  }

  Future<Map<String, dynamic>?> _getProfile(String id) async {
    final p = await _prefs;
    final raw = p.getString('$_kProfilePrefix$id');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveProfile(String id, Map<String, dynamic> data) async {
    final p = await _prefs;
    await p.setString('$_kProfilePrefix$id', jsonEncode(data));
  }

  Future<Map<String, Map<String, dynamic>>> getAllProfiles() async {
    final alex = await _getProfile('alex');
    final maya = await _getProfile('maya');
    return {
      if (alex != null) 'alex': alex,
      if (maya != null) 'maya': maya,
    };
  }

  Future<String?> getCurrentUserId() async {
    final p = await _prefs;
    return p.getString(_kCurrentUserId);
  }

  Future<void> setCurrentUserId(String? id) async {
    final p = await _prefs;
    if (id == null) {
      await p.remove(_kCurrentUserId);
    } else {
      await p.setString(_kCurrentUserId, id);
    }
  }

  Future<void> incrementMoodCount(String userId) async {
    final prof = await _getProfile(userId);
    if (prof == null) return;
    final c = (prof['moodCount'] ?? 0) as int;
    prof['moodCount'] = c + 1;
    await _saveProfile(userId, prof);
  }
}