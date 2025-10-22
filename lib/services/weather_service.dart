import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '5063cfb1712b0220e983100ce52c247a';
  final String city = 'Gothenburg';

  Future<Map<String, dynamic>> fetchWeather() async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Kunde inte hämta väderdata');
    }
  }
}