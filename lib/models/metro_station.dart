import 'package:latlong2/latlong.dart';

/// One Tehran Metro station.
///
/// `lines` can contain more than one line for interchange stations.
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
            .where((line) => line >= 1 && line <= 7)
            .toSet()
            .toList(growable: false) ??
        const <int>[];

    return MetroStation(
      id: key,
      nameFa: (translations?['fa'] ?? json['name'] ?? key).toString().trim(),
      nameEn: (json['name'] ?? key).toString().trim(),
      lines: lines,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address']?.toString(),
    );
  }
}
