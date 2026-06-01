import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/money_format_service.dart';
import '../state/previous_sessions_state.dart';

class PreviousSessionsTable extends StatelessWidget {
  const PreviousSessionsTable({
    super.key,
    required this.rows,
    required this.moneyFormatService,
    required this.onView,
    required this.onEdit,
    required this.onExport,
    required this.onReopen,
  });

  final List<PreviousSessionListRow> rows;
  final MoneyFormatService moneyFormatService;
  final void Function(PreviousSessionListRow row) onView;
  final void Function(PreviousSessionListRow row) onEdit;
  final void Function(PreviousSessionListRow row) onExport;
  final void Function(PreviousSessionListRow row) onReopen;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No previous sessions found.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text('Business Date')),
          DataColumn(label: Text('Session Name')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Starting Balance')),
          DataColumn(label: Text('Total Cash')),
          DataColumn(label: Text('Total Coins')),
          DataColumn(label: Text('Final Total')),
          DataColumn(label: Text('Created At')),
          DataColumn(label: Text('Closed At')),
          DataColumn(label: Text('Actions')),
        ],
        rows: rows.map((row) {
          final session = row.session;
          return DataRow(
            cells: <DataCell>[
              DataCell(Text(_formatDate(session.businessDate))),
              DataCell(Text(session.sessionName)),
              DataCell(Text(session.status)),
              DataCell(Text(moneyFormatService.formatCents(session.startingBalanceCents))),
              DataCell(Text(moneyFormatService.formatCents(row.totalCashCents))),
              DataCell(Text(moneyFormatService.formatCents(row.totalCoinCents))),
              DataCell(Text(moneyFormatService.formatCents(row.finalTotalCents))),
              DataCell(Text(_formatDateTime(session.createdAt))),
              DataCell(Text(session.closedAt == null ? '-' : _formatDateTime(session.closedAt!))),
              DataCell(
                Wrap(
                  spacing: 6,
                  children: <Widget>[
                    TextButton(onPressed: () => onView(row), child: const Text('View')),
                    TextButton(onPressed: () => onEdit(row), child: const Text('Edit')),
                    TextButton(onPressed: () => onExport(row), child: const Text('Export CSV')),
                    TextButton(
                      onPressed: session.status == 'open' ? null : () => onReopen(row),
                      child: const Text('Reopen'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String value) {
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd-MM-yyyy HH:mm').format(value);
  }
}
