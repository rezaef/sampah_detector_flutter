class AuthUser {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String role;
  final String provider;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    required this.provider,
  });

  bool get isGoogleAccount => provider == 'google';

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || displayName.trim().isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'displayName': displayName,
        'role': role,
        'provider': provider,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        role: json['role'] as String? ?? 'user',
        provider: json['provider'] as String? ?? 'local',
      );
}
