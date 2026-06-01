import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../data/repositories/app_settings_repository.dart';
import '../data/repositories/audit_log_repository.dart';
import '../models/cash_entry_model.dart';
import '../models/cash_session_model.dart';
import '../models/cash_summary_model.dart';
import 'money_format_service.dart';

class CsvExportService {
  const CsvExportService({
    required AppSettingsRepository appSettingsRepository,
    required AuditLogRepository auditLogRepository,
    required MoneyFormatService moneyFormatService,
  })  : _appSettingsRepository = appSettingsRepository,
        _auditLogRepository = auditLogRepository,
        _moneyFormatService = moneyFormatService;

  final AppSettingsRepository _appSettingsRepository;
  final AuditLogRepository _auditLogRepository;
  final MoneyFormatService _moneyFormatService;

  Future<String?> pickFolder() {
    return FilePicker.platform.getDirectoryPath();
  }

  Future<String> exportSessionCsv({
    required CashSessionModel session,
    required List<CashEntryModel> entries,
    required CashSummaryModel summary,
    required String folderPath,
    required String filenameInput,
    String auditAction = 'csv_exported',
  }) async {
    final filename = _sanitizeFilename(filenameInput);
    if (filename.isEmpty) {
      throw ArgumentError('Filename cannot be empty');
    }
    final finalName = filename.toLowerCase().endsWith('.csv') ? filename : '$filename.csv';
    final filePath = p.join(folderPath, finalName);

    final rows = <List<dynamic>>[
      <String>[
        'section',
        'session_name',
        'business_date',
        'type',
        'label',
        'amount',
        'quantity',
        'row_total',
        'amount_cents',
        'row_total_cents',
        'comment',
        'created_at',
      ],
      <dynamic>[
        'session',
        session.sessionName,
        session.businessDate,
        'starting_balance',
        'Starting Balance',
        _moneyFormatService.formatCents(summary.startingBalanceCents),
        1,
        _moneyFormatService.formatCents(summary.startingBalanceCents),
        summary.startingBalanceCents,
        summary.startingBalanceCents,
        '',
        DateTime.now().toIso8601String(),
      ],
      <dynamic>[
        'session',
        session.sessionName,
        session.businessDate,
        'eft_pos',
        'EFT POS',
        _moneyFormatService.formatCents(session.eftPosCents),
        1,
        _moneyFormatService.formatCents(session.eftPosCents),
        session.eftPosCents,
        session.eftPosCents,
        '',
        DateTime.now().toIso8601String(),
      ],
    ];

    for (final entry in entries) {
      rows.add(
        <dynamic>[
          'entries',
          session.sessionName,
          session.businessDate,
          entry.entryType,
          entry.label,
          _moneyFormatService.formatCents(entry.amountCents),
          entry.quantity,
          _moneyFormatService.formatCents(entry.rowTotalCents),
          entry.amountCents,
          entry.rowTotalCents,
          entry.comment,
          entry.updatedAt.toIso8601String(),
        ],
      );
    }

    rows.addAll(
      <List<dynamic>>[
        <dynamic>[
          'totals',
          session.sessionName,
          session.businessDate,
          'total_cash_notes',
          'Total Cash Notes',
          '',
          '',
          _moneyFormatService.formatCents(summary.totalCashCents),
          '',
          summary.totalCashCents,
          '',
          DateTime.now().toIso8601String(),
        ],
        <dynamic>[
          'totals',
          session.sessionName,
          session.businessDate,
          'total_coins',
          'Total Coins',
          '',
          '',
          _moneyFormatService.formatCents(summary.totalCoinCents),
          '',
          summary.totalCoinCents,
          '',
          DateTime.now().toIso8601String(),
        ],
        <dynamic>[
          'totals',
          session.sessionName,
          session.businessDate,
          'final_total',
          'Final Total',
          '',
          '',
          _moneyFormatService.formatCents(summary.finalTotalCents),
          '',
          summary.finalTotalCents,
          '',
          DateTime.now().toIso8601String(),
        ],
      ],
    );

    final content = const ListToCsvConverter().convert(rows);
    final file = File(filePath);
    await file.writeAsString(content, flush: true);

    await _appSettingsRepository.upsertSetting('last_export_folder', folderPath);
    await _auditLogRepository.log(auditAction, details: filePath);
    return filePath;
  }

  String _sanitizeFilename(String value) {
    return value.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
