import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/group.dart';
import '../../../models/profile.dart';
import '../../../repositories/group_repository.dart';

final myGroupsProvider = FutureProvider.autoDispose<List<Group>>((ref) {
  return ref.read(groupRepositoryProvider).getMyGroups();
});

final groupByIdProvider =
    FutureProvider.autoDispose.family<Group, String>((ref, groupId) {
  return ref.read(groupRepositoryProvider).getGroupById(groupId);
});

final groupMembersProvider =
    FutureProvider.autoDispose.family<List<Profile>, String>((ref, groupId) {
  return ref.read(groupRepositoryProvider).getGroupMembers(groupId);
});
