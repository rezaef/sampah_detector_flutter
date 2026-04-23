import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const _tokenKey = 'auth.access_token';

  Future<dynamic> get(
    String path, {
    bool requiresAuth = true,
  }) {
    return _send('GET', path, requiresAuth: requiresAuth);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) {
    return _send('POST', path, body: body, requiresAuth: requiresAuth);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) {
    return _send('PUT', path, body: body, requiresAuth: requiresAuth);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) {
    return _send('DELETE', path, body: body, requiresAuth: requiresAuth);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool requiresAuth,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (requiresAuth && (token == null || token.isEmpty)) {
      throw const ApiException('Sesi login tidak tersedia.', statusCode: 401);
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${path.startsWith('/') ? path : '/$path'}');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (requiresAuth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      default:
        throw ApiException('Metode HTTP tidak didukung: $method');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      _extractMessage(decoded, fallback: 'Permintaan ke server gagal.'),
      statusCode: response.statusCode,
    );
  }

  String _extractMessage(dynamic decoded, {required String fallback}) {
    if (decoded is Map<String, dynamic>) {
      final errors = decoded['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value != null) {
            return value.toString();
          }
        }
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded;
    }
    return fallback;
  }
}
