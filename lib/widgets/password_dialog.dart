import 'package:flutter/material.dart';

class PasswordDialog extends StatefulWidget {
  const PasswordDialog({
    super.key,
    this.title = 'Owner Password',
    this.confirmLabel = 'Confirm',
  });

  final String title;
  final String confirmLabel;

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Owner Password'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop<String?>(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<String>(_controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
