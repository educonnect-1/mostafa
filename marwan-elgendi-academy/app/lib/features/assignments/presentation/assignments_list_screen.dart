import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/assignment.dart';
import '../application/assignments_controller.dart';

class AssignmentsListScreen extends ConsumerWidget {
  const AssignmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myAssignmentsProvider.future),
        child: assignmentsAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myAssignmentsProvider),
          ),
          data: (assignments) {
            if (assignments.isEmpty) {
              return const EmptyView(
                icon: Icons.assignment_outlined,
                title: 'No assignments yet',
                subtitle: 'New assignments from your teacher will show up here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: assignments.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _AssignmentTile(assignment: assignments[i]),
            );
          },
        ),
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusPresentation(assignment.effectiveStatus);
    return Card(
      child: ListTile(
        title: Text(assignment.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          'Due ${DateFormat.yMMMd().add_jm().format(assignment.deadline.toLocal())}',
        ),
        trailing: Chip(
          label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: color,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => context.push('/assignments/${assignment.id}'),
      ),
    );
  }

  (String, Color) _statusPresentation(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.graded:
        return ('Graded', AppBrand.success);
      case SubmissionStatus.submitted:
        return ('Submitted', AppBrand.primary);
      case SubmissionStatus.closed:
        return ('Closed', AppBrand.danger);
      case SubmissionStatus.notSubmitted:
        return ('Not Submitted', AppBrand.warning);
    }
  }
}
