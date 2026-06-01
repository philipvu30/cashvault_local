import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cash_session_model.dart';
import '../state/session_detail_state.dart';

class SessionDetailHeader extends StatelessWidget {
  const SessionDetailHeader({
    super.key,
    required this.session,
    required this.mode,
    required this.sessionNameController,
    required this.businessDateController,
  });

  final CashSessionModel session;
  final SessionDetailMode mode;
  final TextEditingController sessionNameController;
  final TextEditingController businessDateController;

  @override
  Widget build(BuildContext context) {
    final edit = mode == SessionDetailMode.ownerEdit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _line(
          label: 'Session Name',
          value: edit
              ? TextField(
                  controller: sessionNameController,
                  decoration: const InputDecoration(isDense: true),
                )
              : Text(session.sessionName),
        ),
        const SizedBox(height: 8),
        _line(
          label: 'Business Date',
          value: edit
              ? TextField(
                  controller: businessDateController,
                  decoration: const InputDecoration(isDense: true),
                )
              : Text(_formatDate(session.businessDate)),
        ),
        const SizedBox(height: 8),
        _line(label: 'Status', value: Text(session.status)),
        const SizedBox(height: 8),
        _line(label: 'Created At', value: Text(_formatDateTime(session.createdAt))),
        const SizedBox(height: 8),
        _line(
          label: 'Closed At',
          value: Text(session.closedAt == null ? '-' : _formatDateTime(session.closedAt!)),
        ),
      ],
    );
  }

  Widget _line({required String label, required Widget value}) {
    return Row(
      children: <Widget>[
        SizedBox(width: 140, child: Text(label)),
        Expanded(child: value),
      ],
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
