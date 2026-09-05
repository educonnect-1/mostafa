import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool sent = false;
  bool busy = false;

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      await AuthService().resetPassword(email.text.trim());
      setState(() => sent = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 16),
        FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Sending…' : 'Send reset email')),
        if (sent) const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('If the account exists, a reset email has been sent.'),
        ),
      ]),
    ),
  );
}
