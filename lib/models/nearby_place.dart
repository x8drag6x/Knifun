import 'package:latlong2/latlong.dart';

class NearbyPlace {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? address;
  final String? imageUrl;
  final double distanceMeters;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.address,
    this.imageUrl,
  });

  LatLng get position => LatLng(latitude, longitude);

  factory NearbyPlace.fromOverpass(Map<String, dynamic> json, LatLng origin) {
    final tags = (json['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final center = (json['center'] as Map?)?.cast<String, dynamic>();
    final lat = json['lat'] ?? center?['lat'];
    final lon = json['lon'] ?? center?['lon'];

    final latitude = double.parse(lat.toString());
    final longitude = double.parse(lon.toString());

    final rawName = (tags['name:fa'] ?? tags['name'] ?? '').toString().trim();
    if (rawName.isEmpty) {
      throw const FormatException('Unnamed OSM object');
    }

    final distance = const Distance().as(
      LengthUnit.Meter,
      origin,
      LatLng(latitude, longitude),
    );

    final street = tags['addr:street']?.toString().trim();
    final housenumber = tags['addr:housenumber']?.toString().trim();
    final address = [street, housenumber]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');

    return NearbyPlace(
      id: '${json['type']}:${json['id']}',
      name: rawName,
      type: _detectType(tags),
      latitude: latitude,
      longitude: longitude,
      address: address.isEmpty ? null : address,
      imageUrl: _extractImageUrl(tags),
      distanceMeters: distance,
    );
  }

  static String? _extractImageUrl(Map<String, dynamic> tags) {
    final direct = tags['image']?.toString().trim();
    if (direct != null && _isHttpUrl(direct)) return direct;

    final commons = tags['wikimedia_commons']?.toString().trim();
    if (commons != null && commons.isNotEmpty) {
      final fileName = commons.startsWith('File:') ? commons.substring(5) : commons;
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/${Uri.encodeComponent(fileName)}';
    }

    return null;
  }

  static bool _isHttpUrl(String value) =>
      value.startsWith('https://') || value.startsWith('http://');

  static String _detectType(Map<String, dynamic> tags) {
    return (tags['amenity'] ?? tags['tourism'] ?? tags['leisure'] ?? tags['shop'] ?? 'place').toString();
  }
}
