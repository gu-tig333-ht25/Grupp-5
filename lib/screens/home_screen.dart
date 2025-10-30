import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/weather_service.dart';
import '../services/local_profiles.dart';
import '../services/mood_store.dart';
import '../models/mood_entry.dart';
import 'map_screen.dart';
import 'mood_log_page.dart';
import 'quiz_screen.dart';
import '../models/weather.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profiles = LocalProfiles();
  final _homeLocation = const LatLng(57.7089, 11.9746);
  Weather? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final w = await WeatherService.fetchCurrent(_homeLocation);
      if (!mounted) return;
      setState(() {
        _weather = w;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getCurrentUserName() async {
    final id = await _profiles.getCurrentUserId() ?? 'alex';
    final all = await _profiles.getAllProfiles();
    return (all[id]?['name'] as String?) ?? 'Användare';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = context.watch<MoodStore>();
    final last = store.entries.isEmpty ? null : store.entries.last;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _getCurrentUserName(),
                      builder: (context, snap) {
                        final name = snap.data ?? '…';
                        return GreetingCard(
                          userName: name,
                          onQuickSave: (note) async {
                            final weather = _weather ??
                                Weather(temperatureC: 0, windSpeed: 0, weatherCode: 3);
                            final entry = MoodEntry(
                              kind: EntryKind.home,
                              emoji: "🙂",
                              note: note.trim().isEmpty ? '(Ingen anteckning)' : note.trim(),
                              date: DateTime.now(),
                              position: _homeLocation,
                              weather: weather,
                            );
                            await context.read<MoodStore>().add(entry);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Humör sparat ✅')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : WeatherCard(weather: _weather),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            MoodCard(latest: last),
            const SizedBox(height: 20),
            ActionButtonsRow(
              onOpenLog: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodLogScreen())),
              onOpenMap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
              onOpenQuiz: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
            ),
            const SizedBox(height: 20),
            const StatsCard(),
          ],
        ),
      ),
    );
  }
}

class GreetingCard extends StatefulWidget {
  final String userName;
  final Future<void> Function(String) onQuickSave;

  const GreetingCard({super.key, required this.userName, required this.onQuickSave});

  @override
  State<GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard> {
  final TextEditingController _moodController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    if (_saving) return;
    final mood = _moodController.text.trim();
    if (mood.isEmpty) return;

    setState(() => _saving = true);
    await widget.onQuickSave(mood);
    if (!mounted) return;
    setState(() => _saving = false);
    _moodController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("☀️ God morgon,",
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
          Text(widget.userName, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          TextField(
            controller: _moodController,
            decoration: InputDecoration(
              hintText: "Hur mår du idag?",
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saveMood,
              child: Text(_saving ? "Sparar…" : "Spara"),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  final Weather? weather;
  const WeatherCard({super.key, required this.weather});

  IconData _iconFromWeather(Weather? w) {
    if (w == null) return Icons.help_outline;
    final c = w.weatherCode;
    if (c == 0) return Icons.wb_sunny;
    if ([1, 2, 3].contains(c)) return Icons.cloud;
    if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(c)) return Icons.umbrella;
    if ([71, 73, 75].contains(c)) return Icons.ac_unit;
    if ([45, 48].contains(c)) return Icons.blur_on;
    if ([95, 96, 99].contains(c)) return Icons.flash_on;
    return Icons.wb_cloudy;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: _cardDecoration(context, color: cs.primaryContainer),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: cs.onPrimaryContainer.withOpacity(0.15),
            child: Icon(_iconFromWeather(weather), color: cs.onPrimaryContainer, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            weather != null ? "${weather!.temperatureC.toStringAsFixed(1)}°C" : "Laddar...",
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 4),
          Text(
            "Göteborg", // <-- LÄGG TILL DENNA RAD
            style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer.withOpacity(.9)),
          ),
          Text(
            weather?.shortDescription ?? "",
            style: tt.bodyMedium?.copyWith(color: cs.onPrimaryContainer.withOpacity(.9)),
          ),
        ],
      ),
    );
  }
}

class MoodCard extends StatelessWidget {
  final MoodEntry? latest;
  const MoodCard({super.key, required this.latest});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final title = latest == null ? "Inget loggat ännu" : "${latest!.emoji} · senast ${_formatAgo(latest!.date)}";
    final subtitle = latest?.note ?? "Tryck “Logga humör” för att börja.";

    return Container(
      decoration: _cardDecoration(context, color: cs.secondaryContainer),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.onSecondaryContainer.withOpacity(.2),
          child: Text(latest?.emoji ?? "😊", style: tt.titleLarge),
        ),
        title: Text(title, style: tt.titleMedium?.copyWith(color: cs.onSecondaryContainer)),
        subtitle: Text(
          subtitle,
          style: tt.bodyMedium?.copyWith(color: cs.onSecondaryContainer.withOpacity(.85)),
        ),
      ),
    );
  }

  String _formatAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'nyss';
    if (diff.inHours < 1) return '${diff.inMinutes} min sedan';
    if (diff.inHours < 24) return '${diff.inHours} h sedan';
    return '${diff.inDays} d sedan';
  }
}

class ActionButtonsRow extends StatelessWidget {
  final VoidCallback onOpenLog;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenQuiz;

  const ActionButtonsRow({super.key, required this.onOpenLog, required this.onOpenMap, required this.onOpenQuiz});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget buildButton(String text, VoidCallback onPressed) {
      return Expanded(
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed,
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
    }

    return Row(
      children: [
        buildButton("Logga humör", onOpenLog),
        const SizedBox(width: 12),
        buildButton("Visa karta", onOpenMap),
        const SizedBox(width: 12),
        buildButton("Gör quiz", onOpenQuiz),
      ],
    );
  }
}

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget col(String title, String value) => Column(
          children: [
            Text(value,
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                )),
            const SizedBox(height: 4),
            Text(title, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        );

    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          col("Inlägg", context.watch<MoodStore>().entries.length.toString()),
          col("Snitthumör", "–"),
          col("Vanligast", "🙂"),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context, {Color? color}) {
  final cs = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: color ?? cs.surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 10,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
