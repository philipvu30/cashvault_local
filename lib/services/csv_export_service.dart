import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../models/cash_entry.dart';
import 'money_calculation_service.dart';

class CsvExportService {
  Future<String?> export({
    required int startingBalanceCents,
    required List<CashEntryInput> cashRows,
    required List<CashEntryInput> coinRows,
    required int totalCashNotesCents,
    required int totalCoinsCents,
    required int finalTotalCents,
  }) async {
    final timestamp = DateTime.now();
    final suggestedName =
        'cashvault_${DateFormat('yyyyMMdd_HHmmss').format(timestamp)}.csv';

    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export CSV',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );

    if (selectedPath == null) {
      return null;
    }

    final normalizedPath = _normalizeCsvFilename(selectedPath);
    final csv = buildCsvContent(
      timestamp: timestamp,
      startingBalanceCents: startingBalanceCents,
      cashRows: cashRows,
      coinRows: coinRows,
      totalCashNotesCents: totalCashNotesCents,
      totalCoinsCents: totalCoinsCents,
      finalTotalCents: finalTotalCents,
    );

    final output = File(normalizedPath);
    await output.writeAsString(csv, flush: true);

    return normalizedPath;
  }

  String normalizeFilenameForTest(String filePath) =>
      _normalizeCsvFilename(filePath);

  String buildCsvContent({
    required DateTime timestamp,
    required int startingBalanceCents,
    required List<CashEntryInput> cashRows,
    required List<CashEntryInput> coinRows,
    required int totalCashNotesCents,
    required int totalCoinsCents,
    required int finalTotalCents,
  }) {
    final rows = <List<dynamic>>[
      <dynamic>['CashVault Local Export'],
      <dynamic>['Timestamp', timestamp.toIso8601String()],
      <dynamic>[
        'Starting Balance',
        MoneyCalculationService.toDecimalString(startingBalanceCents),
      ],
      <dynamic>[],
      <dynamic>['Cash Notes'],
      <dynamic>['Label', 'Amount', 'Quantity', 'Row Total', 'Comment'],
      ...cashRows.map(
        (row) => <dynamic>[
          row.label,
          MoneyCalculationService.toDecimalString(row.amountCents),
          row.quantity,
          MoneyCalculationService.toDecimalString(row.rowTotalCents),
          row.comment ?? '',
        ],
      ),
      <dynamic>[],
      <dynamic>['Coins'],
      <dynamic>['Label', 'Amount', 'Quantity', 'Row Total', 'Comment'],
      ...coinRows.map(
        (row) => <dynamic>[
          row.label,
          MoneyCalculationService.toDecimalString(row.amountCents),
          row.quantity,
          MoneyCalculationService.toDecimalString(row.rowTotalCents),
          row.comment ?? '',
        ],
      ),
      <dynamic>[],
      <dynamic>['Totals'],
      <dynamic>[
        'Total Cash Notes',
        MoneyCalculationService.toDecimalString(totalCashNotesCents),
      ],
      <dynamic>[
        'Total Coins',
        MoneyCalculationService.toDecimalString(totalCoinsCents),
      ],
      <dynamic>[
        'Final Total',
        MoneyCalculationService.toDecimalString(finalTotalCents),
      ],
    ];

    final csv = const ListToCsvConverter().convert(rows);
    return '\uFEFF$csv';
  }

  String _normalizeCsvFilename(String filePath) {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Filename cannot be empty.');
    }

    if (p.extension(trimmed).toLowerCase() == '.csv') {
      return trimmed;
    }
    return '$trimmed.csv';
  }
}
