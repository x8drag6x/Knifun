import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  /// Opens a regular Google Maps Directions URL without requiring a Google Maps API key.
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final destination = '$latitude,$longitude';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}',
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
