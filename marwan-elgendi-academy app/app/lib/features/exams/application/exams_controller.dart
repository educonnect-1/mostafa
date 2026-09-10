import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exam.dart';
import '../../../repositories/exam_repository.dart';

final myExamsProvider = FutureProvider.autoDispose<List<Exam>>((ref) {
  return ref.read(examRepositoryProvider).getMyExams();
});

final examByIdProvider = FutureProvider.autoDispose.family<Exam, String>((ref, id) {
  return ref.read(examRepositoryProvider).getExamById(id);
});
