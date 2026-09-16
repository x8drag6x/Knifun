import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/nearby_place.dart';
import '../models/place_category.dart';

class OverpassService {
  // Public endpoints. If one is temporarily unavailable, the service tries the next one.
  static const endpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  Future<List<NearbyPlace>> findNearby({
    required LatLng center,
    required PlaceCategory category,
    int radiusMeters = 1200,
  }) async {
    final selectors = category.selectors.map((selector) {
      return '$selector(around:$radiusMeters,${center.latitude},${center.longitude});';
    }).join('\n');

    final query = '''
[out:json][timeout:25];
(
$selectors
);
out center tags;
''';

    Object? lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent': 'MetroAroundTehran/1.0 (Flutter OpenStreetMap app)',
          },
          body: {'data': query},
        );

        if (response.statusCode != 200) {
          lastError = Exception('Overpass HTTP ${response.statusCode}');
          continue;
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final elements = decoded['elements'];
        if (elements is! List) {
          throw Exception('پاسخ Overpass نامعتبر است.');
        }

        final places = <NearbyPlace>[];
        final seen = <String>{};
        for (final element in elements) {
          if (element is! Map) continue;
          final map = element.cast<String, dynamic>();
          final id = '${map['type']}:${map['id']}';
          if (!seen.add(id)) continue;

          try {
            final place = NearbyPlace.fromOverpass(map, center);
            places.add(place);
          } catch (_) {
            // Skip incomplete OSM objects.
          }
        }

        places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        return places;
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('جست‌وجوی مکان‌ها انجام نشد. ${lastError ?? ''}');
  }
}
