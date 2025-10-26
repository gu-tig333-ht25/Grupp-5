import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/mood_store.dart';
import '../models/mood_entry.dart';
import '../services/weather_service.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  // ---- Quick log (överst) ----
  static const LatLng _fallbackCenter = LatLng(57.7089, 11.9746); // Göteborg
  Weather? _weather;
  bool _loadingWeather = true;

  // ---- Legacy-delen ----
  static const _legacyKey = 'mood_logs';
  final List<_LegacyLog> _legacy = [];
  bool _loadingLegacy = true;
  bool _migrating = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadLegacy();
  }

  Future<void> _loadWeather() async {
    try {
      final w = await WeatherService.fetchCurrent(_fallbackCenter);
      if (!mounted) return;
      setState(() {
        _weather = w;
        _loadingWeather = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWeather = false);
    }
  }

  Future<void> _loadLegacy() async {
    setState(() => _loadingLegacy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_legacyKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded.cast<Map<String, dynamic>>();
          _legacy
            ..clear()
            ..addAll(list.map(_LegacyLog.fromJson));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunde inte läsa gamla poster: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLegacy = false);
    }
  }

  Future<void> _migrateLegacyToStore() async {
    if (_legacy.isEmpty || _migrating) return;
    setState(() => _migrating = true);
    try {
      final store = context.read<MoodStore>();

      for (final l in _legacy) {
        final parsed = _parseLegacyWeather(l.weather);
        final entry = MoodEntry(
          kind: EntryKind.map, // tolka gamla som kartloggar
          emoji: _emojiFromScore(l.mood),
          note: l.note.isEmpty ? '(Ingen anteckning)' : l.note,
          date: l.createdAt ?? DateTime.now(),
          position: _fallbackCenter,
          weather: parsed,
        );
        await store.add(entry);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKey);

      if (!mounted) return;
      setState(() => _legacy.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gamla poster har migrerats ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Migrering misslyckades: $e')),
      );
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  // Quick save från rutan längst upp
  Future<void> _onQuickSave(String note) async {
    final weather = _weather ?? Weather(temperatureC: 0, windSpeed: 0, weatherCode: 3);
    final entry = MoodEntry(
      kind: EntryKind.home, // 👈 hemlogg
      emoji: '🙂',
      note: note.trim().isEmpty ? '(Ingen anteckning)' : note.trim(),
      date: DateTime.now(),
      position: _fallbackCenter,
      weather: weather,
    );
    await context.read<MoodStore>().add(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Humör sparat ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = context.watch<MoodStore>().entries.reversed.toList();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Dela upp loggar efter typ
    final homeEntries = allEntries.where((e) => e.kind == EntryKind.home).toList();
    final mapEntries  = allEntries.where((e) => e.kind == EntryKind.map ).toList();

    final legacyCount = _legacy.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Humörlogg')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Quick log-kort ----------
          _QuickLogCard(
            isLoadingWeather: _loadingWeather,
            onSave: _onQuickSave,
          ),

          const SizedBox(height: 20),

          // 🏠 Hemloggar (utan emoji)
          _SectionHeader(text: 'Hemloggar (${homeEntries.length})'),
          if (homeEntries.isEmpty)
            const _EmptyHint(text: 'Inga hem-loggar ännu.')
          else
            ...homeEntries.map((m) => _EntryCard.fromMoodEntry(m, theme)),

          const SizedBox(height: 24),

          // 🗺️ Kartloggar (med emoji)
          _SectionHeader(text: 'Kartloggar (${mapEntries.length})'),
          if (mapEntries.isEmpty)
            const _EmptyHint(text: 'Inga kartloggar ännu.')
          else
            ...mapEntries.map((m) => _EntryCard.fromMoodEntry(m, theme)),

          const SizedBox(height: 24),

          // ⏳ Gamla (legacy)
          _SectionHeader(text: 'Gamla loggar ($legacyCount)'),
          if (_loadingLegacy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (legacyCount == 0)
            const _EmptyHint(text: 'Inga gamla poster hittades.')
          else
            ..._legacy.map((l) => _EntryCard.fromLegacy(l, theme)),

          if (legacyCount > 0) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _migrating ? null : _migrateLegacyToStore,
              icon: _migrating
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.publish),
              label: Text(_migrating ? 'Migrerar gamla poster…' : 'Migrera gamla poster'),
            ),
          ],
        ],
      ),
    );
  }
}

// ===== Quick-log widget =====
class _QuickLogCard extends StatefulWidget {
  final bool isLoadingWeather;
  final Future<void> Function(String note) onSave;

