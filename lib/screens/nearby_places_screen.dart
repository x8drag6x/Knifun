import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/metro_station.dart';
import '../models/nearby_place.dart';
import '../models/place_category.dart';
import '../services/navigation_service.dart';
import '../services/overpass_service.dart';
import '../utils/formatters.dart';

class NearbyPlacesScreen extends StatefulWidget {
  final MetroStation station;
  final PlaceCategory category;

  const NearbyPlacesScreen({
    super.key,
    required this.station,
    required this.category,
  });

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  final _overpass = OverpassService();
  final _mapController = MapController();

  List<NearbyPlace> _places = const [];
  bool _loading = true;
  String? _error;
  int _radius = 1200;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final places = await _overpass.findNearby(
        center: widget.station.position,
        category: widget.category,
        radiusMeters: _radius,
      );
      if (!mounted) return;
      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _changeRadius() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final options = [500, 1000, 1200, 2000, 3000];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('شعاع جست‌وجو', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                ...options.map(
                  (value) => RadioListTile<int>(
                    value: value,
                    groupValue: _radius,
                    title: Text(value >= 1000 ? '${value ~/ 1000} کیلومتر' : '$value متر', textDirection: TextDirection.rtl),
                    onChanged: (selected) => Navigator.pop(context, selected),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => _radius = selected);
    await _loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _changeRadius, tooltip: 'شعاع جست‌وجو', icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _loadPlaces)
              : RefreshIndicator(
                  onRefresh: _loadPlaces,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _MapPanel(station: widget.station, places: _places, controller: _mapController)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Text('${_places.length} نتیجه', style: const TextStyle(fontWeight: FontWeight.w900)),
                              const Spacer(),
                              Text('تا ${_radius >= 1000 ? '${(_radius / 1000).toStringAsFixed(_radius % 1000 == 0 ? 0 : 1)} کیلومتر' : '$_radius متر'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                      if (_places.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('در این شعاع موردی پیدا نشد.')),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          sliver: SliverList.separated(
                            itemCount: _places.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _PlaceCard(place: _places[index]),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  final MetroStation station;
  final List<NearbyPlace> places;
  final MapController controller;

  const _MapPanel({required this.station, required this.places, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: station.position,
            initialZoom: 14.8,
            minZoom: 11,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ir.metroaroundtehran.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: station.position,
                  width: 48,
                  height: 48,
                  child: const _MetroMarker(),
                ),
                ...places.map(
                  (place) => Marker(
                    point: place.position,
                    width: 38,
                    height: 38,
                    child: const _PlaceMarker(),
                  ),
                ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetroMarker extends StatelessWidget {
  const _MetroMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B5FFF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: const Icon(Icons.directions_subway_rounded, color: Colors.white, size: 24),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0B5FFF), width: 2),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: const Icon(Icons.place_rounded, color: Color(0xFF0B5FFF), size: 22),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final NearbyPlace place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.place_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(place.name, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(
                  '${formatDistance(place.distanceMeters)}  •  ${place.address ?? 'آدرس ثبت نشده'}',
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'مسیریابی',
            onPressed: () async {
              final opened = await NavigationService.openDirections(
                latitude: place.latitude,
                longitude: place.longitude,
                label: place.name,
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('باز کردن برنامهٔ نقشه ممکن نبود.')));
              }
            },
            icon: const Icon(Icons.navigation_rounded),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 14),
            const Text('جست‌وجوی مکان‌ها ناموفق بود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره')),
          ],
        ),
      ),
    );
  }
}
