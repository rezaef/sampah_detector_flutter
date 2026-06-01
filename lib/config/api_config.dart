import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class ApiConfig {
  const ApiConfig._();

  /// Set true jika ingin menyambung ke backend lokal di laptop Anda saat development (debug).
  /// Set false jika ingin langsung menyambung ke server hosting live (sampahdetector.my.id).
  static const bool useLocalBackend = false;

  /// Base API backend aplikasi.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return _normalize(fromEnv);
    }

    if (useLocalBackend && kDebugMode) {
      // Automatic local IP for development
      try {
        if (!kIsWeb && Platform.isAndroid) {
          return _normalize('http://10.0.2.2:8000');
        }
      } catch (_) {}
      return _normalize('http://127.0.0.1:8000');
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
