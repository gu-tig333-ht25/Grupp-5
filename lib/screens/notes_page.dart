import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
