import 'package:cashvault_local/models/cash_entry.dart';
import 'package:cashvault_local/services/csv_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvExportService', () {
    test('adds csv extension when missing', () {
      final service = CsvExportService();
      final output = service.normalizeFilenameForTest('daily_report');
      expect(output, 'daily_report.csv');
    });

    test('keeps extension when csv exists', () {
      final service = CsvExportService();
      final output = service.normalizeFilenameForTest('daily_report.csv');
      expect(output, 'daily_report.csv');
    });

    test('rejects empty filename', () {
      final service = CsvExportService();
      expect(
        () => service.normalizeFilenameForTest('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('creates expected csv sections', () {
      final service = CsvExportService();
      final now = DateTime.utc(2026, 6, 1, 5, 0, 0);
      final cashRows = [
        CashEntryInput.empty(EntryType.cash).copyWith(
          label: 'Fifty',
          amountCents: 5000,
          quantity: 2,
          comment: 'front desk',
        ),
      ];
      final coinRows = [
        CashEntryInput.empty(
          EntryType.coin,
        ).copyWith(label: 'Quarter', amountCents: 25, quantity: 10),
      ];

      final csv = service.buildCsvContent(
        timestamp: now,
        startingBalanceCents: 10000,
        cashRows: cashRows,
        coinRows: coinRows,
        totalCashNotesCents: 10000,
        totalCoinsCents: 250,
        finalTotalCents: 20250,
      );

      expect(csv.contains('CashVault Local Export'), isTrue);
      expect(csv.contains('Starting Balance'), isTrue);
      expect(csv.contains('Cash Notes'), isTrue);
      expect(csv.contains('Coins'), isTrue);
      expect(csv.contains('Final Total'), isTrue);
      expect(csv.contains('Fifty'), isTrue);
      expect(csv.contains('Quarter'), isTrue);
      expect(csv.contains(now.toIso8601String()), isTrue);
    });
  });
}
