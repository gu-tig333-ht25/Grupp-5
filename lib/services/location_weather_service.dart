import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

/// Hämtar användarens aktuella plats (lat/lng)
Future<Position> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception("Platstjänster är inte aktiverade");
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("Platsåtkomst nekad");
    }
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

/// Översätter lat/lng → stad + land (t.ex. Göteborg, Sverige)
Future<String> getAddressFromCoordinates(Position pos) async {
  final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
  final place = placemarks.first;
  return "${place.locality}, ${place.country}";
}

/// Hämtar aktuellt väder från OpenWeather API
Future<String> getWeather(double lat, double lon) async {
  const apiKey = '5063cfb1712b0220e983100ce52c247a'; // ← Din nyckel här
  final url = Uri.parse(
    "https://api.openweathermap.org/data/2.5/weather"
    "?lat=$lat&lon=$lon&units=metric&lang=sv&appid=$apiKey",
  );

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final temp = data['main']['temp'];
    final desc = data['weather'][0]['description'];
    return "$desc, ${temp.toStringAsFixed(1)}°C";
  } else {
    throw Exception("Kunde inte hämta väderdata");
  }
}
