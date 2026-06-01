import 'package:flutter/material.dart';

import '../models/denomination_preset_model.dart';

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
    this.initial,
    required this.defaultType,
  });

  final DenominationPresetModel? initial;
  final String defaultType;

  @override
  State<DenominationPresetEditorDialog> createState() => _DenominationPresetEditorDialogState();
}

class _DenominationPresetEditorDialogState extends State<DenominationPresetEditorDialog> {
  late String _entryType;
  late TextEditingController _labelController;
  late TextEditingController _amountCentsController;
  late TextEditingController _sortController;
  bool _isActive = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _entryType = initial?.entryType ?? widget.defaultType;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _amountCentsController = TextEditingController(text: (initial?.amountCents ?? 0).toString());
    _sortController = TextEditingController(text: (initial?.sortOrder ?? 0).toString());
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountCentsController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Label' : 'Edit Label'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Type'),
            Row(
              children: <Widget>[
                Expanded(
                  child: RadioListTile<String>(
                    value: 'cash',
                    groupValue: _entryType,
                    onChanged: (value) => setState(() => _entryType = value ?? 'cash'),
                    title: const Text('Cash'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'coin',
                    groupValue: _entryType,
                    onChanged: (value) => setState(() => _entryType = value ?? 'coin'),
                    title: const Text('Coin'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCentsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (Cents)',
                hintText: 'Example: 10000',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Digits only. Stored as integer cents.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
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
            final amountRaw = _amountCentsController.text.trim();
            final sortRaw = _sortController.text.trim();

            if (label.isEmpty) {
              setState(() => _error = 'Label cannot be empty.');
              return;
            }
            if (!RegExp(r'^\d+$').hasMatch(amountRaw)) {
              setState(() => _error = 'Amount must be digits only (integer cents).');
              return;
            }
            if (!RegExp(r'^-?\d+$').hasMatch(sortRaw)) {
              setState(() => _error = 'Sort order must be an integer.');
              return;
            }

            final amountCents = int.tryParse(amountRaw);
            final sortOrder = int.tryParse(sortRaw);
            if (amountCents == null || amountCents < 0 || sortOrder == null) {
              setState(() => _error = 'Invalid values.');
              return;
            }

            Navigator.pop(
              context,
              DenominationPresetEditorResult(
                entryType: _entryType,
                label: label,
                amountCents: amountCents,
                sortOrder: sortOrder,
                isActive: _isActive,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
