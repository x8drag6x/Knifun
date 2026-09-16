import 'package:latlong2/latlong.dart';

/// Represents one Tehran Metro station.
class MetroStation {
  final String id;
  final String nameFa;
  final String nameEn;
  final List<int> lines;
  final double latitude;
  final double longitude;
  final String? address;

  const MetroStation({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.lines,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  LatLng get position => LatLng(latitude, longitude);

  factory MetroStation.fromJson(String key, Map<String, dynamic> json) {
    final translations = (json['translations'] as Map?)?.cast<String, dynamic>();
    final lines = (json['lines'] as List?)
            ?.whereType<num>()
            .map((value) => value.toInt())
            .toList(growable: false) ??
        const <int>[];

    return MetroStation(
      id: key,
      nameFa: (translations?['fa'] ?? json['name'] ?? key).toString(),
      nameEn: (json['name'] ?? key).toString(),
      lines: lines,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address']?.toString(),
    );
  }
}
