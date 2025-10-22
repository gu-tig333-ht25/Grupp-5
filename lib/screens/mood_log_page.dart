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
    const emojis = [
      "😭", // 0
      "😫", // 1
      "😢", // 2
      "☹️", // 3
      "🙁", // 4
      "😐", // 5
      "🙂", // 6
      "😊", // 7
      "😄", // 8
      "😃", // 9
      "😁", // 10
    ];
    final i = moodScore.clamp(0, 10).toInt();
    return emojis[i];
  }

  Future<void> _appendLog(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    final List<dynamic> list =
        raw != null ? jsonDecode(raw) as List : <dynamic>[];
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Humör & anteckning sparad ✅")),
      );
    }
    // Valfritt: töm textfältet efter spar
    // noteCtrl.clear();
  }

  void onShowSaved() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Ingen bottomNavigationBar här — borttagen.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 4),
            Text(
              "Hur mår du idag",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Kort: emoji + etikett + poäng
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        moodEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(moodLabel, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            "$moodScore/10",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kort: slider
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Humörnivå", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Slider(
                      min: 0,
                      max: 10,
                      divisions: 10,
                      value: sliderValue,
                      label: moodScore.toString(),
                      onChanged: (v) {
                        setState(() {
                          sliderValue = v;
                          moodScore = v.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "hemskt",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          "underbart",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kort: anteckning
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Vad tänker du på?",
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Skriv en anteckning om ditt humör…",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kort: plats + väder (exempel)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(locationText)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.cloud_queue,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(weatherText)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Spara-knapp
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text("Spara humör"),
              ),
            ),

            const SizedBox(height: 12),

            // Visa sparade loggar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onShowSaved,
                icon: const Icon(Icons.list_alt_outlined),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                label: const Text("Visa sparade loggar"),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

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
    final List<dynamic> list =
        raw != null ? jsonDecode(raw) as List : <dynamic>[];
    setState(() {
      logs = list.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeKey);
    if (mounted) {
      setState(() => logs = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Behåll gärna en AppBar här för navigation.
      appBar: AppBar(
        title: const Text("Sparade loggar"),
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              tooltip: "Rensa allt",
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text("Inga sparade loggar ännu."))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = logs[index];
                final mood = (item["mood"] ?? 0).toString();
                final note = (item["note"] ?? "") as String;
                final loc = (item["location"] ?? "") as String;
                final weather = (item["weather"] ?? "") as String;
                final createdAt = DateTime.tryParse(item["createdAt"] ?? "");

                final subtitle = [
                  if (loc.isNotEmpty) "📍 $loc",
                  if (weather.isNotEmpty) "☁️ $weather",
                ].join("  •  ");

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      note.isEmpty ? "(Ingen anteckning)" : note,
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text("Humör: $mood/10"),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subtitle),
                        ],
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Skapad: ${_fmt(createdAt)}",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _fmt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }
}