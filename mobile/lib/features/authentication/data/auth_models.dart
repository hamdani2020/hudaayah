/// Profile returned by the backend `/me/` and `/auth/google/` responses.
class UserProfile {
  final int id;
  final String provider;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.provider,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        provider: json['provider'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

/// Token pair + profile returned on successful sign-in.
class AuthResult {
  final UserProfile user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: UserProfile.fromJson((json['user'] as Map).cast<String, dynamic>()),
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
