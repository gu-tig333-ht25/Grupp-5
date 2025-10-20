import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodLogPage extends StatefulWidget {
  const MoodLogPage({super.key});

  @override
  State<MoodLogPage> createState() => _MoodLogPageState();
}

class _MoodLogPageState extends State<MoodLogPage> {
  int moodScore = 6;
  double sliderValue = 6;
  final noteCtrl = TextEditingController();
  String locationText = "Stockholm, Sverige";
  String weatherText = "Delvis molnigt, 12°";
  static const _storeKey = 'mood_logs';

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  String get moodLabel {
    if (moodScore <= 2) return "Dåligt";
    if (moodScore <= 4) return "Okej";
    if (moodScore <= 7) return "Bra";
    return "Underbart";
  }

  String get moodEmoji {
    const emojis = ["😭","😫","😢","☹️","🙁","😐","🙂","😊","😄","😃","😁"];
    return emojis[moodScore.clamp(0, 10).toInt()];
  }

  Future<void> _appendLog(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    final List<dynamic> list = raw != null ? jsonDecode(raw) as List : [];
    list.add(payload);
    await prefs.setString(_storeKey, jsonEncode(list));
  }

  void onSave() async {
    final payload = {
      "mood": moodScore,
      "note": noteCtrl.text.trim(),
      "location": locationText,
      "weather": weatherText,
      "createdAt": DateTime.now().toIso8601String(),
    };
    await _appendLog(payload);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Humör & anteckning sparad ✅")));
    }
  }

  void onShowSaved() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotesPage()));
  }

  // 🔹 Navigering i menyn
  void _onNav(int i) {
    if (i == 1) return; // Du är redan på "Logga"
    switch (i) {
      case 0: Navigator.pushReplacementNamed(context, '/home'); break;
      case 2: Navigator.pushReplacementNamed(context, '/map'); break;
      case 3: Navigator.pushReplacementNamed(context, '/stats'); break;
      case 4: Navigator.pushReplacementNamed(context, '/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // ✅ Här är menyn längst ner
      bottomNavigationBar: AppBottomNav(currentIndex: 1, onTap: _onNav),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text("Hur mår du idag",
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Emoji-kort
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Text(moodEmoji, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(moodLabel, style: theme.textTheme.titleMedium),
                        Text("$moodScore/10",
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Slider
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Humörnivå", style: theme.textTheme.titleMedium),
                    Slider(
                      min: 0,
                      max: 10,
                      divisions: 10,
                      value: sliderValue,
                      onChanged: (v) => setState(() {
                        sliderValue = v;
                        moodScore = v.round();
                      }),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [Text("hemskt"), Text("underbart")]),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Anteckning
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Vad tänker du på?", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Skriv en anteckning om ditt humör…",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Plats och väder
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.place_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text(locationText)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.cloud_queue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(weatherText)),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24))),
                child: const Text("Spara humör"),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onShowSaved,
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text("Visa sparade loggar"),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24))),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔸 Visa sparade loggar
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const _storeKey = 'mood_logs';
  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    final List<dynamic> list = raw != null ? jsonDecode(raw) as List : [];
    setState(() => logs = list.cast<Map<String, dynamic>>());
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeKey);
    setState(() => logs = []);
  }

  void _onNav(int i) {
    if (i == 1) Navigator.pushReplacementNamed(context, '/log');
    else if (i == 0) Navigator.pushReplacementNamed(context, '/home');
    else if (i == 2) Navigator.pushReplacementNamed(context, '/map');
    else if (i == 3) Navigator.pushReplacementNamed(context, '/stats');
    else if (i == 4) Navigator.pushReplacementNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sparade loggar"),
        actions: [
          if (logs.isNotEmpty)
            IconButton(onPressed: _clearAll, icon: const Icon(Icons.delete_outline))
        ],
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 1, onTap: _onNav),
      body: logs.isEmpty
          ? const Center(child: Text("Inga sparade loggar ännu."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final item = logs[i];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(item["note"] ?? "(Ingen anteckning)"),
                    subtitle: Text(
                      "Humör: ${item["mood"]}/10\n📍 ${item["location"]}\n☁️ ${item["weather"]}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// 🔹 Själva menyn (Hem, Logga, Karta, Statistik, Profil)
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurfaceVariant,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Hem'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Logga'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Karta'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Statistik'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }
}
