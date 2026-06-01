import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/money_format_service.dart';
import '../services/money_parser_service.dart';
import '../state/cash_entries_state.dart';

class CashEntryRow extends StatefulWidget {
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
    required this.qtyFocusNode,
    required this.nextQtyFocusNode,
  });

  final CashEntryDraft row;
  final MoneyFormatService moneyFormatService;
  final MoneyParserService moneyParserService;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback? onDelete;
  final bool isReadOnly;
  final FocusNode qtyFocusNode;
  final FocusNode? nextQtyFocusNode;

  @override
  State<CashEntryRow> createState() => _CashEntryRowState();
}

class _CashEntryRowState extends State<CashEntryRow> {
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: _qtyText(widget.row.quantity));
  }

  @override
  void didUpdateWidget(covariant CashEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desired = _qtyText(widget.row.quantity);
    if (_qtyController.text != desired) {
      _qtyController.value = TextEditingValue(
        text: desired,
        selection: TextSelection.collapsed(offset: desired.length),
      );
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: widget.row.isCustom
                ? TextFormField(
                    initialValue: widget.row.label,
                    enabled: !widget.isReadOnly,
                    decoration: const InputDecoration(labelText: 'Label'),
                    onChanged: widget.onLabelChanged,
                  )
                : Text(widget.row.label),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: widget.row.isCustom
                ? TextFormField(
                    initialValue: _centsToEditableText(widget.row.amountCents),
                    enabled: !widget.isReadOnly,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    onChanged: (value) {
                      final cents = widget.moneyParserService.tryParseToCents(value);
                      if (cents != null) widget.onAmountChanged(cents);
                    },
                  )
                : Text(widget.moneyFormatService.formatCents(widget.row.amountCents)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _qtyController,
              focusNode: widget.qtyFocusNode,
              enabled: !widget.isReadOnly,
              decoration: const InputDecoration(labelText: 'Qty'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => widget.onQuantityChanged(int.tryParse(value) ?? 0),
              onFieldSubmitted: (_) {
                final next = widget.nextQtyFocusNode;
                if (next != null) {
                  FocusScope.of(context).requestFocus(next);
                } else {
                  widget.qtyFocusNode.unfocus();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              widget.moneyFormatService.formatCents(widget.row.rowTotalCents),
              textAlign: TextAlign.right,
            ),
          ),
          if (widget.row.isCustom) ...<Widget>[
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.isReadOnly ? null : widget.onDelete,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  String _qtyText(int quantity) {
    return quantity == 0 ? '' : quantity.toString();
  }

  String _centsToEditableText(int cents) {
    final dollars = cents ~/ 100;
    final remainder = cents % 100;
    return '$dollars.${remainder.toString().padLeft(2, '0')}';
  }
}
