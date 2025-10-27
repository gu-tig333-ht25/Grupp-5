// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/mood_entry.dart';

class WeatherService {
  /// Hämtar *aktuellt* väder (du har redan denna – kvar här för helhet).
  static Future<Weather> fetchCurrent(LatLng at) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${at.latitude}&longitude=${at.longitude}'
      '&current_weather=true',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Kunde inte hämta väder (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final cw = data['current_weather'] as Map<String, dynamic>;
    return Weather(
      temperatureC: (cw['temperature'] as num).toDouble(),
      windSpeed: (cw['windspeed'] as num).toDouble(),
      weatherCode: (cw['weathercode'] as num).toInt(),
    );
  }

  /// Hämtar **dagliga** väderkoder (Open-Meteo `daily.weather_code`) för ett datumintervall.
  /// Returnerar en map med nyckel 'YYYY-MM-DD' -> weather_code (int).
  static Future<Map<String, int>> fetchDailyWeatherCodes({
    required LatLng at,
    required DateTime start,
    required DateTime end,
  }) async {
    // Open-Meteo kräver datum i YYYY-MM-DD
    String _fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${at.latitude}&longitude=${at.longitude}'
      '&daily=weather_code'
      '&timezone=auto'
      '&start_date=${_fmt(start)}'
      '&end_date=${_fmt(end)}',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Kunde inte hämta dagliga väderkoder (${res.statusCode})');
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>?;
    if (daily == null) {
      throw Exception('Svar saknar "daily"');
    }

    final times = (daily['time'] as List?)?.cast<String>() ?? const <String>[];
    final codes = (daily['weather_code'] as List?)?.cast<num>() ?? const <num>[];

    if (times.length != codes.length) {
      // Robusthet om API skulle returnera olika längd
      final n = times.length < codes.length ? times.length : codes.length;
      return {
        for (var i = 0; i < n; i++) times[i]: codes[i].toInt(),
      };
    }

    return {
      for (var i = 0; i < times.length; i++) times[i]: codes[i].toInt(),
    };
  }
}
