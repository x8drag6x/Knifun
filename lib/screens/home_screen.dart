import 'package:flutter/material.dart';

import '../models/metro_station.dart';
import '../services/metro_service.dart';
import '../utils/metro_ui.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _metroService = MetroService();
  final _searchController = TextEditingController();

  List<MetroStation> _allStations = const [];
  Map<int, List<MetroStation>> _stationsByLine = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
    _loadStations();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadStations({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stations = await _metroService.loadStations(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _allStations = stations;
        _stationsByLine = {
          for (var line = 1; line <= 7; line++)
            line: _metroService.stationsForLine(stations, line),
        };
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

  void _refreshSearch() => setState(() {});

  List<MetroStation> _visibleStationsForLine(int line) {
    final query = _searchController.text.trim().toLowerCase();
    final stations = _stationsByLine[line] ?? const <MetroStation>[];
    if (query.isEmpty) return stations;

    return stations.where((station) {
      return station.nameFa.toLowerCase().contains(query) ||
          station.nameEn.toLowerCase().contains(query) ||
          'خط $line'.contains(query) ||
          line.toString() == query;
    }).toList();
  }

  int get _visibleCount {
    var count = 0;
    for (var line = 1; line <= 7; line++) {
      count += _visibleStationsForLine(line).length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نزدیک مترو'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadStations(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              sliver: SliverToBoxAdapter(
                child: _HeroCard(totalStations: _allStations.length),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'جست‌وجوی نام ایستگاه یا شماره خط...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  message: _error!,
                  onRetry: () => _loadStations(forceRefresh: true),
                ),
              )
            else if (_visibleCount == 0)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('ایستگاهی با این عبارت پیدا نشد.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.separated(
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final line = index + 1;
                    final stations = _visibleStationsForLine(line);

                    // Hide lines that have no matching stations while searching.
                    if (stations.isEmpty) return const SizedBox.shrink();

                    return _LineExpansionTile(
                      line: line,
                      stations: stations,
                      searching: _searchController.text.trim().isNotEmpty,
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

class _HeroCard extends StatelessWidget {
  final int totalStations;

  const _HeroCard({required this.totalStations});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B5FFF), Color(0xFF193B9D)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B5FFF),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.directions_subway_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'کجا می‌خواهی بروی؟',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'ایستگاه مترو را انتخاب کن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'بعد می‌توانی مکان‌های اطراف را پیدا کنی و برایشان مسیر بگیری.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          if (totalStations > 0) ...[
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  '$totalStations',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineExpansionTile extends StatelessWidget {
  final int line;
  final List<MetroStation> stations;
  final bool searching;

  const _LineExpansionTile({
    required this.line,
    required this.stations,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    final color = metroLineColor(line);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: color.withValues(alpha: 0.08),
            highlightColor: color.withValues(alpha: 0.04),
          ),
          child: ExpansionTile(
            initiallyExpanded: searching,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            expandedAlignment: Alignment.centerRight,
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            leading: Container(
              width: 12,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            title: Text(
              'خط $line',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            subtitle: Text(
              '${stations.length} ایستگاه',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: Icon(Icons.expand_more_rounded, color: color),
            children: [
              ...stations.map(
                (station) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _StationCard(
                    station: station,
                    line: line,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryScreen(
                            station: station,
                            selectedLine: line,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final MetroStation station;
  final int line;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.line,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = metroLineColor(line);
    final interchange = station.lines.length > 1;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      color.withValues(alpha: 0.20),
                      color.withValues(alpha: 0.07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Icon(Icons.directions_subway_rounded, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      station.nameFa,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (interchange)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'تغییر خط',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          'خط $line',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_left_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 54),
            const SizedBox(height: 16),
            const Text(
              'دریافت ایستگاه‌ها ناموفق بود',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}
