import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.studentId,
    required this.fullName,
    this.avatarUrl,
    this.averageGrade,
  });

  final String studentId;
  final String fullName;
  final String? avatarUrl;
  final double? averageGrade;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      studentId: json['student_id'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      averageGrade: (json['average_grade'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [studentId, fullName, avatarUrl, averageGrade];
}
