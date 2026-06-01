import 'package:flutter/material.dart';

class NewSessionDialogResult {
  const NewSessionDialogResult({
    required this.sessionName,
    required this.businessDate,
  });

  final String sessionName;
  final String businessDate;
}

class NewSessionDialog extends StatefulWidget {
  const NewSessionDialog({
    super.key,
  });

  @override
  State<NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends State<NewSessionDialog> {
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _nameController = TextEditingController(text: 'Business Day $date');
    _dateController = TextEditingController(text: date);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start New Session'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Session Name')),
            const SizedBox(height: 8),
            TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Business Date (YYYY-MM-DD)')),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final date = _dateController.text.trim();
            if (name.isEmpty || date.isEmpty) {
              setState(() => _error = 'Invalid values.');
              return;
            }
            Navigator.pop(
              context,
              NewSessionDialogResult(
                sessionName: name,
                businessDate: date,
              ),
            );
          },
          child: const Text('Create Session'),
        ),
      ],
    );
  }
}
