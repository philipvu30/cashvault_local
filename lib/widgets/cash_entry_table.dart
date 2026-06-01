import 'package:flutter/material.dart';

import '../services/money_format_service.dart';
import '../services/money_parser_service.dart';
import '../state/cash_entries_state.dart';
import 'cash_entry_row.dart';

class CashEntryTable extends StatefulWidget {
  const CashEntryTable({
    super.key,
    required this.rows,
    required this.moneyFormatService,
    required this.moneyParserService,
    required this.onQuantityChanged,
    required this.onLabelChanged,
    required this.onAmountChanged,
    required this.onDeleteRow,
    required this.readOnly,
  });

  final List<CashEntryDraft> rows;
  final MoneyFormatService moneyFormatService;
  final MoneyParserService moneyParserService;
  final void Function(CashEntryDraft row, int value) onQuantityChanged;
  final void Function(CashEntryDraft row, String value) onLabelChanged;
  final void Function(CashEntryDraft row, int value) onAmountChanged;
  final void Function(CashEntryDraft row) onDeleteRow;
  final bool readOnly;

  @override
  State<CashEntryTable> createState() => _CashEntryTableState();
}

class _CashEntryTableState extends State<CashEntryTable> {
  final List<FocusNode> _qtyNodes = <FocusNode>[];

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(covariant CashEntryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      _syncNodes();
    }
  }

  @override
  void dispose() {
    for (final node in _qtyNodes) {
      node.dispose();
    }
    _qtyNodes.clear();
    super.dispose();
  }

  void _syncNodes() {
    final target = widget.rows.length;
    if (_qtyNodes.length < target) {
      final toAdd = target - _qtyNodes.length;
      for (var i = 0; i < toAdd; i++) {
        _qtyNodes.add(FocusNode());
      }
    } else if (_qtyNodes.length > target) {
      final extras = _qtyNodes.sublist(target);
      for (final node in extras) {
        node.dispose();
      }
      _qtyNodes.removeRange(target, _qtyNodes.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
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
          ],
        ),
        const SizedBox(height: 8),
        ...widget.rows.asMap().entries.map(
              (entry) => CashEntryRow(
                row: entry.value,
                moneyFormatService: widget.moneyFormatService,
                moneyParserService: widget.moneyParserService,
                onQuantityChanged: (value) => widget.onQuantityChanged(entry.value, value),
                onLabelChanged: (value) => widget.onLabelChanged(entry.value, value),
                onAmountChanged: (value) => widget.onAmountChanged(entry.value, value),
                onDelete: () => widget.onDeleteRow(entry.value),
                isReadOnly: widget.readOnly,
                qtyFocusNode: _qtyNodes[entry.key],
                nextQtyFocusNode: entry.key + 1 < _qtyNodes.length ? _qtyNodes[entry.key + 1] : null,
              ),
            ),
      ],
    );
  }
}
