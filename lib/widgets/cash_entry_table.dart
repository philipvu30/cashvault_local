import 'package:flutter/material.dart';

import '../services/money_format_service.dart';
import '../services/money_parser_service.dart';
import '../state/cash_entries_state.dart';
import 'cash_entry_row.dart';

class CashEntryTable extends StatelessWidget {
  const CashEntryTable({
    super.key,
    required this.rows,
    required this.moneyFormatService,
    required this.moneyParserService,
    required this.onQuantityChanged,
    required this.onCommentChanged,
    required this.onLabelChanged,
    required this.onAmountChanged,
    required this.onDeleteRow,
    required this.readOnly,
  });

  final List<CashEntryDraft> rows;
  final MoneyFormatService moneyFormatService;
  final MoneyParserService moneyParserService;
  final void Function(CashEntryDraft row, int value) onQuantityChanged;
  final void Function(CashEntryDraft row, String value) onCommentChanged;
  final void Function(CashEntryDraft row, String value) onLabelChanged;
  final void Function(CashEntryDraft row, int value) onAmountChanged;
  final void Function(CashEntryDraft row) onDeleteRow;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Row(
          children: <Widget>[
            Expanded(flex: 3, child: Text('Label', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(flex: 3, child: Text('Comment', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) => CashEntryRow(
            row: row,
            moneyFormatService: moneyFormatService,
            moneyParserService: moneyParserService,
            onQuantityChanged: (value) => onQuantityChanged(row, value),
            onCommentChanged: (value) => onCommentChanged(row, value),
            onLabelChanged: (value) => onLabelChanged(row, value),
            onAmountChanged: (value) => onAmountChanged(row, value),
            onDelete: () => onDeleteRow(row),
            isReadOnly: readOnly,
          ),
        ),
      ],
    );
  }
}
