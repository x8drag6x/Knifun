import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/metro_station.dart';
import '../utils/metro_order.dart';

/// Loads the open Tehran Metro station dataset.
///
/// Coordinates and station metadata stay in the source dataset, while the
/// UI order is controlled locally so the app always shows line 1 → line 7.
class MetroService {
  static const String sourceUrl =
      'https://raw.githubusercontent.com/mostafa-kheibary/tehran-metro-data/main/data/stations.json';

  List<MetroStation>? _memoryCache;

  Future<List<MetroStation>> loadStations({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCache != null) return _memoryCache!;

    final response = await http.get(
      Uri.parse(sourceUrl),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('بارگذاری اطلاعات ایستگاه‌های مترو ناموفق بود (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw Exception('فرمت دادهٔ ایستگاه‌های مترو نامعتبر است.');
    }

    final stations = <MetroStation>[];
    decoded.forEach((key, value) {
      if (key is String && value is Map) {
        try {
          final station = MetroStation.fromJson(key, value.cast<String, dynamic>());
          if (station.nameFa.trim().isNotEmpty &&
              station.latitude.abs() <= 90 &&
              station.longitude.abs() <= 180 &&
              station.lines.isNotEmpty) {
            stations.add(station);
          }
        } catch (_) {
          // Ignore malformed rows so one bad record doesn't break the whole app.
        }
      }
    });

    if (stations.isEmpty) {
      throw Exception('هیچ ایستگاه مترویی از منبع دریافت نشد.');
    }

    _memoryCache = List<MetroStation>.unmodifiable(stations);
    return _memoryCache!;
  }

  List<MetroStation> stationsForLine(List<MetroStation> stations, int line) {
    final result = stations.where((station) => station.lines.contains(line)).toList();
    result.sort((a, b) {
      final ai = stationOrderIndex(line, a.nameEn);
      final bi = stationOrderIndex(line, b.nameEn);
      final orderCompare = ai.compareTo(bi);
      if (orderCompare != 0) return orderCompare;
      return a.nameFa.compareTo(b.nameFa);
    });
    return result;
  }
}
