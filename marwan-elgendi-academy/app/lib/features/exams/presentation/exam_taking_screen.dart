import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/exam.dart';
import '../application/exam_taking_controller.dart';

class ExamTakingScreen extends ConsumerWidget {
  const ExamTakingScreen({super.key, required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examTakingControllerProvider(exam));
    final controller = ref.read(examTakingControllerProvider(exam).notifier);

    ref.listen(examTakingControllerProvider(exam), (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!.message)),
        );
        controller.clearError();
      }
      if (next.submitted && prev?.submitted == false) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam submitted!')),
        );
      }
    });

    return PopScope(
      canPop: state.submitted || state.questions.isEmpty,
      child: Scaffold(
        appBar: AppBar(
          title: Text(exam.title),
          actions: [
            if (state.remaining != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  child: Text(
                    _formatDuration(state.remaining!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: state.remaining!.inMinutes < 5
                              ? AppBrand.danger
                              : null,
                        ),
                  ),
                ),
              ),
          ],
        ),
        body: state.loading
            ? const LoadingView()
            : state.questions.isEmpty
                ? const EmptyView(
                    icon: Icons.error_outline,
                    title: 'No questions found for this exam',
                  )
                : Column(
                    children: [
                      _ProgressBar(state: state),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _QuestionCard(
                            key: ValueKey(state.currentQuestion!.id),
                            question: state.currentQuestion!,
                            answer: state.answers[state.currentQuestion!.id],
                            saving: state.savingQuestionId == state.currentQuestion!.id,
                            onChanged: (data) =>
                                controller.answer(state.currentQuestion!.id, data),
                          ),
                        ),
                      ),
                      _NavigationBar(exam: exam, state: state, controller: controller),
                    ],
                  ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state});
  final ExamTakingState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${state.currentIndex + 1} of ${state.questions.length} '
            '· ${state.answeredCount} answered',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (state.currentIndex + 1) / state.questions.length,
          ),
        ],
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.exam,
    required this.state,
    required this.controller,
  });

  final Exam exam;
  final ExamTakingState state;
  final ExamTakingController controller;

  @override
  Widget build(BuildContext context) {
    final isLast = state.currentIndex == state.questions.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.currentIndex > 0 ? controller.previous : null,
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: isLast
                  ? ElevatedButton(
                      onPressed: state.submitting ? null : () => _confirmSubmit(context, controller),
                      child: state.submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Exam'),
                    )
                  : ElevatedButton(
                      onPressed: controller.next,
                      child: const Text('Next'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSubmit(BuildContext context, ExamTakingController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: const Text(
          'Once submitted, you cannot change your answers. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.submit();
    }
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.answer,
    required this.saving,
    required this.onChanged,
  });

  final ExamQuestion question;
  final Map<String, dynamic>? answer;
  final bool saving;
  final ValueChanged<Map<String, dynamic>> onChanged;

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
                Expanded(
                  child: Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (saving)
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${question.points.toStringAsFixed(question.points % 1 == 0 ? 0 : 1)} points',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (question.imageUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(question.imageUrl!, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildAnswerInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(BuildContext context) {
    switch (question.type) {
      case QuestionType.mcq:
        final options = question.options ?? const [];
        final selected = answer?['selected'] as String?;
        return Column(
          children: options.map((opt) {
            final id = opt['id'] as String;
            final text = opt['text'] as String;
            return RadioListTile<String>(
              value: id,
              groupValue: selected,
              title: Text(text),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => onChanged({'selected': v}),
            );
          }).toList(),
        );

      case QuestionType.trueFalse:
        final selected = answer?['value'] as bool?;
        return Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                value: true,
                groupValue: selected,
                title: const Text('True'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => onChanged({'value': v}),
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                value: false,
                groupValue: selected,
                title: const Text('False'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => onChanged({'value': v}),
              ),
            ),
          ],
        );

      case QuestionType.shortAnswer:
        return TextFormField(
          initialValue: answer?['text'] as String? ?? '',
          decoration: const InputDecoration(
            hintText: 'Your answer',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => onChanged({'text': v}),
        );

      case QuestionType.longAnswer:
        return TextFormField(
          initialValue: answer?['text'] as String? ?? '',
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Write your answer here...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => onChanged({'text': v}),
        );

      case QuestionType.numerical:
        return TextFormField(
          initialValue: answer?['value']?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: const InputDecoration(
            hintText: 'Numeric answer',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            onChanged({'value': parsed, 'raw': v});
          },
        );
    }
  }
}
