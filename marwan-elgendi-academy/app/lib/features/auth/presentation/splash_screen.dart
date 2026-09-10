import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shown only for the brief moment while GoRouter's redirect resolves
/// the initial auth state (spec §33 — never leave a blank screen).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 72, color: AppBrand.primary),
            SizedBox(height: AppSpacing.md),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
