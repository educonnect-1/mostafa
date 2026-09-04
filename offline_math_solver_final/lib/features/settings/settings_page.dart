import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('MathSolve',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Local-first mathematics solving with image, voice and typed input.',
          ),
          const SizedBox(height: 22),
          const _SettingCard(
            icon: Icons.language_outlined,
            title: 'Solution language',
            value: 'English',
          ),
          const _SettingCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Appearance',
            value: 'Light mode',
          ),
          const _SettingCard(
            icon: Icons.cloud_off_outlined,
            title: 'Solver',
            value: 'Offline / no AI API',
          ),
          const _SettingCard(
            icon: Icons.photo_camera_outlined,
            title: 'Image input',
            value: 'Local OCR + editable review',
          ),
          const _SettingCard(
            icon: Icons.record_voice_over_outlined,
            title: 'Voice input',
            value: 'Device speech recognition',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current solving coverage',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const _Coverage('Arithmetic / expressions', true),
                  const _Coverage('Linear equations', true),
                  const _Coverage('Quadratic equations', true),
                  const _Coverage('2×2 linear systems', true),
                  const _Coverage('Linear inequalities', true),
                  const _Coverage('Derivatives', true),
                  const _Coverage('Generic handwriting recognition', false),
                  const _Coverage('Full symbolic CAS', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'OCR and device speech recognition can have platform limitations. Always review captured input before relying on a result.',
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _Coverage extends StatelessWidget {
  final String label;
  final bool supported;

  const _Coverage(this.label, this.supported);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            supported ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
