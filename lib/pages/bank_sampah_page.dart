import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _googleMapController;

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

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
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
      
      double? searchLat;
      double? searchLng;

      if (_useManualRegion) {
        final coords = await _mapsPlaceService.geocodeAreaText(area);
        if (coords != null) {
          searchLat = coords[0];
          searchLng = coords[1];
        }
      } else {
        searchLat = _currentLat;
        searchLng = _currentLng;
      }

      final result = await _mapsPlaceService.searchPlaces(
        query: '${category.query} di $area Indonesia',
        category: category.label,
        areaText: area,
        latitude: searchLat,
        longitude: searchLng,
      );

      final sortLat = searchLat ?? _currentLat;
      final sortLng = searchLng ?? _currentLng;
      if (sortLat != null && sortLng != null) {
        result.sort((a, b) {
          final distanceA = _distanceKm(
            sortLat,
            sortLng,
            a.latitude,
            a.longitude,
          );
          final distanceB = _distanceKm(
            sortLat,
            sortLng,
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
      } else if (sortLat != null && sortLng != null) {
        _moveCameraTo(LatLng(sortLat, sortLng), zoom: 13);
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

  Set<Marker> get _markers {
    final markers = <Marker>{};

    for (var index = 0; index < _places.length; index++) {
      final place = _places[index];
      final selected = index == _selectedPlaceIndex;

      double hue = BitmapDescriptor.hueRed;
      switch (_selectedCategoryIndex) {
        case 0: // Bank Sampah
          hue = selected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueGreen;
          break;
        case 1: // Pengelolaan
          hue = selected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueAzure;
          break;
        case 2: // TPS/TPA
          hue = selected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueRed;
          break;
        case 3: // Drop Point
          hue = selected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueOrange;
          break;
      }

      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.category,
          ),
          onTap: () {
            setState(() {
              _selectedPlaceIndex = index;
            });
            _moveCameraTo(LatLng(place.latitude, place.longitude), zoom: 16);
          },
        ),
      );
    }

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
    _googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
        ),
      ),
    );
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
    final destination = '${place.latitude},${place.longitude}';
    final origin = (_currentLat != null && _currentLng != null)
        ? '${_currentLat},${_currentLng}'
        : '';
        
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
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
      appBar: AppBar(title: const Text('Peta Lokasi Sampah')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeaderCard(
            title: selectedCategory.label == 'Bank Sampah'
                ? 'Temukan bank sampah dan titik daur ulang terdekat.'
                : 'Temukan ${selectedCategory.label.toLowerCase()} di sekitar lokasi Anda.',
            subtitle: _useManualRegion
                ? 'Wilayah aktif: $_selectedAreaText'
                : _currentLat == null
                    ? 'Pilih wilayah atau aktifkan GPS untuk mencari lokasi terdekat.'
                    : 'Menampilkan hasil berdasarkan lokasi perangkat saat ini.',
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F8A70).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF1F8A70).withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Wilayah Indonesia',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B4D3E),
                    ),
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
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.my_location_outlined, size: 20),
                    label: const Text('Gunakan Lokasi Terdekat Saya', style: TextStyle(fontSize: 14)),
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
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F8A70).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF1F8A70).withOpacity(0.06),
                width: 1,
              ),
            ),
            child: SizedBox(
              height: 360,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialCenter,
                      zoom: 13,
                    ),
                    myLocationEnabled: _currentLat != null && _currentLng != null,
                    myLocationButtonEnabled: false,
                    markers: _markers,
                    onMapCreated: (controller) {
                      _googleMapController = controller;
                    },
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
              const Expanded(
                child: Text(
                  'Daftar Lokasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B4D3E),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: _searchPlaces,
                tooltip: 'Muat ulang',
                icon: const Icon(Icons.refresh, color: Color(0xFF1F8A70)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_places.isEmpty && !_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1F8A70).withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Tidak ditemukan lokasi untuk kategori ini di wilayah yang dipilih. Coba perluas area pencarian atau gunakan kategori lain.',
                  style: TextStyle(color: Color(0xFF507A6D), height: 1.35),
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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F8A70), Color(0xFF35A285)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text('Coba lagi', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1F8A70).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              place.address,
              style: const TextStyle(
                color: Color(0xFF507A6D),
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 16, color: Color(0xFF1F8A70)),
                  label: Text(place.category),
                ),
                if (distanceLabel != null)
                  Chip(
                    avatar: const Icon(Icons.route_outlined, size: 16, color: Color(0xFF1F8A70)),
                    label: Text(distanceLabel!),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFocus,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
                    label: const Text('Fokus Peta', style: TextStyle(fontSize: 13.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpenMaps,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text('Rute', style: TextStyle(fontSize: 13.5)),
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
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1F8A70).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1F8A70)
              : const Color(0xFF1F8A70).withOpacity(0.06),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F8A70).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF1F8A70),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.address,
                        style: const TextStyle(
                          color: Color(0xFF507A6D),
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(place.category),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          if (distanceLabel != null) 
                            Chip(
                              label: Text(distanceLabel!),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onOpenMaps,
                  tooltip: 'Buka rute',
                  icon: const Icon(Icons.directions_outlined, color: Color(0xFF1F8A70)),
                ),
              ],
            ),
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
