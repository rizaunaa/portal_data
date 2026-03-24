class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.role,
    required this.photoUrl,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String username;
  final String role;
  final String photoUrl;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      role: map['role'] as String? ?? 'staff',
      photoUrl: map['photo_url'] as String? ?? '',
      settings: (map['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'role': role,
      'photo_url': photoUrl,
      'settings': settings,
    };
  }
}
