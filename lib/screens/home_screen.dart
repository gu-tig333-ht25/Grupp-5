import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userName = "Alex";
  final WeatherService _weatherService = WeatherService();

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
      print('Fel vid hämtning av väderdata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Hem'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Logga'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karta'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistik'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 🧑‍💬 God morgon + väder i rad
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GreetingCard(userName: userName),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : WeatherCard(
                            temperature: _weatherData?['main']['temp'],
                            description: _weatherData?['weather'][0]['description'],
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
  _GreetingCardState createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard> {
  final TextEditingController _moodController = TextEditingController();

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  void _saveMood() {
    String moodText = _moodController.text;
    if (moodText.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Humör sparat"),
          content: Text('😊 "$moodText"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("☀️ God morgon,", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(widget.userName, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: _moodController,
            decoration: InputDecoration(
              hintText: "Hur mår du idag?",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(getWeatherIcon(description), color: Colors.blue[800], size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            temperature != null ? "${temperature!.toStringAsFixed(1)}°C" : "Laddar...",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(description ?? "", style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class MoodCard extends StatelessWidget {
  const MoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.yellow,
          child: Text("😊", style: TextStyle(fontSize: 24)),
        ),
        title: Text("Glad · för 2 timmar sedan"),
        subtitle: Text("Hade ett trevligt fika med en vän"),
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            onPressed: () {},
            child: const Text("Logga humör"),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            onPressed: () {},
            child: const Text("Visa karta"),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Column(children: [
            Text("7", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Inloggningar")
          ]),
          Column(children: [
            Text("7.2", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Snitthumör")
          ]),
          Column(children: [
            Text("😊", style: TextStyle(fontSize: 22)),
            Text("Vanligast")
          ]),
        ],
      ),
    );
  }
}
