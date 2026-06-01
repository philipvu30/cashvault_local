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
    required this.onExport,
  });

  final List<PreviousSessionListRow> rows;
  final MoneyFormatService moneyFormatService;
  final void Function(PreviousSessionListRow row) onView;
  final void Function(PreviousSessionListRow row) onExport;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No previous sessions found.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final table = DataTable(
          columnSpacing: 14,
          horizontalMargin: 10,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
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
                DataCell(SizedBox(width: 110, child: Text(_formatDate(session.businessDate)))),
                DataCell(SizedBox(width: 180, child: Text(session.sessionName, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 70, child: Text(session.status))),
                DataCell(SizedBox(width: 110, child: Text(moneyFormatService.formatCents(session.startingBalanceCents)))),
                DataCell(SizedBox(width: 100, child: Text(moneyFormatService.formatCents(row.totalCashCents)))),
                DataCell(SizedBox(width: 100, child: Text(moneyFormatService.formatCents(row.totalCoinCents)))),
                DataCell(SizedBox(width: 100, child: Text(moneyFormatService.formatCents(row.finalTotalCents)))),
                DataCell(SizedBox(width: 130, child: Text(_formatDateTime(session.createdAt)))),
                DataCell(SizedBox(width: 130, child: Text(session.closedAt == null ? '-' : _formatDateTime(session.closedAt!)))),
                DataCell(
                  SizedBox(
                    width: 160,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => onView(row),
                          style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () => onExport(row),
                          style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                          child: const Text('Export CSV'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        );

        final minTableWidth = constraints.maxWidth < 1500 ? 1500.0 : constraints.maxWidth;
        return SizedBox(
          height: 480,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minTableWidth),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: table,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
