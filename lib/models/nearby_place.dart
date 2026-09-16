import 'package:latlong2/latlong.dart';

class NearbyPlace {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? address;
  final double distanceMeters;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.address,
  });

  LatLng get position => LatLng(latitude, longitude);

  factory NearbyPlace.fromOverpass(Map<String, dynamic> json, LatLng origin) {
    final tags = (json['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final center = (json['center'] as Map?)?.cast<String, dynamic>();
    final lat = json['lat'] ?? center?['lat'];
    final lon = json['lon'] ?? center?['lon'];

    final latitude = double.parse(lat.toString());
    final longitude = double.parse(lon.toString());

    final distance = const Distance().as(
      LengthUnit.Meter,
      origin,
      LatLng(latitude, longitude),
    );

    final street = tags['addr:street']?.toString();
    final housenumber = tags['addr:housenumber']?.toString();
    final address = [street, housenumber]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    return NearbyPlace(
      id: '${json['type']}:${json['id']}',
      name: (tags['name:fa'] ?? tags['name'] ?? 'مکان بدون نام').toString(),
      type: _detectType(tags),
      latitude: latitude,
      longitude: longitude,
      address: address.isEmpty ? null : address,
      distanceMeters: distance,
    );
  }

  static String _detectType(Map<String, dynamic> tags) {
    return (tags['amenity'] ?? tags['tourism'] ?? tags['leisure'] ?? tags['shop'] ?? 'place').toString();
  }
}
