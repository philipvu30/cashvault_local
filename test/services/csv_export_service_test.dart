import 'dart:io';

import 'package:cashvault_local/data/database.dart';
import 'package:cashvault_local/data/repositories/app_settings_repository.dart';
import 'package:cashvault_local/data/repositories/audit_log_repository.dart';
import 'package:cashvault_local/models/cash_entry_model.dart';
import 'package:cashvault_local/models/cash_session_model.dart';
import 'package:cashvault_local/models/cash_summary_model.dart';
import 'package:cashvault_local/services/csv_export_service.dart';
import 'package:cashvault_local/services/money_format_service.dart';
import 'package:cashvault_local/services/money_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAppDatabase extends Fake implements AppDatabase {
  final List<List<Object?>> executedStatements = <List<Object?>>[];

  @override
  Future<void> execute(String sql, [List<Object?> variables = const <Object?>[]]) async {
    executedStatements.add(<Object?>[sql, ...variables]);
  }
}

void main() {
  group('CsvExportService.exportSessionCsv', () {
    test('write final total without starting balance', () async {
      final database = FakeAppDatabase();
      final service = CsvExportService(
        appSettingsRepository: AppSettingsRepository(database),
        auditLogRepository: AuditLogRepository(database),
        moneyFormatService: MoneyFormatService(),
        moneyParserService: MoneyParserService(),
      );
      final tempDir = await Directory.systemTemp.createTemp('cashvault_csv_test');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final outputPath = await service.exportSessionCsv(
        session: CashSessionModel(
          id: 1,
          sessionName: 'Session 1',
          businessDate: '2026-06-19',
          startingBalanceCents: 20000,
          eftPosText: '0.00',
          status: 'closed',
          createdAt: DateTime.parse('2026-06-19T09:00:00Z'),
          closedAt: DateTime.parse('2026-06-19T17:00:00Z'),
        ),
        entries: <CashEntryModel>[
          CashEntryModel(
            id: 1,
            sessionId: 1,
            presetId: null,
            entryType: 'cash',
            label: '\$50',
            amountCents: 5000,
            quantity: 2,
            rowTotalCents: 10000,
            comment: '',
            createdAt: DateTime.parse('2026-06-19T09:00:00Z'),
            updatedAt: DateTime.parse('2026-06-19T09:00:00Z'),
            isCustom: false,
          ),
          CashEntryModel(
            id: 2,
            sessionId: 1,
            presetId: null,
            entryType: 'coin',
            label: 'Coins',
            amountCents: 100,
            quantity: 5,
            rowTotalCents: 500,
            comment: '',
            createdAt: DateTime.parse('2026-06-19T09:00:00Z'),
            updatedAt: DateTime.parse('2026-06-19T09:00:00Z'),
            isCustom: false,
          ),
        ],
        summary: const CashSummaryModel(
          startingBalanceCents: 20000,
          totalCashCents: 10000,
          totalCoinCents: 500,
        ),
        folderPath: tempDir.path,
        filenameInput: 'session_export',
      );

      final content = await File(outputPath).readAsString();

      expect(content, contains(r'totals,Session 1,2026-06-19,final_total,Final Total,,,$105.00,,10500,'));
      expect(content, isNot(contains(r'totals,Session 1,2026-06-19,final_total,Final Total,,,$305.00,,30500,')));
    });
  });
}
