/// Modell för väderdata kopplat till humörinlägg
class Weather {
  final double temperatureC;
  final double windSpeed;
  final int weatherCode;
  final String? shortDescription; // 👈 Nytt fält

  Weather({
    required this.temperatureC,
    required this.windSpeed,
    required this.weatherCode,
    this.shortDescription, // 👈 tillåter anpassad text
  });

  /// En kort beskrivning baserad på Open‑Meteo‑koder eller manuellt fält
  String get description {
    if (shortDescription != null && shortDescription!.isNotEmpty) {
      return shortDescription!;
    }
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

  /// Konverterar till JSON (för lagring)
  Map<String, dynamic> toJson() => {
        'temperatureC': temperatureC,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
        'shortDescription': shortDescription,
      };

  /// Skapar objekt från JSON (vid laddning)
  static Weather fromJson(Map<String, dynamic> json) => Weather(
        temperatureC: (json['temperatureC'] as num).toDouble(),
        windSpeed: (json['windSpeed'] as num).toDouble(),
        weatherCode: (json['weatherCode'] as num).toInt(),
        shortDescription: json['shortDescription'],
      );

  /// Hjälpfunktion för att skapa "okänt" väder om API saknas
  static Weather unknown() => Weather(
        temperatureC: 0,
        windSpeed: 0,
        weatherCode: 3,
      );
}
