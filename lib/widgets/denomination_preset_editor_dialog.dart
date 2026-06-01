import 'package:flutter/material.dart';

import '../models/denomination_preset_model.dart';
import '../services/money_parser_service.dart';

class DenominationPresetEditorResult {
  const DenominationPresetEditorResult({
    required this.entryType,
    required this.label,
    required this.amountCents,
    required this.sortOrder,
    required this.isActive,
  });

  final String entryType;
  final String label;
  final int amountCents;
  final int sortOrder;
  final bool isActive;
}

class DenominationPresetEditorDialog extends StatefulWidget {
  const DenominationPresetEditorDialog({
    super.key,
    required this.parser,
    this.initial,
    required this.defaultType,
  });

  final MoneyParserService parser;
  final DenominationPresetModel? initial;
  final String defaultType;

  @override
  State<DenominationPresetEditorDialog> createState() => _DenominationPresetEditorDialogState();
}

class _DenominationPresetEditorDialogState extends State<DenominationPresetEditorDialog> {
  late String _entryType;
  late TextEditingController _labelController;
  late TextEditingController _amountController;
  late TextEditingController _sortController;
  bool _isActive = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _entryType = initial?.entryType ?? widget.defaultType;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _amountController = TextEditingController(
      text: initial == null ? '' : _editableMoney(initial.amountCents),
    );
    _sortController = TextEditingController(text: (initial?.sortOrder ?? 0).toString());
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Label' : 'Edit Label'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _entryType,
              decoration: const InputDecoration(labelText: 'Entry Type'),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'cash', child: Text('cash')),
                DropdownMenuItem(value: 'coin', child: Text('coin')),
              ],
              onChanged: (value) => setState(() => _entryType = value ?? 'cash'),
            ),
            const SizedBox(height: 8),
            TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Label')),
            const SizedBox(height: 8),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount')),
            const SizedBox(height: 8),
            TextField(
              controller: _sortController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort Order'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value ?? true),
              title: const Text('Active'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final label = _labelController.text.trim();
            final amount = widget.parser.tryParseToCents(_amountController.text);
            final sort = int.tryParse(_sortController.text.trim());
            if (label.isEmpty || amount == null || amount < 0 || sort == null) {
              setState(() => _error = 'Invalid values.');
              return;
            }
            Navigator.pop(
              context,
              DenominationPresetEditorResult(
                entryType: _entryType,
                label: label,
                amountCents: amount,
                sortOrder: sort,
                isActive: _isActive,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _editableMoney(int cents) {
    final d = cents ~/ 100;
    final c = cents % 100;
    return '$d.${c.toString().padLeft(2, '0')}';
  }
}
