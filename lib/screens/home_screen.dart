import 'package:flutter/material.dart';

import '../models/metro_station.dart';
import '../services/metro_service.dart';
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
  List<MetroStation> _filteredStations = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stations = await _metroService.loadStations();
      if (!mounted) return;
      setState(() {
        _allStations = stations;
        _filteredStations = stations;
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

  void _filter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStations = _allStations;
      } else {
        _filteredStations = _allStations.where((station) {
          return station.nameFa.toLowerCase().contains(query) ||
              station.nameEn.toLowerCase().contains(query) ||
              station.lines.any((line) => line.toString() == query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نزدیک مترو'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStations,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF0B5FFF), Color(0xFF193B9D)],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('کجا می‌خواهی بروی؟', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 5),
                      Text('یک ایستگاه مترو انتخاب کن', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      SizedBox(height: 8),
                      Text('بعد می‌توانی کافه، رستوران، تفریح و مکان‌های دیگر اطرافش را پیدا کنی.', style: TextStyle(color: Colors.white70, height: 1.45)),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'جست‌وجوی نام ایستگاه...',
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
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(message: _error!, onRetry: _loadStations),
              )
            else if (_filteredStations.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('ایستگاهی با این نام پیدا نشد.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.separated(
                  itemCount: _filteredStations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final station = _filteredStations[index];
                    return _StationCard(
                      station: station,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CategoryScreen(station: station)),
                        );
                      },
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

class _StationCard extends StatelessWidget {
  final MetroStation station;
  final VoidCallback onTap;

  const _StationCard({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.directions_subway_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(station.nameFa, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      station.lines.isEmpty ? 'ایستگاه مترو' : station.lines.map((e) => 'خط $e').join(' • '),
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left_rounded),
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
            const Text('دریافت ایستگاه‌ها ناموفق بود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره')),
          ],
        ),
      ),
    );
  }
}
