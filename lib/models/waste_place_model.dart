class WastePlaceModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;

  const WastePlaceModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  factory WastePlaceModel.fromNominatim(
    Map<String, dynamic> json, {
    required String category,
  }) {
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0;
    final displayName = json['display_name']?.toString() ?? 'Alamat tidak tersedia';
    final name = json['name']?.toString().trim();

    return WastePlaceModel(
      id: json['osm_id']?.toString() ?? '$displayName-$lat-$lon',
      name: name == null || name.isEmpty ? displayName.split(',').first : name,
      address: displayName,
      latitude: lat,
      longitude: lon,
      category: category,
    );
  }

  factory WastePlaceModel.fromOverpass(
    Map<String, dynamic> element, {
    required String category,
  }) {
    final tags = element['tags'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final center = element['center'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final lat = (element['lat'] as num?)?.toDouble() ??
        (center['lat'] as num?)?.toDouble() ??
        0;
    final lon = (element['lon'] as num?)?.toDouble() ??
        (center['lon'] as num?)?.toDouble() ??
        0;
    final name = _firstNonEmpty([
      tags['name'],
      tags['operator'],
      tags['brand'],
      _defaultName(category),
    ]);

    return WastePlaceModel(
      id: '${element['type']}-${element['id']}',
      name: name,
      address: _buildAddress(tags, lat, lon),
      latitude: lat,
      longitude: lon,
      category: category,
    );
  }

  static String _buildAddress(Map<String, dynamic> tags, double lat, double lon) {
    final parts = <String>[
      if (_value(tags['addr:street']).isNotEmpty) _value(tags['addr:street']),
      if (_value(tags['addr:village']).isNotEmpty) _value(tags['addr:village']),
      if (_value(tags['addr:suburb']).isNotEmpty) _value(tags['addr:suburb']),
      if (_value(tags['addr:city']).isNotEmpty) _value(tags['addr:city']),
      if (_value(tags['addr:state']).isNotEmpty) _value(tags['addr:state']),
    ];

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return 'Koordinat: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'Lokasi tanpa nama';
  }

  static String _value(dynamic value) => value?.toString().trim() ?? '';

  static String _defaultName(String category) {
    switch (category.toLowerCase()) {
      case 'bank sampah':
        return 'Bank sampah / titik daur ulang';
      case 'tps/tpa':
        return 'TPS/TPA';
      case 'drop point':
        return 'Drop point sampah';
      default:
        return 'Lokasi pengelolaan sampah';
    }
  }
}
