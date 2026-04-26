class ApiConfig {
  const ApiConfig._();

  /// Base API backend aplikasi.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return _normalize(fromEnv);
    }

    return _normalize('https://sampahdetector.my.id');
  }

  /// Versi peta gratis memakai OpenStreetMap + flutter_map.
  /// Tidak perlu API key Google Maps.
  static const bool useOpenStreetMap = true;

  static String _normalize(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api')) {
      return trimmed;
    }
    return '$trimmed/api';
  }
}
