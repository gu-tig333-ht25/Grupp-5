import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _center = const LatLng(57.7089, 11.9746); // Göteborg
  final List<MoodMarker> _markers = [];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'sv_SE';
  }

  void _onMapTap(TapPosition _, LatLng latLng) async {
    final res = await showModalBottomSheet<_NewMoodResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B2236),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _NewMoodSheet(),
    );
    if (res == null || !mounted) return;

    setState(() {
      _markers.add(MoodMarker(
        position: latLng,
        emoji: res.emoji,
        note: res.note.trim().isEmpty ? '(Ingen anteckning)' : res.note.trim(),
        date: DateTime.now(),
      ));
    });
  }

  void _showDetails(MoodMarker m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2236),
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
              DateFormat('d MMMM yyyy').format(m.date),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                m.note,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1325),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            children: [
              const SizedBox(height: 6),
              const Text(
                "Humörkarta",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                "Tryck på kartan för att lägga en emoji-markör",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 13.5,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.moodmap',
                      ),
                      MarkerLayer(
                        markers: _markers.map((m) {
                          return Marker(
                            width: 48,
                            height: 48,
                            point: m.position,
                            child: GestureDetector(
                              onTap: () => _showDetails(m),
                              child: Center(
                                child: Text(m.emoji, style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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

// ========== Sheet för nytt humör ==========

class _NewMoodSheet extends StatefulWidget {
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
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text("Nytt humörinlägg", style: TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: emojis.map((e) {
              final selected = e == _emoji;
              return InkWell(
                onTap: () => setState(() => _emoji = e),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: selected ? Colors.white10 : Colors.transparent,
                    border: Border.all(color: selected ? Colors.white : Colors.white24),
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Hur mår du här?",
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop<_NewMoodResult?>(context, null),
                child: const Text("Avbryt", style: TextStyle(color: Colors.grey)),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
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

// ========== Modellklasser ==========

class _NewMoodResult {
  final String emoji;
  final String note;
  _NewMoodResult({required this.emoji, required this.note});
}

class MoodMarker {
  final LatLng position;
  final String emoji;
  final String note;
  final DateTime date;

  MoodMarker({
    required this.position,
    required this.emoji,
    required this.note,
    required this.date,
  });
}