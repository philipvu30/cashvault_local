import 'package:flutter/material.dart';

class OwnerPasswordSetupResult {
  const OwnerPasswordSetupResult({
    required this.password,
    required this.confirmPassword,
  });

  final String password;
  final String confirmPassword;
}

class OwnerPasswordSetupDialog extends StatefulWidget {
  const OwnerPasswordSetupDialog({super.key});

  @override
  State<OwnerPasswordSetupDialog> createState() => _OwnerPasswordSetupDialogState();
}

class _OwnerPasswordSetupDialogState extends State<OwnerPasswordSetupDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Owner Password'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () {
            if (_passwordController.text.isEmpty ||
                _confirmController.text.isEmpty ||
                _passwordController.text != _confirmController.text) {
              setState(() => _error = 'Password invalid or not matched.');
              return;
            }
            Navigator.of(context).pop(
              OwnerPasswordSetupResult(
                password: _passwordController.text,
                confirmPassword: _confirmController.text,
              ),
            );
          },
          child: const Text('Create Password'),
        ),
      ],
    );
  }
}
