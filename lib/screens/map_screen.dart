import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/mood_entry.dart';
import '../services/mood_store.dart';
import '../services/weather_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _center = const LatLng(57.7089, 11.9746); // Göteborg
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'sv_SE';
  }

  Future<void> _onMapTap(TapPosition _, LatLng latLng) async {
    if (_saving) return;

    final res = await showModalBottomSheet<_NewMoodResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NewMoodSheet(),
    );
    if (!mounted || res == null) return;

    setState(() => _saving = true);
    try {
      final weather = await WeatherService.fetchCurrent(latLng);

      final entry = MoodEntry(
        kind: EntryKind.map,
        emoji: res.emoji,
        note: res.note.trim().isEmpty ? '(Ingen anteckning)' : res.note.trim(),
        date: DateTime.now(),
        position: latLng,
        weather: weather,
      );
      await context.read<MoodStore>().add(entry);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Humör sparat!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte hämta väder: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDetails(MoodEntry m) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              DateFormat('d MMMM yyyy HH:mm').format(m.date),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                m.note,
                style: tt.bodyLarge?.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${m.weather.shortDescription} • '
                    '${m.weather.temperatureC.toStringAsFixed(0)}°C • '
                    'Vind ${m.weather.windSpeed.toStringAsFixed(0)} m/s',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final all = context.watch<MoodStore>().entries;
    final mapEntries = all.where((e) => e.kind == EntryKind.map).toList();

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: const Text('Humörkarta'),
        backgroundColor: cs.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/logg'),
            icon: const Icon(Icons.list_alt),
            tooltip: 'Öppna logg',
          )
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Text(
                "Tryck på kartan för att lägga en emoji-markör (sparas med väder)",
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
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
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _center,
                            initialZoom: 13.5,
                            onTap: _onMapTap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.moodmap',
                            ),
                            MarkerLayer(
                              markers: mapEntries.map((m) {
                                return Marker(
                                  width: 48,
                                  height: 48,
                                  point: m.position,
                                  child: GestureDetector(
                                    onTap: () => _showDetails(m),
                                    child: Center(
                                      child: Text(m.emoji,
                                          style:
                                              const TextStyle(fontSize: 28)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        if (_saving)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black45,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 12),
                                  Text('Sparar…',
                                      style: tt.bodyMedium
                                          ?.copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewMoodSheet extends StatefulWidget {
  const _NewMoodSheet();

  @override
  State<_NewMoodSheet> createState() => _NewMoodSheetState();
}

class _NewMoodSheetState extends State<_NewMoodSheet> {
  String _emoji = "🙂";
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final emojis = ["😄", "🙂", "😐", "😔", "😡"];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text("Nytt humörinlägg",
              style: tt.titleMedium?.copyWith(color: cs.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: emojis.map((e) {
              final selected = e == _emoji;
              return InkWell(
                onTap: () => setState(() => _emoji = e),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: selected ? cs.surfaceVariant : Colors.transparent,
                    border: Border.all(
                      color: selected ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Hur mår du här?",
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: cs.primary),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop<_NewMoodResult?>(context, null),
                child: const Text("Avbryt"),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.pop<_NewMoodResult>(
                    context,
                    _NewMoodResult(emoji: _emoji, note: _noteCtrl.text),
                  );
                },
                child: const Text("Spara"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewMoodResult {
  final String emoji;
  final String note;
  _NewMoodResult({required this.emoji, required this.note});
}