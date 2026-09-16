import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/metro_station.dart';

/// Loads the open Tehran Metro station dataset.
///
/// The source project publishes stations in JSON and is licensed under ODbL-1.0.
/// We intentionally load the source instead of maintaining a second database in this app.
class MetroService {
  static const String sourceUrl =
      'https://raw.githubusercontent.com/mostafa-kheibary/tehran-metro-data/main/data/stations.json';

  Future<List<MetroStation>> loadStations() async {
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
          if (station.latitude.abs() <= 90 && station.longitude.abs() <= 180) {
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

    // The source can contain graph-related data; sorting makes the UI predictable.
    stations.sort((a, b) => a.nameFa.compareTo(b.nameFa));
    return stations;
  }
}
