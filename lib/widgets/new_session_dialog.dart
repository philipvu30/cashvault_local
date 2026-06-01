import 'package:flutter/material.dart';

import '../services/money_parser_service.dart';

class NewSessionDialogResult {
  const NewSessionDialogResult({
    required this.sessionName,
    required this.businessDate,
    required this.startingBalanceCents,
  });

  final String sessionName;
  final String businessDate;
  final int startingBalanceCents;
}

class NewSessionDialog extends StatefulWidget {
  const NewSessionDialog({
    super.key,
    required this.parser,
    required this.defaultStartingBalanceCents,
  });

  final MoneyParserService parser;
  final int defaultStartingBalanceCents;

  @override
  State<NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends State<NewSessionDialog> {
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _balanceController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _nameController = TextEditingController(text: 'Business Day $date');
    _dateController = TextEditingController(text: date);
    _balanceController = TextEditingController(text: _editableMoney(widget.defaultStartingBalanceCents));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _balanceController.dispose();
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
            const SizedBox(height: 8),
            TextField(controller: _balanceController, decoration: const InputDecoration(labelText: 'Starting Balance')),
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
            final cents = widget.parser.tryParseToCents(_balanceController.text);
            if (name.isEmpty || date.isEmpty || cents == null || cents < 0) {
              setState(() => _error = 'Invalid values.');
              return;
            }
            Navigator.pop(
              context,
              NewSessionDialogResult(
                sessionName: name,
                businessDate: date,
                startingBalanceCents: cents,
              ),
            );
          },
          child: const Text('Create Session'),
        ),
      ],
    );
  }

  String _editableMoney(int cents) {
    final dollars = cents ~/ 100;
    final remains = cents % 100;
    return '$dollars.${remains.toString().padLeft(2, '0')}';
  }
}
