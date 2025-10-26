import 'package:latlong2/latlong.dart';

/// Vilken typ av inlägg det är.
enum EntryKind { map, home }

class Weather {
  final double temperatureC;
  final double windSpeed;
  final int weatherCode;

  Weather({
    required this.temperatureC,
    required this.windSpeed,
    required this.weatherCode,
  });

  // Kort beskrivning baserad på Open-Meteo-koder
  String get shortDescription {
    final c = weatherCode;
    if (c == 0) return 'Klart';
    if ([1, 2].contains(c)) return 'Mest klart';
    if (c == 3) return 'Mulet';
    if ([45, 48].contains(c)) return 'Dimma';
    if ([51, 53, 55].contains(c)) return 'Duggregn';
    if ([61, 63, 65].contains(c)) return 'Regn';
    if ([71, 73, 75].contains(c)) return 'Snöfall';
    if ([80, 81, 82].contains(c)) return 'Skurar';
    if ([95, 96, 99].contains(c)) return 'Åska';
    return 'Växlande';
    }

  Map<String, dynamic> toJson() => {
        'temperatureC': temperatureC,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
      };

  static Weather fromJson(Map<String, dynamic> json) => Weather(
        temperatureC: (json['temperatureC'] as num).toDouble(),
        windSpeed: (json['windSpeed'] as num).toDouble(),
        weatherCode: (json['weatherCode'] as num).toInt(),
      );
}

class MoodEntry {
  final EntryKind kind;           // 👈 NYTT: typ av inlägg
  final String emoji;
  final String note;
  final DateTime date;
  final LatLng position;
  final Weather weather;

  MoodEntry({
    required this.kind,           // 👈 obligatoriskt
    required this.emoji,
    required this.note,
    required this.date,
    required this.position,
    required this.weather,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name, // spara som sträng: 'map' / 'home'
        'emoji': emoji,
        'note': note,
        'date': date.toIso8601String(),
        'position': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'weather': weather.toJson(),
      };

  static MoodEntry fromJson(Map<String, dynamic> json) {
    // Bakåtkomp: saknas 'kind' → anta 'map' (gamla poster från kartan)
    final kindStr = (json['kind'] as String?) ?? 'map';
    final EntryKind kind =
        kindStr == 'home' ? EntryKind.home : EntryKind.map;

    final pos = (json['position'] as Map).cast<String, dynamic>();
    return MoodEntry(
      kind: kind,
      emoji: json['emoji'] as String,
      note: (json['note'] ?? '') as String,
      date: DateTime.parse(json['date'] as String),
      position: LatLng(
        (pos['lat'] as num).toDouble(),
        (pos['lng'] as num).toDouble(),
      ),
      weather: Weather.fromJson(
        (json['weather'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}
