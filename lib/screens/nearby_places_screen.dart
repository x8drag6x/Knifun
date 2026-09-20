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

  static const _radiusOptions = <int>[500, 1000, 2000, 3000];

  List<NearbyPlace> _places = const [];
  bool _loading = true;
  String? _error;
  int _radius = 1000;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

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

      if (places.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(widget.station.position, _radius <= 500 ? 15.2 : 14.8);
        });
      }
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('شعاع جست‌وجو', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                ..._radiusOptions.map(
                  (value) => RadioListTile<int>(
                    value: value,
                    groupValue: _radius,
                    title: Text(_radiusLabel(value), textDirection: TextDirection.rtl),
                    onChanged: (selected) => Navigator.pop(context, selected),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted || selected == _radius) return;
    setState(() => _radius = selected);
    await _loadPlaces();
  }

  static String _radiusLabel(int meters) =>
      meters >= 1000 ? '${meters ~/ 1000} کیلومتر' : '$meters متر';

  Future<void> _openNavigation(NearbyPlace place) async {
    final opened = await NavigationService.openDirections(
      latitude: place.latitude,
      longitude: place.longitude,
      label: place.name,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('باز کردن برنامهٔ نقشه ممکن نبود.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loading ? null : _changeRadius,
            tooltip: 'شعاع جست‌وجو',
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: _loading
          ? _LoadingBody(categoryTitle: widget.category.title)
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _loadPlaces)
              : RefreshIndicator(
                  onRefresh: _loadPlaces,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _MapPanel(
                          station: widget.station,
                          places: _places,
                          controller: _mapController,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Text(
                                '${_places.length} نتیجه',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'تا ${_radiusLabel(_radius)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_places.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'در این شعاع مکان نام‌گذاری‌شده‌ای پیدا نشد.\nمی‌توانی شعاع بیشتری را امتحان کنی.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                          sliver: SliverList.separated(
                            itemCount: _places.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final place = _places[index];
                              return _PlaceCard(
                                place: place,
                                onOpenNavigation: () => _openNavigation(place),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  final String categoryTitle;

  const _LoadingBody({required this.categoryTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'در حال جست‌وجوی $categoryTitle در اطراف ایستگاه…',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'ممکن است پاسخ چند ثانیه زمان ببرد.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPanel extends StatefulWidget {
  final MetroStation station;
  final List<NearbyPlace> places;
  final MapController controller;

  const _MapPanel({
    required this.station,
    required this.places,
    required this.controller,
  });

  @override
  State<_MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<_MapPanel> {
  // Labels stay hidden at the normal overview zoom and appear only after
  // the user zooms in enough to identify nearby places individually.
  static const double _placeLabelZoom = 16.0;

  bool _showPlaceLabels = false;

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final shouldShowLabels = camera.zoom >= _placeLabelZoom;
    if (shouldShowLabels == _showPlaceLabels) return;

    setState(() {
      _showPlaceLabels = shouldShowLabels;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            initialCenter: widget.station.position,
            initialZoom: 14.8,
            minZoom: 11,
            maxZoom: 19,
            onPositionChanged: _onPositionChanged,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ir.metroaroundtehran.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.station.position,
                  width: 48,
                  height: 48,
                  child: const _MetroMarker(),
                ),
                ...widget.places.map(
                  (place) => Marker(
                    // The coordinate is still exactly place.position. Only the
                    // widget drawn around that coordinate gets larger when a
                    // label is visible; the actual LatLng is never modified.
                    point: place.position,
                    width: 160,
                    height: 80,
                    alignment: Alignment.center,
                    child: _PlaceMarkerWithLabel(
                      place: place,
                      showLabel: _showPlaceLabels,
                    ),
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

class _PlaceMarkerWithLabel extends StatelessWidget {
  final NearbyPlace place;
  final bool showLabel;

  const _PlaceMarkerWithLabel({
    required this.place,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (showLabel)
          Positioned(
            top: 2,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0B5FFF).withValues(alpha: 0.18),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    spreadRadius: 0.5,
                    color: Colors.black26,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0B5FFF), width: 2),
              boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
            ),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.place_rounded, color: Color(0xFF0B5FFF), size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final NearbyPlace place;
  final VoidCallback onOpenNavigation;

  const _PlaceCard({required this.place, required this.onOpenNavigation});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpenNavigation,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              _PlaceImage(place: place),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      place.name,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatDistance(place.distanceMeters)}  •  ${place.address ?? 'آدرس در OSM ثبت نشده'}',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'مسیریابی',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.navigation_rounded, size: 17, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  final NearbyPlace place;

  const _PlaceImage({required this.place});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B5FFF), Color(0xFF81A9FF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
    );

    final url = place.imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          cacheWidth: 240,
          cacheHeight: 240,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return fallback;
          },
        ),
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
