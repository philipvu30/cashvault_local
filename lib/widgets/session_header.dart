import 'package:flutter/material.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Session Name: ${session.sessionName}'),
              const SizedBox(height: 4),
              Text('Business Date: ${session.businessDate}'),
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
}
