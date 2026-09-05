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
        const SizedBox(height: 16),
        Text('Mathematical transformations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...solution.steps.asMap().entries.map((e) => _StepCard(index: e.key + 1, step: e.value)),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final TransformationStep step;
  const _StepCard({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    final hasBoth = step.leftOperation != null || step.rightOperation != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step $index', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _MathLine(step.before),
            const SizedBox(height: 8),
            if (hasBoth)
              Row(
                children: [
                  Expanded(child: _OperationLine(step.leftOperation ?? step.operation)),
                  const SizedBox(width: 12),
                  Expanded(child: _OperationLine(step.rightOperation ?? step.operation)),
                ],
              )
            else
              _OperationLine(step.operation),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _MathLine(step.after),
          ],
        ),
      ),
    );
  }
}

class _OperationLine extends StatelessWidget {
  final String text;
  const _OperationLine(this.text);
  @override
  Widget build(BuildContext context) => Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w700));
}

class _MathLine extends StatelessWidget {
  final String text;
  const _MathLine(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: const Color(0xFFF3F5F8), borderRadius: BorderRadius.circular(12)),
    child: SelectableText(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w600)),
  );
}
