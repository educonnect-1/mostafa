import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  bool busy = false;
  String? error;

  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      await auth.signIn(email.text.trim(), password.text);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(shrinkWrap: true, children: [
          const Text('EduConnect', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Learn. Teach. Connect.'),
          const SizedBox(height: 28),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password')),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 18),
          FilledButton(onPressed: busy ? null : submit,
            child: Text(busy ? 'Signing in…' : 'Sign in')),
          TextButton(onPressed: () => context.go('/register'),
            child: const Text('Create account')),
          TextButton(onPressed: () => context.go('/forgot-password'),
            child: const Text('Forgot password?')),
        ]),
      ),
    ))),
  );
}
