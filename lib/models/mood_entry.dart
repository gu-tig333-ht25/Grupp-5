import 'package:latlong2/latlong.dart';
import 'weather.dart';

enum EntryKind { map, home }

class MoodEntry {
  final EntryKind kind;
  final String emoji;
  final String note;
  final DateTime date;
  final LatLng position;
  final Weather? weather;

  MoodEntry({
    required this.kind,
    required this.emoji,
    required this.note,
    required this.date,
    required this.position,
    this.weather,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name, // 'map' eller 'home'
        'emoji': emoji,
        'note': note,
        'date': date.toIso8601String(),
        'position': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'weather': weather?.toJson(), // null om inget väder
      };

  static MoodEntry fromJson(Map<String, dynamic> json) {
    // Hantera 'kind' med fallback (gamla poster)
    final kindStr = (json['kind'] as String?) ?? 'map';
    final kind = kindStr == 'home' ? EntryKind.home : EntryKind.map;

    // Hantera position med fallback (måste finnas)
    final pos = (json['position'] as Map).cast<String, dynamic>();
    final lat = (pos['latitude'] ?? pos['lat'] ?? 0.0) as num;
    final lng = (pos['longitude'] ?? pos['lng'] ?? 0.0) as num;

    // Hantera weather som kan vara null
    final weatherJson = json['weather'];
    final weather = (weatherJson is Map)
        ? Weather.fromJson(weatherJson.cast<String, dynamic>())
        : null;

    return MoodEntry(
      kind: kind,
      emoji: json['emoji'] ?? '',
      note: json['note'] ?? '',
      date: DateTime.parse(json['date']),
      position: LatLng(lat.toDouble(), lng.toDouble()),
      weather: weather,
    );
  }

  @override
  String toString() {
    return 'MoodEntry(emoji: $emoji, note: $note, date: $date, '
        'position: (${position.latitude}, ${position.longitude}), '
        'weather: ${weather?.shortDescription}, kind: $kind)';
  }
}
