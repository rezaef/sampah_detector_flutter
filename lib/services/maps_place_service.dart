import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/waste_place_model.dart';

class MapsPlaceService {
  MapsPlaceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<WastePlaceModel>> searchPlaces({
    required String query,
    required String category,
    String? areaText,
    double? latitude,
    double? longitude,
    double radiusMeters = 12000,
  }) async {
    final apiKey = ApiConfig.googleMapsApiKey;
    if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
      throw Exception('API Key Google Maps belum dikonfigurasi di ApiConfig.');
    }

    final Map<String, String> params = {
      'query': query,
      'key': apiKey,
      'language': 'id',
    };

    if (latitude != null && longitude != null) {
      params['location'] = '$latitude,$longitude';
      params['radius'] = radiusMeters.round().toString();
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/textsearch/json', params);

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Gagal menghubungi Google Places API: status ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] == 'REQUEST_DENIED') {
        final error = decoded['error_message'] ?? 'Akses ditolak oleh Google API.';
        throw Exception('Google API Error: $error');
      }

      final results = decoded['results'] as List<dynamic>? ?? [];
      final places = results.map((item) {
        final map = item as Map<String, dynamic>;
        final geometry = map['geometry'] as Map<String, dynamic>? ?? {};
        final location = geometry['location'] as Map<String, dynamic>? ?? {};
        final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;
        
        return WastePlaceModel(
          id: map['place_id']?.toString() ?? '$lat-$lng',
          name: map['name']?.toString() ?? 'Lokasi Pengelolaan Sampah',
          address: map['formatted_address']?.toString() ?? map['vicinity']?.toString() ?? 'Alamat tidak tersedia',
          latitude: lat,
          longitude: lng,
          category: category,
        );
      }).toList();

      return _deduplicate(places);
    } catch (e) {
      throw Exception('Pencarian Google Places gagal: $e');
    }
  }

  Future<List<double>?> geocodeAreaText(String area) async {
    final apiKey = ApiConfig.googleMapsApiKey;
    if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
      return null;
    }

    var query = area.trim();
    if (!query.toLowerCase().contains('indonesia')) {
      query = '$query, Indonesia';
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': query,
      'key': apiKey,
      'language': 'id',
    });

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != 'OK') return null;

      final results = decoded['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>? ?? {};
      final location = geometry['location'] as Map<String, dynamic>? ?? {};
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        return [lat, lng];
      }
    } catch (_) {}
    return null;
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
