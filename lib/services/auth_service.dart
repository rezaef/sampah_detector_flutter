import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import 'api_client.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _sessionKey = 'auth.current_user';
  static const _tokenKey = 'auth.access_token';

  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '1007262464293-8h5suimordefvn8fcrg19a1ko9ueci8q.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId:
        _googleServerClientId.isEmpty ? null : _googleServerClientId,
  );

  AuthUser? _currentUser;
  bool _isInitialized = false;

  AuthUser? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionRaw = prefs.getString(_sessionKey);
    if (sessionRaw != null && sessionRaw.isNotEmpty) {
      _currentUser = AuthUser.fromJson(
        jsonDecode(sessionRaw) as Map<String, dynamic>,
      );
    }

    final token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      try {
        await refreshCurrentUser(notify: false);
      } on AuthException {
        await _clearSession(notify: false);
      } catch (_) {
        await _clearSession(notify: false);
      }
    } else if (_currentUser != null) {
      await _clearSession(notify: false);
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> registerLocal({
    required String displayName,
    required String username,
    required String email,
    required String password,
  }) async {
    await initialize();

    try {
      final response = await ApiClient.instance.post(
        '/mobile/auth/register',
        requiresAuth: false,
        body: {
          'display_name': displayName.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': password,
        },
      );

      await _applyAuthResponse(response as Map<String, dynamic>);
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<void> loginLocal({
    required String identifier,
    required String password,
  }) async {
    await initialize();

    try {
      final response = await ApiClient.instance.post(
        '/mobile/auth/login',
        requiresAuth: false,
        body: {
          'identifier': identifier.trim(),
          'password': password,
        },
      );

      await _applyAuthResponse(response as Map<String, dynamic>);
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<void> signInWithGoogle() async {
    await initialize();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthException('Masuk dengan Google dibatalkan.');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('ID token Google tidak tersedia.');
      }

      final response = await ApiClient.instance.post(
        '/mobile/auth/google',
        requiresAuth: false,
        body: {
          'id_token': idToken,
          'email': account.email,
          'display_name': account.displayName ?? '',
        },
      );

      await _applyAuthResponse(response as Map<String, dynamic>);
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } on PlatformException catch (error) {
      throw AuthException(_mapGoogleError(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw const AuthException('Gagal masuk dengan Google.');
    }
  }

  Future<void> signInWithGoogleDemo() => signInWithGoogle();

  Future<void> refreshCurrentUser({bool notify = true}) async {
    try {
      final response = await ApiClient.instance.get('/mobile/me');
      final payload = response as Map<String, dynamic>;
      final user = AuthUser.fromJson(payload['user'] as Map<String, dynamic>);
      await _persistCurrentUser(user, notify: notify);
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<void> updateEmail(String email) async {
    await initialize();

    try {
      final response = await ApiClient.instance.put(
        '/mobile/me/email',
        body: {'email': email.trim()},
      );
      final payload = response as Map<String, dynamic>;
      final user = AuthUser.fromJson(payload['user'] as Map<String, dynamic>);
      await _persistCurrentUser(user);
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await initialize();

    try {
      await ApiClient.instance.put(
        '/mobile/me/password',
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // best effort
    }

    try {
      await ApiClient.instance.post('/mobile/auth/logout');
    } catch (_) {
      // best effort
    }

    await _clearSession();
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> payload) async {
    final token = (payload['token'] ?? '').toString();
    final userJson = payload['user'];
    if (token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const AuthException('Respons login dari server tidak valid.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await _persistCurrentUser(AuthUser.fromJson(userJson));
  }

  Future<void> _persistCurrentUser(
    AuthUser user, {
    bool notify = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    _currentUser = user;
    if (notify) {
      this.notifyListeners();
    }
  }

  Future<void> _clearSession({bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
    _currentUser = null;
    if (notify) {
      this.notifyListeners();
    }
  }

  String _mapGoogleError(PlatformException error) {
    switch (error.code) {
      case 'sign_in_canceled':
        return 'Masuk dengan Google dibatalkan.';
      case 'network_error':
        return 'Koneksi internet bermasalah.';
      case 'sign_in_failed':
        return 'Masuk dengan Google gagal.';
      default:
        final message = error.message?.trim() ?? '';
        if (message.isNotEmpty) {
          return message;
        }
        return 'Masuk dengan Google gagal.';
    }
  }
}