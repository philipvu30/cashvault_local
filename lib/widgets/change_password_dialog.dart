import 'package:flutter/material.dart';

class ChangePasswordResult {
  const ChangePasswordResult({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Owner Password'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 8),
            TextField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 8),
            TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              ChangePasswordResult(
                currentPassword: _current.text,
                newPassword: _next.text,
                confirmPassword: _confirm.text,
              ),
            );
          },
          child: const Text('Save Password'),
        ),
      ],
    );
  }
}
