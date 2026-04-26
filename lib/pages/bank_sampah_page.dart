import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/waste_place_model.dart';
import '../services/location_service.dart';
import '../services/maps_place_service.dart';
import '../widgets/region_dropdown_picker.dart';

class BankSampahPage extends StatefulWidget {
  const BankSampahPage({super.key});

  @override
  State<BankSampahPage> createState() => _BankSampahPageState();
}

class _BankSampahPageState extends State<BankSampahPage> {
  final MapsPlaceService _mapsPlaceService = MapsPlaceService();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  final List<_PlaceCategory> _categories = const [
    _PlaceCategory(
      label: 'Bank Sampah',
      query: 'bank sampah',
      icon: Icons.recycling_outlined,
    ),
    _PlaceCategory(
      label: 'Pengelolaan',
      query: 'tempat pengelolaan sampah daur ulang',
      icon: Icons.factory_outlined,
    ),
    _PlaceCategory(
      label: 'TPS/TPA',
      query: 'TPS TPA tempat pembuangan sampah',
      icon: Icons.delete_outline,
    ),
    _PlaceCategory(
      label: 'Drop Point',
      query: 'drop point sampah daur ulang',
      icon: Icons.pin_drop_outlined,
    ),
  ];

  List<WastePlaceModel> _places = [];
  int _selectedCategoryIndex = 0;
  int? _selectedPlaceIndex;

  double? _currentLat;
  double? _currentLng;
  String _selectedAreaText = 'Surabaya, Jawa Timur';
  bool _useManualRegion = false;
  bool _isLoading = true;
  String? _errorMessage;

  static const LatLng _defaultCenter = LatLng(-7.3200, 112.7289);

  @override
  void initState() {
    super.initState();
    _initLocationAndSearch();
  }

