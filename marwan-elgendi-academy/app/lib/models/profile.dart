import 'package:equatable/equatable.dart';

enum UserRole { teacher, student }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.student,
  );
}

/// Mirrors `public.profiles`. Note: `parent_phone` and `phone` are only
/// ever populated when this row was fetched for the signed-in user's own
/// profile — group-mate lookups must go through
/// `ProfileRepository.getGroupMemberProfiles`, which never selects these
/// columns at all (see schema.sql §18 comments).
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    this.age,
    this.phone,
    this.parentPhone,
    this.avatarUrl,
    required this.online,
    this.lastSeenAt,
  });

  final String id;
  final UserRole role;
  final String fullName;
  final String email;
  final int? age;
  final String? phone;
  final String? parentPhone;
  final String? avatarUrl;
  final bool online;
  final DateTime? lastSeenAt;

  bool get isTeacher => role == UserRole.teacher;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: userRoleFromString(json['role'] as String),
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      age: json['age'] as int?,
      phone: json['phone'] as String?,
      parentPhone: json['parent_phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      online: (json['online'] as bool?) ?? false,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
    );
  }

  /// Lightweight variant returned by `get_group_member_profiles` RPC —
  /// intentionally has no email/phone/parent_phone fields to decode.
  factory Profile.fromGroupMemberJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: UserRole.student,
      fullName: json['full_name'] as String,
      email: '',
      avatarUrl: json['avatar_url'] as String?,
      online: (json['online'] as bool?) ?? false,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
    );
  }

  Profile copyWith({
    String? fullName,
    int? age,
    String? phone,
    String? avatarUrl,
    bool? online,
    DateTime? lastSeenAt,
  }) {
    return Profile(
      id: id,
      role: role,
      fullName: fullName ?? this.fullName,
      email: email,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      parentPhone: parentPhone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      online: online ?? this.online,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        fullName,
        email,
        age,
        phone,
        parentPhone,
        avatarUrl,
        online,
        lastSeenAt,
      ];
}
