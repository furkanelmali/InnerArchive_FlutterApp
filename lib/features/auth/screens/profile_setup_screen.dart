import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime? _birthDate;

  void _submit() {
    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    
    if (username.isEmpty || name.isEmpty) return;
    
    ref.read(authProvider.notifier).completeSetup(
      username: username,
      fullName: name,
      birthDate: _birthDate,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_pin, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Tell us a bit about yourself',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _birthDate == null 
                      ? 'Select Date' 
                      : DateFormat.yMMMd().format(_birthDate!),
                  style: _birthDate == null 
                      ? theme.textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary)
                      : theme.textTheme.bodyLarge,
                ),
              ),
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 24),
              Text(
                authState.error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Complete Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