  Future<void> _initLocationAndSearch() async {
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _currentLat = position?.latitude;
      _currentLng = position?.longitude;
      _isLoading = false;
    });

    await _searchPlaces();
  }

  Future<void> _searchPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final category = _categories[_selectedCategoryIndex];
      final area = _selectedAreaText.trim().isEmpty
          ? 'Indonesia'
          : _selectedAreaText.trim();
      final useDeviceLocation = !_useManualRegion &&
          _currentLat != null &&
          _currentLng != null;

      final result = await _mapsPlaceService.searchPlaces(
        query: '${category.query} di $area Indonesia',
        category: category.label,
        areaText: area,
        latitude: useDeviceLocation ? _currentLat : null,
        longitude: useDeviceLocation ? _currentLng : null,
      );

      if (_currentLat != null && _currentLng != null) {
        result.sort((a, b) {
          final distanceA = _distanceKm(
            _currentLat!,
            _currentLng!,
            a.latitude,
            a.longitude,
          );
          final distanceB = _distanceKm(
            _currentLat!,
            _currentLng!,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }

      if (!mounted) return;
      setState(() {
        _places = result;
        _selectedPlaceIndex = result.isEmpty ? null : 0;
        _isLoading = false;
      });

      if (result.isNotEmpty) {
        final first = result.first;
        _moveCameraTo(LatLng(first.latitude, first.longitude), zoom: 14);
      } else if (useDeviceLocation) {
        _moveCameraTo(LatLng(_currentLat!, _currentLng!), zoom: 13);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _places = [];
        _selectedPlaceIndex = null;
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Marker> get _markers {
    final markers = <Marker>[];

    if (_currentLat != null && _currentLng != null) {
      markers.add(
        Marker(
          point: LatLng(_currentLat!, _currentLng!),
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black26,
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }

    markers.addAll(
      _places.asMap().entries.map((entry) {
        final index = entry.key;
        final place = entry.value;
        final selected = index == _selectedPlaceIndex;

        return Marker(
          point: LatLng(place.latitude, place.longitude),
          width: selected ? 54 : 46,
          height: selected ? 54 : 46,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlaceIndex = index;
              });
              _moveCameraTo(LatLng(place.latitude, place.longitude), zoom: 16);
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black26,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _categories[_selectedCategoryIndex].icon,
                color: Colors.white,
                size: selected ? 27 : 23,
              ),
            ),
          ),
        );
      }),
    );

    return markers;
  }

  LatLng get _initialCenter {
    if (_currentLat != null && _currentLng != null && !_useManualRegion) {
      return LatLng(_currentLat!, _currentLng!);
    }
    return _defaultCenter;
  }

  WastePlaceModel? get _selectedPlace {
    final index = _selectedPlaceIndex;
    if (index == null || index < 0 || index >= _places.length) {
      return null;
    }
    return _places[index];
  }

  void _moveCameraTo(LatLng target, {double zoom = 15}) {
    _mapController.move(target, zoom);
  }

  void _onRegionChanged(RegionSelection selection) {
    final text = selection.areaText.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _selectedAreaText = text;
      _useManualRegion = true;
    });
    _searchPlaces();
  }

  Future<void> _useNearestLocation() async {
    setState(() {
      _useManualRegion = false;
      _selectedAreaText = 'sekitar lokasi saya';
    });

    if (_currentLat == null || _currentLng == null) {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLat = position?.latitude;
        _currentLng = position?.longitude;
      });
    }

    await _searchPlaces();
  }

  Future<void> _openInMaps(WastePlaceModel place) async {
    Uri uri;

    if (_currentLat != null && _currentLng != null) {
      uri = Uri.https(
        'www.openstreetmap.org',
        '/directions',
        {
          'from': '$_currentLat,$_currentLng',
          'to': '${place.latitude},${place.longitude}',
        },
      );
    } else {
      uri = Uri.https(
        'www.openstreetmap.org',
        '/',
        {
          'mlat': place.latitude.toString(),
          'mlon': place.longitude.toString(),
          'zoom': '17',
        },
      );
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _distanceLabel(WastePlaceModel place) {
    if (_currentLat == null || _currentLng == null) {
      return null;
    }

    final distance = _distanceKm(
      _currentLat!,
      _currentLng!,
      place.latitude,
      place.longitude,
    );

    if (distance < 1) {
      return '${(distance * 1000).round()} m dari lokasi kamu';
    }

    final formatted = distance < 10
        ? distance.toStringAsFixed(1)
        : distance.toStringAsFixed(0);
    return '$formatted km dari lokasi kamu';
  }

  double _distanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLat)) *
            math.cos(_toRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories[_selectedCategoryIndex];
    final selectedPlace = _selectedPlace;

    return Scaffold(
      appBar: AppBar(title: const Text('Peta Lokasi Bank Sampah')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeaderCard(
            title: selectedCategory.label == 'Bank Sampah'
                ? 'Cari bank sampah terdekat tanpa API key berbayar.'
                : 'Cari lokasi pengelolaan sampah berbasis OpenStreetMap.',
            subtitle: _useManualRegion
                ? 'Wilayah aktif: $_selectedAreaText'
                : _currentLat == null
                    ? 'Pilih wilayah Indonesia secara bertahap, atau aktifkan GPS untuk lokasi terdekat.'
                    : 'Mode terdekat aktif dari lokasi perangkat kamu.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih wilayah Indonesia',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  RegionDropdownPicker(
                    compact: true,
                    initialHelperText:
                        'Urutkan pilihan dari provinsi, kabupaten/kota, kecamatan, lalu kelurahan/desa.',
                    onChanged: _onRegionChanged,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _useNearestLocation,
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Gunakan lokasi terdekat saya'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ChoiceChip(
                  avatar: Icon(category.icon, size: 18),
                  label: Text(category.label),
                  selected: _selectedCategoryIndex == index,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                    _searchPlaces();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 360,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 13,
                      minZoom: 4,
                      maxZoom: 19,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.sampah_detector_mobile',
                      ),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                  const Positioned(
                    left: 8,
                    bottom: 8,
                    child: _OsmAttribution(),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.white.withOpacity(0.72),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(
              message: _errorMessage!,
              onRetry: _searchPlaces,
            ),
          ],
          if (selectedPlace != null) ...[
            const SizedBox(height: 16),
            _SelectedPlaceCard(
              place: selectedPlace,
              distanceLabel: _distanceLabel(selectedPlace),
              onFocus: () => _moveCameraTo(
                LatLng(selectedPlace.latitude, selectedPlace.longitude),
                zoom: 16,
              ),
              onOpenMaps: () => _openInMaps(selectedPlace),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daftar lokasi',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: _searchPlaces,
                tooltip: 'Muat ulang',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_places.isEmpty && !_isLoading)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Belum ada lokasi ditemukan dari OpenStreetMap. Coba pilih wilayah yang lebih luas, aktifkan lokasi terdekat, atau pilih kategori lain.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ..._places.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlaceListCard(
                      place: entry.value,
                      isSelected: entry.key == _selectedPlaceIndex,
                      distanceLabel: _distanceLabel(entry.value),
                      onTap: () {
                        setState(() {
                          _selectedPlaceIndex = entry.key;
                        });
                        _moveCameraTo(
                          LatLng(entry.value.latitude, entry.value.longitude),
                          zoom: 16,
                        );
                      },
                      onOpenMaps: () => _openInMaps(entry.value),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF134E4A), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.94),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '© OpenStreetMap contributors',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  final WastePlaceModel place;
  final String? distanceLabel;
  final VoidCallback onFocus;
  final VoidCallback onOpenMaps;

  const _SelectedPlaceCard({
    required this.place,
    required this.distanceLabel,
    required this.onFocus,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              place.address,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 16),
                  label: Text(place.category),
                ),
                if (distanceLabel != null)
                  Chip(
                    avatar: const Icon(Icons.route_outlined, size: 16),
                    label: Text(distanceLabel!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFocus,
                    icon: const Icon(Icons.center_focus_strong_outlined),
                    label: const Text('Fokus peta'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpenMaps,
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Rute'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceListCard extends StatelessWidget {
  final WastePlaceModel place;
  final bool isSelected;
  final String? distanceLabel;
  final VoidCallback onTap;
  final VoidCallback onOpenMaps;

  const _PlaceListCard({
    required this.place,
    required this.isSelected,
    required this.distanceLabel,
    required this.onTap,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.42)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(place.category)),
                        if (distanceLabel != null) Chip(label: Text(distanceLabel!)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenMaps,
                tooltip: 'Buka rute',
                icon: const Icon(Icons.directions_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCategory {
  final String label;
  final String query;
  final IconData icon;

  const _PlaceCategory({
    required this.label,
    required this.query,
    required this.icon,
  });
}
