import 'package:flutter/material.dart';

import '../services/money_parser_service.dart';

class MoneyInputField extends StatelessWidget {
  const MoneyInputField({
    super.key,
    required this.controller,
    required this.parser,
    this.readOnly = false,
    this.labelText,
    this.onChangedCents,
  });

  final TextEditingController controller;
  final MoneyParserService parser;
  final bool readOnly;
  final String? labelText;
  final ValueChanged<int?>? onChangedCents;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: labelText,
        prefixText: '\$',
      ),
      onChanged: (value) => onChangedCents?.call(parser.tryParseToCents(value)),
    );
  }
}
