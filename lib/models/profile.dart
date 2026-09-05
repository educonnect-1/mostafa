enum UserRole { student, teacher }

class Profile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final UserRole role;
  final String bio;

  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.bio = '',
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as String,
    fullName: map['full_name'] as String? ?? '',
    avatarUrl: map['avatar_url'] as String?,
    role: (map['role'] as String? ?? 'student') == 'teacher'
        ? UserRole.teacher
        : UserRole.student,
    bio: map['bio'] as String? ?? '',
  );
}
