import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cash_session_model.dart';

class SessionHeader extends StatelessWidget {
  const SessionHeader({
    super.key,
    required this.session,
  });

  final CashSessionModel session;

  @override
  Widget build(BuildContext context) {
    final isOpen = session.status == 'open';
    final formattedBusinessDate = _formatDisplayDate(session.businessDate);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Session Name: ${session.sessionName}'),
              const SizedBox(height: 4),
              Text('Business Date: $formattedBusinessDate'),
            ],
          ),
        ),
        Chip(
          label: Text(isOpen ? 'Open' : 'Closed'),
          backgroundColor: isOpen ? const Color(0xFFE7F8EC) : const Color(0xFFF7E9E8),
        ),
      ],
    );
  }

  String _formatDisplayDate(String raw) {
    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (_) {
      return raw;
    }
  }
}
