import 'package:equatable/equatable.dart';

enum SearchResultType { message, resource, announcement, assignment, exam }

class SearchResultItem extends Equatable {
  const SearchResultItem({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.groupId,
  });

  final SearchResultType type;
  final String id;
  final String title;
  final String? subtitle;

  /// Only set for chat message results — needed to open the right group.
  final String? groupId;

  @override
  List<Object?> get props => [type, id, title, subtitle, groupId];
}