  const _QuickLogCard({
    required this.isLoadingWeather,
    required this.onSave,
  });

  @override
  State<_QuickLogCard> createState() => _QuickLogCardState();
}

class _QuickLogCardState extends State<_QuickLogCard> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final note = _ctrl.text.trim();
    if (note.isEmpty || _saving) return;
    setState(() => _saving = true);
    await widget.onSave(note);
    if (!mounted) return;
    setState(() => _saving = false);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hur mår du idag?',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Skriv en anteckning om ditt humör…',
              filled: true,
              fillColor: cs.surfaceVariant,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: cs.primary),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (widget.isLoadingWeather)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _handleSave,
                child: Text(_saving ? 'Sparar…' : 'Spara'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Hjälpfunktioner (top-level) =====

String _emojiFromScore(int score) {
  const emojis = ["😭","😫","😢","☹️","🙁","😐","🙂","😊","😄","😃","😁"];
  final i = score.clamp(0, 10).toInt();
  return emojis[i];
}

Weather _parseLegacyWeather(String? text) {
  if (text == null || text.trim().isEmpty) {
    return Weather(temperatureC: 0, windSpeed: 0, weatherCode: 3);
  }
  final tempMatch = RegExp(r'(-?\d+)(?:[.,]\d+)?\s*°').firstMatch(text);
  final temp =
      tempMatch != null ? double.tryParse(tempMatch.group(1)!)?.toDouble() ?? 0.0 : 0.0;

  final t = text.toLowerCase();
  int code = 0; // klart
  if (t.contains('moln')) code = 3; // mulet
  if (t.contains('regn')) code = 61;
  if (t.contains('snö')) code = 71;
  if (t.contains('dim')) code = 45;
  if (t.contains('åsk') || t.contains('blixt')) code = 95;

  return Weather(temperatureC: temp, windSpeed: 0, weatherCode: code);
}

// ----- UI-hjälpklasser -----

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: tt.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Widget child;
  const _EntryCard(this.child);

  // 👉 Emoji visas ENDAST när det är en kartlogg
  factory _EntryCard.fromMoodEntry(MoodEntry m, ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final showEmoji = m.kind == EntryKind.map;

    return _EntryCard(
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showEmoji) ...[
                Text(m.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d MMM yyyy HH:mm', 'sv_SE').format(m.date),
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.note.isEmpty ? '(Ingen anteckning)' : m.note,
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.wb_sunny, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${m.weather.shortDescription} • '
                            '${m.weather.temperatureC.toStringAsFixed(0)}°C • '
                            'Vind ${m.weather.windSpeed.toStringAsFixed(0)} m/s',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 16, color: cs.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Lat ${m.position.latitude.toStringAsFixed(5)}, '
                          'Lng ${m.position.longitude.toStringAsFixed(5)}',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  factory _EntryCard.fromLegacy(_LegacyLog l, ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final created = l.createdAt != null
        ? DateFormat('d MMM yyyy HH:mm', 'sv_SE').format(l.createdAt!)
        : '(okänt datum)';
    final sub = [
      if (l.location.isNotEmpty) '📍 ${l.location}',
      if (l.weather.isNotEmpty) '☁️ ${l.weather}',
    ].join('  •  ');

    return _EntryCard(
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_emojiFromScore(l.mood), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(created,
                        style: tt.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 6),
                    Text(l.note.isEmpty ? '(Ingen anteckning)' : l.note,
                        style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
                    const SizedBox(height: 8),
                    if (sub.isNotEmpty)
                      Text(sub, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(
                      '(Gammal post • visas tills du migrerar)',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => child;
}

// ----- Legacy-modell -----

class _LegacyLog {
  final int mood;
  final String note;
  final String location;
  final String weather;
  final DateTime? createdAt;

  _LegacyLog({
    required this.mood,
    required this.note,
    required this.location,
    required this.weather,
    this.createdAt,
  });

  factory _LegacyLog.fromJson(Map<String, dynamic> json) {
    final dynamic rawMood = json['mood'] ?? 0;
    int parsedMood;
    if (rawMood is int) {
      parsedMood = rawMood;
    } else if (rawMood is num) {
      parsedMood = rawMood.round();
    } else {
      parsedMood = int.tryParse(rawMood.toString()) ?? 0;
    }

    return _LegacyLog(
      mood: parsedMood,
      note: (json['note'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      weather: (json['weather'] ?? '') as String,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    );
  }
}
