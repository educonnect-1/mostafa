import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/exam.dart';
import '../application/exams_controller.dart';

class ExamDetailScreen extends ConsumerWidget {
  const ExamDetailScreen({super.key, required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examAsync = ref.watch(examByIdProvider(examId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exam')),
      body: examAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(examByIdProvider(examId)),
        ),
        data: (exam) => _ExamBody(exam: exam),
      ),
    );
  }
}

class _ExamBody extends StatelessWidget {
  const _ExamBody({required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(exam.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: AppBrand.warning),
            const SizedBox(width: AppSpacing.xs),
            Text('Due ${DateFormat.yMMMd().add_jm().format(exam.deadline.toLocal())}'),
            const SizedBox(width: AppSpacing.md),
            const Icon(Icons.timer_outlined, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text('${exam.durationMinutes} min'),
          ],
        ),
        if (exam.description != null && exam.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(exam.description!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (exam.instructions != null && exam.instructions!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructions', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(exam.instructions!),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ActionArea(exam: exam),
      ],
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final attempt = exam.myAttempt;

    if (attempt == null) {
      if (!exam.canStartOrContinue) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('This exam is closed. The deadline has passed.'),
          ),
        );
      }
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Exam'),
        onPressed: () => context.push('/exams/${exam.id}/take', extra: exam),
      );
    }

    switch (attempt.status) {
      case AttemptStatus.inProgress:
        return ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Continue Exam'),
          onPressed: () => context.push('/exams/${exam.id}/take', extra: exam),
        );
      case AttemptStatus.submitted:
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty, color: AppBrand.warning),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Submitted. Waiting for teacher review.')),
              ],
            ),
          ),
        );
      case AttemptStatus.graded:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.grade, color: AppBrand.success),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Grade: ${attempt.score?.toStringAsFixed(1)} / ${attempt.maxScore?.toStringAsFixed(0) ?? '-'}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppBrand.success),
                    ),
                  ],
                ),
                if (attempt.teacherFeedback != null && attempt.teacherFeedback!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Teacher Feedback', style: Theme.of(context).textTheme.labelLarge),
                  Text(attempt.teacherFeedback!),
                ],
              ],
            ),
          ),
        );
    }
  }
}
