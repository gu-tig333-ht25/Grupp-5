import 'package:flutter/material.dart';

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


  void onSave() {
    final payload = {
      "mood": moodScore,
      "note": noteCtrl.text.trim(),
      "location": locationText,
      "weather": weatherText,
      "createdAt": DateTime.now().toIso8601String(),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Humör sparat: $payload")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 4),
            Text("Hur mår du idag",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                      child:
                          Text(moodEmoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(moodLabel,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text("$moodScore/10",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                        Text("hemskt",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                        Text("underbart",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text("Spara humör"),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (i) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: "Hem"),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline), label: "Logga"),
          NavigationDestination(
              icon: Icon(Icons.map_outlined), label: "Karta"),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined), label: "Statistik"),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }
}
