class AuthUser {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String role;
  final String provider;
  final int pointsBalance;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    required this.provider,
    this.pointsBalance = 0,
  });

  bool get isGoogleAccount => provider == 'google';

  String get initials {
    final clean = displayName.trim();
    if (clean.isEmpty) {
      return 'U';
    }
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AuthUser copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? role,
    String? provider,
    int? pointsBalance,
  }) {
    return AuthUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      provider: provider ?? this.provider,
      pointsBalance: pointsBalance ?? this.pointsBalance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'display_name': displayName,
        'role': role,
        'provider': provider,
        'points_balance': pointsBalance,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] ?? '').toString(),
        username: (json['username'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        displayName: (json['display_name'] ?? json['displayName'] ?? json['name'] ?? '')
            .toString(),
        role: (json['role'] ?? 'user').toString(),
        provider: (json['provider'] ?? 'local').toString(),
        pointsBalance: int.tryParse(
              (json['points_balance'] ?? json['pointsBalance'] ?? 0).toString(),
            ) ??
            0,
      );
}