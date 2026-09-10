import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/assignment.dart';
import '../../../repositories/assignment_repository.dart';
import '../application/assignments_controller.dart';
import '../application/submission_flow_controller.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  const AssignmentDetailScreen({super.key, required this.assignmentId});
  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(assignmentByIdProvider(assignmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment')),
      body: assignmentAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(assignmentByIdProvider(assignmentId)),
        ),
        data: (assignment) => _AssignmentBody(assignment: assignment),
      ),
    );
  }
}

class _AssignmentBody extends ConsumerWidget {
  const _AssignmentBody({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submission = assignment.mySubmission;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(assignment.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              assignment.isClosed ? Icons.lock_outline : Icons.schedule,
              size: 16,
              color: assignment.isClosed ? AppBrand.danger : AppBrand.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              assignment.isClosed
                  ? 'Closed'
                  : 'Due ${DateFormat.yMMMd().add_jm().format(assignment.deadline.toLocal())}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (assignment.description != null && assignment.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(assignment.description!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (submission != null)
          _SubmissionSummaryCard(submission: submission)
        else if (assignment.isClosed)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('The deadline for this assignment has passed. '
                  'Submissions are no longer accepted.'),
            ),
          )
        else
          _SubmissionFlowCard(assignmentId: assignment.id),
      ],
    );
  }
}

class _SubmissionSummaryCard extends ConsumerWidget {
  const _SubmissionSummaryCard({required this.submission});
  final AssignmentSubmission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGraded = submission.status == SubmissionStatus.graded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Submission', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<String>(
              future: ref
                  .read(assignmentRepositoryProvider)
                  .getSubmissionPhotoUrl(submission.photoStoragePath),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: snapshot.data!,
                    fit: BoxFit.cover,
                    height: 220,
                    width: double.infinity,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Submitted ${DateFormat.yMMMd().add_jm().format(submission.submittedAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (isGraded) ...[
              Row(
                children: [
                  const Icon(Icons.grade, color: AppBrand.success),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Grade: ${submission.grade?.toStringAsFixed(1)} / ${submission.maxGrade.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppBrand.success),
                  ),
                ],
              ),
              if (submission.teacherComment != null &&
                  submission.teacherComment!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Teacher Comment', style: Theme.of(context).textTheme.labelLarge),
                Text(submission.teacherComment!),
              ],
            ] else
              Row(
                children: [
                  const Icon(Icons.hourglass_empty, color: AppBrand.warning),
                  const SizedBox(width: AppSpacing.xs),
                  const Text('Waiting for teacher review'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionFlowCard extends ConsumerWidget {
  const _SubmissionFlowCard({required this.assignmentId});
  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(submissionFlowControllerProvider(assignmentId));
    final controller = ref.read(submissionFlowControllerProvider(assignmentId).notifier);

    ref.listen(submissionFlowControllerProvider(assignmentId), (prev, next) {
      if (next.step == SubmissionFlowStep.done) {
        ref.invalidate(assignmentByIdProvider(assignmentId));
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!.message)),
        );
      }
    });

    if (flowState.step == SubmissionFlowStep.done) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppBrand.success),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Submitted! Your teacher will review it soon.')),
            ],
          ),
        ),
      );
    }

    if (flowState.step == SubmissionFlowStep.previewing ||
        flowState.step == SubmissionFlowStep.uploading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Preview', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(flowState.photo!, height: 240, fit: BoxFit.cover),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: flowState.step == SubmissionFlowStep.uploading
                          ? null
                          : controller.retake,
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: flowState.step == SubmissionFlowStep.uploading
                          ? null
                          : controller.confirmAndSubmit,
                      child: flowState.step == SubmissionFlowStep.uploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Submit Your Homework', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text('Take a photo of your completed homework to submit it.'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take Photo'),
              onPressed: () => controller.capturePhoto(fromCamera: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from Gallery'),
              onPressed: () => controller.capturePhoto(fromCamera: false),
            ),
          ],
        ),
      ),
    );
  }
}
