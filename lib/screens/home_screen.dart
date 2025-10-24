import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/local_profiles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final _profiles = LocalProfiles();

  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final data = await _weatherService.fetchWeather();
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fel vid hämtning av väderdata: $e');
      setState(() => _isLoading = false);
    }
  }

  // Hämta aktuellt användarnamn från LocalProfiles
  Future<String> _getCurrentUserName() async {
    final id = await _profiles.getCurrentUserId() ?? 'alex';
    final all = await _profiles.getAllProfiles();
    return (all[id]?['name'] as String?) ?? 'Användare';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hälsning + väder
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _getCurrentUserName(),
                      builder: (context, snap) {
                        final name = snap.data ?? '…';
                        return GreetingCard(userName: name);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : WeatherCard(
                            temperature: _weatherData?['main']?['temp'],
                            description:
                                _weatherData?['weather']?[0]?['description'],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const MoodCard(),
            const SizedBox(height: 20),
            const ActionButtonsRow(),
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
  const GreetingCard({super.key, required this.userName});

  @override
  State<GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard> {
  final TextEditingController _moodController = TextEditingController();

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  void _saveMood() {
    final mood = _moodController.text.trim();
    if (mood.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Humör sparat"),
          content: Text('😊 "$mood"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      _moodController.clear();
    }
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
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              )),
          Text(widget.userName,
              style: tt.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
              )),
          const SizedBox(height: 10),
          TextField(
            controller: _moodController,
            decoration: InputDecoration(
              hintText: "Hur mår du idag?",
              filled: true,
              fillColor: cs.surfaceVariant,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              child: const Text("Spara"),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  final double? temperature;
  final String? description;

  const WeatherCard({
    super.key,
    required this.temperature,
    required this.description,
  });

  IconData getWeatherIcon(String? desc) {
    if (desc == null) return Icons.help_outline;
    final lower = desc.toLowerCase();
    if (lower.contains('clear')) return Icons.wb_sunny;
    if (lower.contains('cloud')) return Icons.cloud;
    if (lower.contains('rain')) return Icons.umbrella;
    if (lower.contains('fog') || lower.contains('mist')) return Icons.blur_on;
    if (lower.contains('snow')) return Icons.ac_unit;
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
            child: Icon(getWeatherIcon(description),
                color: cs.onPrimaryContainer, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            temperature != null ? "${temperature!.toStringAsFixed(1)}°C" : "Laddar...",
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
          Text(
            description ?? "",
            style: tt.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer.withOpacity(.9),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodCard extends StatelessWidget {
  const MoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: _cardDecoration(context, color: cs.secondaryContainer),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.onSecondaryContainer.withOpacity(.2),
          child: Text("😊", style: tt.titleLarge),
        ),
        title: Text("Glad · för 2 timmar sedan",
            style: tt.titleMedium?.copyWith(color: cs.onSecondaryContainer)),
        subtitle: Text(
          "Hade ett trevligt fika med en vän",
          style: tt.bodyMedium?.copyWith(
            color: cs.onSecondaryContainer.withOpacity(.85),
          ),
        ),
      ),
    );
  }
}

class ActionButtonsRow extends StatelessWidget {
  const ActionButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              // TODO: Navigera till logga humör
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text("Logga humör"),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: FilledButton.tonal(
            onPressed: () {
              // TODO: Navigera till karta
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text("Visa karta"),
            ),
          ),
        ),
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
            Text(title,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                )),
          ],
        );

    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          col("Inloggningar", "7"),
          col("Snitthumör", "7.2"),
          col("Vanligast", "😊"),
        ],
      ),
    );
  }
}

/// Temaanpassad kort-dekoration
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