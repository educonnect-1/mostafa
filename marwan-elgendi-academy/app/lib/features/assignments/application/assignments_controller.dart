import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/assignment.dart';
import '../../../repositories/assignment_repository.dart';

final myAssignmentsProvider = FutureProvider.autoDispose<List<Assignment>>((ref) {
  return ref.read(assignmentRepositoryProvider).getMyAssignments();
});

final assignmentByIdProvider =
    FutureProvider.autoDispose.family<Assignment, String>((ref, id) {
  return ref.read(assignmentRepositoryProvider).getAssignmentById(id);
});
