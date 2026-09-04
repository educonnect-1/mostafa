import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';

class MathSolveApp extends StatelessWidget {
  const MathSolveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathSolve',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}
