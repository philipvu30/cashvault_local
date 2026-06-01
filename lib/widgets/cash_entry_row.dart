import 'package:flutter/material.dart';

import '../models/cash_entry.dart';
import '../services/money_calculation_service.dart';

class CashEntryRow extends StatelessWidget {
  const CashEntryRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onDelete,
  });

  final CashEntryInput entry;
  final ValueChanged<CashEntryInput> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.label,
                    decoration: const InputDecoration(labelText: 'Label'),
                    onChanged: (value) =>
                        onChanged(entry.copyWith(label: value)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Delete Row',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: (entry.amountCents / 100.0).toStringAsFixed(
                      2,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      final cents = _safeParseCents(value);
                      onChanged(entry.copyWith(amountCents: cents));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.quantity.toString(),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 0;
                      onChanged(entry.copyWith(quantity: quantity));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: entry.comment ?? '',
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
              ),
              onChanged: (value) => onChanged(
                entry.copyWith(comment: value.isEmpty ? null : value),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Row Total: ${MoneyCalculationService.formatCents(entry.rowTotalCents)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _safeParseCents(String value) {
    try {
      return MoneyCalculationService.parseToCents(value);
    } catch (_) {
      return 0;
    }
  }
}
