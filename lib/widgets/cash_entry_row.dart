import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/cash_entry.dart';
import '../services/money_calculation_service.dart';

class CashEntryRow extends StatefulWidget {
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
  State<CashEntryRow> createState() => _CashEntryRowState();
}

class _CashEntryRowState extends State<CashEntryRow> {
  late final TextEditingController _labelController;
  late final TextEditingController _amountController;
  late final TextEditingController _quantityController;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.entry.label);
    _amountController = TextEditingController(
      text: MoneyCalculationService.toDecimalString(widget.entry.amountCents),
    );
    _quantityController = TextEditingController(
      text: widget.entry.quantity.toString(),
    );
    _commentController = TextEditingController(text: widget.entry.comment ?? '');
  }

  @override
  void didUpdateWidget(covariant CashEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_labelController, widget.entry.label);
    _syncController(
      _amountController,
      MoneyCalculationService.toDecimalString(widget.entry.amountCents),
    );
    _syncController(_quantityController, widget.entry.quantity.toString());
    _syncController(_commentController, widget.entry.comment ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          _EntryCell(
            flex: 3,
            child: _buildTextField(
              controller: _labelController,
              onChanged: (value) => widget.onChanged(
                widget.entry.copyWith(label: value),
              ),
            ),
          ),
          _EntryCell(
            flex: 2,
            child: _buildTextField(
              controller: _amountController,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => widget.onChanged(
                widget.entry.copyWith(amountCents: _parseAmount(value)),
              ),
            ),
          ),
          _EntryCell(
            flex: 2,
            child: _buildTextField(
              controller: _quantityController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (value) => widget.onChanged(
                widget.entry.copyWith(quantity: int.tryParse(value) ?? 0),
              ),
            ),
          ),
          _EntryCell(
            flex: 2,
            child: Center(
              child: Text(
                MoneyCalculationService.formatCents(widget.entry.rowTotalCents),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _EntryCell(
            flex: 3,
            child: _buildTextField(
              controller: _commentController,
              onChanged: (value) => widget.onChanged(
                widget.entry.copyWith(
                  comment: value.trim().isEmpty ? null : value,
                  clearComment: value.trim().isEmpty,
                ),
              ),
            ),
          ),
          _EntryCell(
            flex: 1,
            child: Center(
              child: IconButton(
                tooltip: 'Delete Row',
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.left,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textAlign: textAlign,
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: const TextStyle(fontSize: 15),
      maxLines: 1,
    );
  }

  int _parseAmount(String value) {
    try {
      return MoneyCalculationService.parseToCents(value);
    } catch (_) {
      return 0;
    }
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }
}

class _EntryCell extends StatelessWidget {
  const _EntryCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    return Expanded(
      flex: flex,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: borderColor),
          ),
        ),
        child: child,
      ),
    );
  }
}
