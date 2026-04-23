import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return _normalize(fromEnv);
    }

    return _normalize('https://sampahdetector.my.id');
  }

  static String _normalize(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api')) {
      return trimmed;
    }
    return '$trimmed/api';
  }
}