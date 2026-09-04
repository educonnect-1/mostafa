import 'package:flutter/material.dart';
import '../solver/models/solution.dart';

class StepsView extends StatelessWidget {
  final Solution solution;

  const StepsView({super.key, required this.solution});

  @override
  Widget build(BuildContext context) {
    if (solution.steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Text('Mathematical transformations',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...solution.steps.asMap().entries.map(
              (entry) => _StepCard(
                index: entry.key + 1,
                step: entry.value,
              ),
            ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final TransformationStep step;

  const _StepCard({
    required this.index,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step $index',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _EquationBox(step.before),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  step.operation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_downward_rounded, size: 18),
            const SizedBox(height: 8),
            _EquationBox(step.after),
          ],
        ),
      ),
    );
  }
}

class _EquationBox extends StatelessWidget {
  final String text;

  const _EquationBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8ED)),
      ),
      child: SelectableText(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    );
  }
}
