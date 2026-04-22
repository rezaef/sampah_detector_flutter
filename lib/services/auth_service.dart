import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

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
  static const _usersKey = 'auth.local_users';
  static const _googleDemoEmail = 'google.user@sampahdetector.app';
  static const _googleDemoUsername = 'googleuser';

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
    _isInitialized = true;
  }

  Future<void> registerLocal({
    required String displayName,
    required String username,
    required String email,
    required String password,
  }) async {
    await initialize();

    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();

    if (displayName.trim().isEmpty) {
      throw const AuthException('Nama lengkap wajib diisi.');
    }
    if (normalizedUsername.isEmpty || normalizedUsername.length < 4) {
      throw const AuthException('Username minimal 4 karakter.');
    }
    if (!_isValidEmail(normalizedEmail)) {
      throw const AuthException('Format email belum valid.');
    }
    if (password.length < 6) {
      throw const AuthException('Password minimal 6 karakter.');
    }

    final users = await _loadStoredUsers();
    final usernameUsed = users.any(
      (user) => (user['username'] as String).toLowerCase() == normalizedUsername,
    );
    if (usernameUsed) {
      throw const AuthException('Username sudah digunakan.');
    }

    final emailUsed = users.any(
      (user) => (user['email'] as String).toLowerCase() == normalizedEmail,
    );
    if (emailUsed) {
      throw const AuthException('Email sudah digunakan.');
    }

    final newUser = {
      'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
      'displayName': displayName.trim(),
      'username': normalizedUsername,
      'email': normalizedEmail,
      'role': 'user',
      'provider': 'local',
      'password': password,
    };

    users.insert(0, newUser);
    await _saveStoredUsers(users);
    await _setCurrentUser(AuthUser.fromJson(newUser));
  }

  Future<void> loginLocal({
    required String identifier,
    required String password,
  }) async {
    await initialize();

    if (identifier.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Username/email dan password wajib diisi.');
    }

    final normalizedIdentifier = identifier.trim().toLowerCase();
    final users = await _loadStoredUsers();

    Map<String, dynamic>? matchedUser;
    for (final user in users) {
      final username = (user['username'] as String).toLowerCase();
      final email = (user['email'] as String).toLowerCase();
      if (username == normalizedIdentifier || email == normalizedIdentifier) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser == null) {
      throw const AuthException('Akun tidak ditemukan.');
    }
    if ((matchedUser['password'] as String?) != password) {
      throw const AuthException('Password salah.');
    }

    await _setCurrentUser(AuthUser.fromJson(matchedUser));
  }

  Future<void> signInWithGoogleDemo() async {
    await initialize();

    final users = await _loadStoredUsers();
    Map<String, dynamic>? googleUser;
    for (final user in users) {
      if ((user['email'] as String).toLowerCase() == _googleDemoEmail) {
        googleUser = user;
        break;
      }
    }

    googleUser ??= {
      'id': 'google_demo_user',
      'displayName': 'Pengguna Google',
      'username': _googleDemoUsername,
      'email': _googleDemoEmail,
      'role': 'user',
      'provider': 'google',
      'password': '',
    };

    if (!users.any((user) => user['id'] == googleUser!['id'])) {
      users.insert(0, googleUser);
      await _saveStoredUsers(users);
    }

    await _setCurrentUser(AuthUser.fromJson(googleUser));
  }

  Future<void> updateEmail(String email) async {
    await initialize();

    final user = _currentUser;
    if (user == null) {
      throw const AuthException('Sesi akun tidak tersedia.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail)) {
      throw const AuthException('Format email belum valid.');
    }

    final users = await _loadStoredUsers();
    final emailUsed = users.any(
      (item) =>
          (item['id'] as String) != user.id &&
          (item['email'] as String).toLowerCase() == normalizedEmail,
    );
    if (emailUsed) {
      throw const AuthException('Email sudah digunakan.');
    }

    final updatedUsers = users.map((item) {
      if (item['id'] != user.id) {
        return item;
      }
      return {
        ...item,
        'email': normalizedEmail,
      };
    }).toList();

    await _saveStoredUsers(updatedUsers);
    await _setCurrentUser(
      AuthUser(
        id: user.id,
        username: user.username,
        email: normalizedEmail,
        displayName: user.displayName,
        role: user.role,
        provider: user.provider,
      ),
    );
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await initialize();

    final user = _currentUser;
    if (user == null) {
      throw const AuthException('Sesi akun tidak tersedia.');
    }
    if (newPassword.length < 6) {
      throw const AuthException('Password minimal 6 karakter.');
    }

    final users = await _loadStoredUsers();
    final index = users.indexWhere((item) => item['id'] == user.id);
    if (index < 0) {
      throw const AuthException('Data akun tidak ditemukan.');
    }

    final storedPassword = (users[index]['password'] as String?) ?? '';
    if (storedPassword.isNotEmpty && storedPassword != currentPassword) {
      throw const AuthException('Kata sandi saat ini tidak sesuai.');
    }

    users[index] = {
      ...users[index],
      'password': newPassword,
    };

    await _saveStoredUsers(users);
    await _setCurrentUser(user);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUser = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _loadStoredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _saveStoredUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<void> _setCurrentUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    _currentUser = user;
    notifyListeners();
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }
}
