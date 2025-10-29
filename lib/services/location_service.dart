import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<String> reverseGeocode(LatLng coords) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2'
      '&lat=${coords.latitude}&lon=${coords.longitude}&zoom=10&addressdetails=1',
    );

    final response = await http.get(url, headers: {
      // Viktigt: Nominatim kräver en giltig User-Agent (din app eller kontaktinfo)
      'User-Agent': 'MoodApp/1.0 (bella@example.com)',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['address'];

      // Försök hämta stad/kommun först
      final primary = address['city'] ??
                      address['town'] ??
                      address['village'] ??
                      address['municipality'];

      // Lägg till län eller region som sekundär del
      final secondary = address['state'] ??
                        address['county'];

      if (primary != null && secondary != null) {
        return '$primary, $secondary';
      } else if (primary != null) {
        return primary;
      } else if (secondary != null) {
        return secondary;
      } else {
        return 'Okänd plats';
      }
    } else {
      throw Exception('Kunde inte hämta platsnamn (${response.statusCode})');
    }
  }
}
