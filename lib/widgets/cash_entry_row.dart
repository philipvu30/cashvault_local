import 'package:flutter/material.dart';

import '../services/money_format_service.dart';
import '../services/money_parser_service.dart';
import '../state/cash_entries_state.dart';

class CashEntryRow extends StatelessWidget {
  const CashEntryRow({
    super.key,
    required this.row,
    required this.moneyFormatService,
    required this.moneyParserService,
    required this.onQuantityChanged,
    required this.onLabelChanged,
    required this.onAmountChanged,
    required this.onDelete,
    required this.isReadOnly,
  });

  final CashEntryDraft row;
  final MoneyFormatService moneyFormatService;
  final MoneyParserService moneyParserService;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback? onDelete;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: row.isCustom
                ? TextFormField(
                    initialValue: row.label,
                    enabled: !isReadOnly,
                    decoration: const InputDecoration(labelText: 'Label'),
                    onChanged: onLabelChanged,
                  )
                : Text(row.label),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: row.isCustom
                ? TextFormField(
                    initialValue: _centsToEditableText(row.amountCents),
                    enabled: !isReadOnly,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    onChanged: (value) {
                      final cents = moneyParserService.tryParseToCents(value);
                      if (cents != null) onAmountChanged(cents);
                    },
                  )
                : Text(moneyFormatService.formatCents(row.amountCents)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: row.quantity == 0 ? '' : row.quantity.toString(),
              enabled: !isReadOnly,
              decoration: const InputDecoration(labelText: 'Qty'),
              keyboardType: TextInputType.number,
              onChanged: (value) => onQuantityChanged(int.tryParse(value) ?? 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              moneyFormatService.formatCents(row.rowTotalCents),
              textAlign: TextAlign.right,
            ),
          ),
          if (row.isCustom) ...<Widget>[
            const SizedBox(width: 8),
            IconButton(
              onPressed: isReadOnly ? null : onDelete,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  String _centsToEditableText(int cents) {
    final dollars = cents ~/ 100;
    final remainder = cents % 100;
    return '$dollars.${remainder.toString().padLeft(2, '0')}';
  }
}
