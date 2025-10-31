// lib/screens/mood_log_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/mood_store.dart';
import '../models/mood_entry.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  static const LatLng _fallbackCenter = LatLng(57.7089, 11.9746); // Göteborg
  Weather? _weather;
  bool _loadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
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

  // ⬇️ NYTT: ta emot emoji från snabbloggen
  Future<void> _onQuickSave(String note, String emoji) async {
    final weather = _weather ?? Weather.unknown();
    final entry = MoodEntry(
      kind: EntryKind.home,
      emoji: emoji,
      note: note.trim().isEmpty ? '(Ingen anteckning)' : note.trim(),
      date: DateTime.now().toUtc(), // spara konsekvent i UTC
      position: _fallbackCenter,
      weather: weather,
    );
    await context.read<MoodStore>().add(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Humör sparat!')));
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = context.watch<MoodStore>().entries.reversed.toList();
    final theme = Theme.of(context);

    final homeEntries = allEntries
        .where((e) => e.kind == EntryKind.home)
        .toList();
    final mapEntries = allEntries
        .where((e) => e.kind == EntryKind.map)
        .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Humörlogg')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _QuickLogCard(
              isLoadingWeather: _loadingWeather,
              onSave: _onQuickSave, // ⬅️ skickar vidare till metoden ovan
            ),
            const SizedBox(height: 20),
            _SectionHeader(text: 'Hemloggar (${homeEntries.length})'),
            if (homeEntries.isEmpty)
              const _EmptyHint(text: 'Inga hem-loggar ännu.')
            else
              ...homeEntries.map((m) => _EntryCard.fromMoodEntry(m, theme)),
            const SizedBox(height: 24),
            _SectionHeader(text: 'Kartloggar (${mapEntries.length})'),
            if (mapEntries.isEmpty)
              const _EmptyHint(text: 'Inga kartloggar ännu.')
            else
              ...mapEntries.map((m) => _EntryCard.fromMoodEntry(m, theme)),
          ],
        ),
      ),
    );
  }
}

class _QuickLogCard extends StatefulWidget {
  // ⬇️ ändrat: onSave tar även emoji
  final Future<void> Function(String note, String emoji) onSave;
  final bool isLoadingWeather;

  const _QuickLogCard({required this.isLoadingWeather, required this.onSave});

  @override
  State<_QuickLogCard> createState() => _QuickLogCardState();
}

class _QuickLogCardState extends State<_QuickLogCard> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  // ⬇️ NYTT: valbar emoji för snabbloggen
  final List<String> _choices = ['😔', '😐', '😄'];
  String _selected = '😐';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final note = _ctrl.text.trim();
    if (note.isEmpty || _saving) return;
    setState(() => _saving = true);
    await widget.onSave(note, _selected);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
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
          Text(
            'Hur mår du idag?',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          // ⬇️ NYTT: Emoji-väljare (lågt / medel / högt)
          Row(
            children: _choices.map((e) {
              final bool active = e == _selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e, style: const TextStyle(fontSize: 16)),
                  selected: active,
                  onSelected: (_) => setState(() => _selected = e),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Skriv en anteckning om ditt humör…',
              filled: true,
              fillColor: cs.surfaceContainerHighest,
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
        color: cs.surfaceContainerHighest,
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

class _EntryCard extends StatefulWidget {
  final MoodEntry mood;
  const _EntryCard(this.mood);

  factory _EntryCard.fromMoodEntry(MoodEntry m, ThemeData theme) {
    return _EntryCard(m);
  }

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _loadLocationName();
  }

  Future<void> _loadLocationName() async {
    try {
      final name = await LocationService.reverseGeocode(widget.mood.position);
      if (!mounted) return;
      setState(() => _locationName = name);
    } catch (_) {
      setState(() => _locationName = 'Okänd plats');
    }
  }

  void _confirmDelete(BuildContext context, MoodEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort logg'),
        content: const Text(
          'Är du säker på att du vill ta bort detta humörinlägg?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final store = context.read<MoodStore>();
      store.remove(entry);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inlägg borttaget!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mood;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final showEmoji = m.kind == EntryKind.map;

    final weather = m.weather ?? Weather.unknown();

    return Card(
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
                  /// Datum + Ta bort-ikon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'd MMM yyyy HH:mm',
                          'sv_SE',
                        ).format(m.date.toLocal()),
                        style: tt.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: cs.error,
                        tooltip: 'Ta bort logg',
                        onPressed: () => _confirmDelete(context, m),
                      ),
                    ],
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
                          '${weather.shortDescription} • ${weather.temperatureC.toStringAsFixed(0)}°C • Vind ${weather.windSpeed.toStringAsFixed(0)} m/s',
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
                      Expanded(
                        child: Text(
                          _locationName ?? 'Hämtar plats...',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}
