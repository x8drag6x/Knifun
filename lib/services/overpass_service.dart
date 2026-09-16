import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/nearby_place.dart';
import '../models/place_category.dart';

class OverpassService {
  // Public mirrors. The app rotates through them when one mirror is busy.
  static const endpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  static const _requestTimeout = Duration(seconds: 14);
  static const _cacheLifetime = Duration(minutes: 5);

  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  Future<List<NearbyPlace>> findNearby({
    required LatLng center,
    required PlaceCategory category,
    int radiusMeters = 1000,
  }) async {
    final cacheKey =
        '${category.id}:${center.latitude.toStringAsFixed(5)}:${center.longitude.toStringAsFixed(5)}:$radiusMeters';

    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.createdAt) < _cacheLifetime) {
      return cached.places;
    }

    final selector = _buildSelector(category, radiusMeters, center);
    final query = '''
[out:json][timeout:12];
(
$selector
);
out center tags;
''';

    Object? lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json',
                'User-Agent': 'MetroAroundTehran/1.1 (Flutter OpenStreetMap app)',
              },
              body: {'data': query},
            )
            .timeout(_requestTimeout);

        if (response.statusCode != 200) {
          lastError = Exception('Overpass HTTP ${response.statusCode}');
          continue;
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final elements = decoded['elements'];
        if (elements is! List) {
          throw const FormatException('پاسخ Overpass نامعتبر است.');
        }

        final places = <NearbyPlace>[];
        final seen = <String>{};
        for (final element in elements) {
          if (element is! Map) continue;
          final map = element.cast<String, dynamic>();
          final id = '${map['type']}:${map['id']}';
          if (!seen.add(id)) continue;

          try {
            // The query already requires a name, but we keep the model-level
            // filter too, so incomplete OSM records never reach the UI.
            final place = NearbyPlace.fromOverpass(map, center);
            if (place.name.trim().isEmpty) continue;
            places.add(place);
          } catch (_) {
            // Skip incomplete objects instead of breaking the whole result set.
          }
        }

        places.sort((a, b) {
          final byDistance = a.distanceMeters.compareTo(b.distanceMeters);
          if (byDistance != 0) return byDistance;
          return a.name.compareTo(b.name);
        });

        final result = List<NearbyPlace>.unmodifiable(places);
        _cache[cacheKey] = _CacheEntry(DateTime.now(), result);
        return result;
      } on TimeoutException {
        lastError = TimeoutException('خطا');
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'چند لحظه بعد دوباره امتحان کن. ${lastError ?? ''}',
    );
  }

  String _buildSelector(PlaceCategory category, int radiusMeters, LatLng center) {
    final base = 'around:$radiusMeters,${center.latitude},${center.longitude}';
    return category.selectors.map((selector) {
      // One nwr selector is much lighter than issuing separate node/way/relation
      // queries for every category. Requiring ["name"] removes anonymous POIs.
      final normalized = selector
          .replaceFirst(RegExp(r'^(node|way|relation)'), 'nwr')
          .replaceAll(RegExp(r'\]\s*\['), '][');
      final named = normalized.endsWith(']') ? '$normalized["name"]' : '$normalized["name"]';
      return '$named($base);';
    }).join('\n');
  }

  void clearCache() => _cache.clear();
}

class _CacheEntry {
  final DateTime createdAt;
  final List<NearbyPlace> places;

  const _CacheEntry(this.createdAt, this.places);
}
