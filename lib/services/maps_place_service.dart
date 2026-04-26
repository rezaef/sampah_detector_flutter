import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/waste_place_model.dart';

class MapsPlaceService {
  MapsPlaceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _nominatimHost = 'nominatim.openstreetmap.org';
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static DateTime? _lastNominatimRequest;

  static const Map<String, String> _headers = {
    'User-Agent': 'sampah_detector_mobile/1.0 (student project)',
    'Accept-Language': 'id,en;q=0.8',
  };

  Future<List<WastePlaceModel>> searchPlaces({
    required String query,
    required String category,
    String? areaText,
    double? latitude,
    double? longitude,
    double radiusMeters = 12000,
  }) async {
    final radius = radiusMeters.clamp(3000, 30000).round();

    if (latitude != null && longitude != null) {
      final nearby = await _tryOverpass(
        category: category,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
      );
      if (nearby.isNotEmpty) {
        return nearby;
      }

      return _searchNominatim(query: query, category: category, limit: 15);
    }

    final area = areaText?.trim() ?? '';
    if (area.isNotEmpty) {
      final center = await _geocodeArea('$area, Indonesia');
      if (center != null) {
        final nearby = await _tryOverpass(
          category: category,
          latitude: center.latitude,
          longitude: center.longitude,
          radiusMeters: 20000,
        );
        if (nearby.isNotEmpty) {
          return nearby;
        }
      }
    }

    return _searchNominatim(query: query, category: category, limit: 15);
  }

  Future<_OsmPoint?> _geocodeArea(String area) async {
    final uri = Uri.https(_nominatimHost, '/search', {
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'id',
      'q': area,
    });

    final response = await _nominatimGet(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    if (decoded.isEmpty) {
      return null;
    }

    final first = decoded.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) {
      return null;
    }

    return _OsmPoint(lat, lon);
  }

  Future<List<WastePlaceModel>> _searchNominatim({
    required String query,
    required String category,
    int limit = 15,
  }) async {
    final uri = Uri.https(_nominatimHost, '/search', {
      'format': 'jsonv2',
      'limit': limit.toString(),
      'countrycodes': 'id',
      'addressdetails': '1',
      'q': query,
    });

    final response = await _nominatimGet(uri);
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data dari OpenStreetMap/Nominatim.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return _deduplicate(
      decoded
          .map(
            (item) => WastePlaceModel.fromNominatim(
              item as Map<String, dynamic>,
              category: category,
            ),
          )
          .where((place) => place.latitude != 0 && place.longitude != 0)
          .toList(),
    );
  }

  Future<List<WastePlaceModel>> _tryOverpass({
    required String category,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    try {
      return await _searchOverpass(
        category: category,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
    } catch (_) {
      return <WastePlaceModel>[];
    }
  }

  Future<List<WastePlaceModel>> _searchOverpass({
    required String category,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    final query = _buildOverpassQuery(
      category: category,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    final response = await _client.post(
      Uri.parse(_overpassUrl),
      headers: _headers,
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data dari Overpass API.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? <dynamic>[];

    final places = elements
        .map(
          (item) => WastePlaceModel.fromOverpass(
            item as Map<String, dynamic>,
            category: category,
          ),
        )
        .where((place) => place.latitude != 0 && place.longitude != 0)
        .toList();

    return _deduplicate(places).take(30).toList();
  }

  String _buildOverpassQuery({
    required String category,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    final filters = _filtersForCategory(category);
    final lines = <String>['[out:json][timeout:25];', '('];

    for (final filter in filters) {
      lines
        ..add('node(around:$radiusMeters,$latitude,$longitude)$filter;')
        ..add('way(around:$radiusMeters,$latitude,$longitude)$filter;')
        ..add('relation(around:$radiusMeters,$latitude,$longitude)$filter;');
    }

    lines
      ..add(');')
      ..add('out center tags 40;');

    return lines.join('\n');
  }

  List<String> _filtersForCategory(String category) {
    final lower = category.toLowerCase();

    if (lower.contains('bank')) {
      return const [
        '["name"~"bank sampah",i]',
        '["amenity"="recycling"]',
        '["recycling_type"="centre"]',
      ];
    }

    if (lower.contains('tps') || lower.contains('tpa')) {
      return const [
        '["name"~"tps|tpa|tempat pembuangan",i]',
        '["amenity"="waste_disposal"]',
        '["amenity"="waste_transfer_station"]',
        '["landuse"="landfill"]',
      ];
    }

    if (lower.contains('drop')) {
      return const [
        '["name"~"drop point|dropbox|drop off|bank sampah",i]',
        '["amenity"="recycling"]',
        '["recycling_type"="container"]',
      ];
    }

    return const [
      '["amenity"="recycling"]',
      '["amenity"="waste_disposal"]',
      '["amenity"="waste_transfer_station"]',
      '["landuse"="landfill"]',
      '["name"~"daur ulang|sampah|recycling|waste",i]',
    ];
  }

  Future<http.Response> _nominatimGet(Uri uri) async {
    final last = _lastNominatimRequest;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      const minimumGap = Duration(milliseconds: 1100);
      if (elapsed < minimumGap) {
        await Future<void>.delayed(minimumGap - elapsed);
      }
    }

    final response = await _client.get(uri, headers: _headers);
    _lastNominatimRequest = DateTime.now();
    return response;
  }

  List<WastePlaceModel> _deduplicate(List<WastePlaceModel> places) {
    final seen = <String>{};
    final result = <WastePlaceModel>[];

    for (final place in places) {
      final key = '${place.name.toLowerCase()}-'
          '${place.latitude.toStringAsFixed(4)}-'
          '${place.longitude.toStringAsFixed(4)}';
      if (seen.add(key)) {
        result.add(place);
      }
    }

    return result;
  }
}

class _OsmPoint {
  final double latitude;
  final double longitude;

  const _OsmPoint(this.latitude, this.longitude);
}
