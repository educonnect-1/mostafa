import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/profile.dart';
import '../../../repositories/profile_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_edit_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) => _ProfileForm(profile: profile),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  File? _newAvatar;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _ageController = TextEditingController(text: widget.profile.age?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) setState(() => _newAvatar = File(picked.path));
  }

  Future<void> _save() async {
    final ok = await ref.read(profileEditControllerProvider.notifier).save(
          fullName: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          newAvatar: _newAvatar,
        );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(myProfileProvider);
      setState(() => _newAvatar = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } else {
      final error = ref.read(profileEditControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.message ?? 'Could not update profile.')),
      );
      ref.read(profileEditControllerProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(profileEditControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: _newAvatar != null
                    ? FileImage(_newAvatar!) as ImageProvider
                    : (widget.profile.avatarUrl != null
                        ? NetworkImage(widget.profile.avatarUrl!) as ImageProvider
                        : null),
                child: _newAvatar == null && widget.profile.avatarUrl == null
                    ? Text(
                        widget.profile.fullName.isNotEmpty
                            ? widget.profile.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppBrand.primary,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    onPressed: _pickAvatar,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: TextEditingController(text: widget.profile.email),
          enabled: false,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Age'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: editState.saving ? null : _save,
          child: editState.saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
