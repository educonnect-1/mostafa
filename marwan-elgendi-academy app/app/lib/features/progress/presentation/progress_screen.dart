import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/progress_summary.dart';
import '../../../repositories/progress_repository.dart';

final myProgressProvider = FutureProvider.autoDispose<ProgressSummary>((ref) {
  return ref.read(progressRepositoryProvider).getMyProgress();
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(myProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myProgressProvider.future),
        child: progressAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myProgressProvider),
          ),
          data: (progress) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ProgressCard(
                title: 'Assignments',
                icon: Icons.assignment_outlined,
                completed: progress.submittedAssignments,
                total: progress.totalAssignments,
                ratio: progress.assignmentCompletionRatio,
                averagePercent: progress.averageAssignmentPercent,
                gradedCount: progress.gradedAssignments,
              ),
              const SizedBox(height: AppSpacing.md),
              _ProgressCard(
                title: 'Exams',
                icon: Icons.quiz_outlined,
                completed: progress.submittedExams,
                total: progress.totalExams,
                ratio: progress.examCompletionRatio,
                averagePercent: progress.averageExamPercent,
                gradedCount: progress.gradedExams,
              ),
              const SizedBox(height: AppSpacing.md),
              _AttendanceCard(percent: progress.attendancePercent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.icon,
    required this.completed,
    required this.total,
    required this.ratio,
    required this.averagePercent,
    required this.gradedCount,
  });

  final String title;
  final IconData icon;
  final int completed;
  final int total;
  final double ratio;
  final double? averagePercent;
  final int gradedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppBrand.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: total == 0 ? 0 : ratio),
            const SizedBox(height: AppSpacing.xs),
            Text('$completed of $total completed · $gradedCount graded'),
            if (averagePercent != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Average: ${averagePercent!.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppBrand.success,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.percent});
  final double? percent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available_outlined, color: AppBrand.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Attendance', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (percent == null)
              const Text('No attendance records yet.')
            else ...[
              LinearProgressIndicator(value: percent! / 100),
              const SizedBox(height: AppSpacing.xs),
              Text('${percent!.toStringAsFixed(0)}% present/late'),
            ],
          ],
        ),
      ),
    );
  }
}
