import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/exam.dart';
import '../application/exams_controller.dart';

class ExamsListScreen extends ConsumerWidget {
  const ExamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(myExamsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exams')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myExamsProvider.future),
        child: examsAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myExamsProvider),
          ),
          data: (exams) {
            if (exams.isEmpty) {
              return const EmptyView(
                icon: Icons.quiz_outlined,
                title: 'No exams yet',
                subtitle: 'New exams from your teacher will show up here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: exams.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _ExamTile(exam: exams[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusPresentation(exam);
    return Card(
      child: ListTile(
        title: Text(exam.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          'Due ${DateFormat.yMMMd().add_jm().format(exam.deadline.toLocal())}',
        ),
        trailing: Chip(
          label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: color,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => context.push('/exams/${exam.id}'),
      ),
    );
  }

  (String, Color) _statusPresentation(Exam exam) {
    final attempt = exam.myAttempt;
    if (attempt == null) {
      return exam.canStartOrContinue ? ('Not Started', AppBrand.warning) : ('Closed', AppBrand.danger);
    }
    switch (attempt.status) {
      case AttemptStatus.graded:
        return ('Graded', AppBrand.success);
      case AttemptStatus.submitted:
        return ('Submitted', AppBrand.primary);
      case AttemptStatus.inProgress:
        return ('In Progress', AppBrand.secondary);
    }
  }
}
