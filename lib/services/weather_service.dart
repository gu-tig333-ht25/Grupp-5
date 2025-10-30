// lib/services/weather_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/weather.dart';

class WeatherService {
  static const _apiKey = '5063cfb1712b0220e983100ce52c247a'; // ← din OpenWeather API-nyckel

  /// Hämtar väder från OpenWeather och returnerar en `Weather`-modell
  static Future<Weather> fetchCurrent(LatLng pos) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=${pos.latitude}&lon=${pos.longitude}'
      '&units=metric&lang=sv&appid=$_apiKey',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Kunde inte hämta väder (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    final temp = (data['main']['temp'] as num).toDouble();
    final wind = (data['wind']['speed'] as num).toDouble();
    final openWeatherCode = (data['weather'][0]['id'] as int);

    return Weather(
      temperatureC: temp,
      windSpeed: wind,
      weatherCode: _mapToOpenMeteoCode(openWeatherCode),
    );
  }

  /// Mappa OpenWeather väderkoder till Open-Meteo-liknande koder
  static int _mapToOpenMeteoCode(int code) {
    if (code >= 200 && code < 300) return 95; // Thunderstorm
    if (code >= 300 && code < 400) return 51; // Drizzle
    if (code >= 500 && code < 600) return 61; // Rain
    if (code >= 600 && code < 700) return 71; // Snow
    if (code == 800) return 0; // Clear
    if (code == 801 || code == 802) return 1; // Partly Cloudy
    if (code == 803 || code == 804) return 3; // Cloudy
    if (code >= 700 && code < 800) return 45; // Fog/Mist etc
    return 3; // fallback = cloudy
  }

  /// 🔹 NYTT: Hämtar väderkoder för flera dagar (används i statistik-sidan)
  static Future<Map<String, int>> fetchDailyWeatherCodes({
    required LatLng at,
    required DateTime start,
    required DateTime end,
  }) async {
    // Open-Meteo används här eftersom OpenWeather inte har gratis daily weather_code
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

    final n = min(times.length, codes.length);
    return {
      for (var i = 0; i < n; i++) times[i]: codes[i].toInt(),
    };
  }
}
