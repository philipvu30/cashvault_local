import 'package:flutter/material.dart';

import '../models/cash_session_model.dart';

class ReopenSessionDialog extends StatefulWidget {
  const ReopenSessionDialog({
    super.key,
    required this.sessions,
  });

  final List<CashSessionModel> sessions;

  @override
  State<ReopenSessionDialog> createState() => _ReopenSessionDialogState();
}

class _ReopenSessionDialogState extends State<ReopenSessionDialog> {
  int? selectedId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reopen Previous Session'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.sessions
              .map(
                (session) => RadioListTile<int>(
                  value: session.id,
                  groupValue: selectedId,
                  onChanged: (value) => setState(() => selectedId = value),
                  title: Text(session.sessionName),
                  subtitle: Text('${session.businessDate} • ${session.status}'),
                ),
              )
              .toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: selectedId == null ? null : () => Navigator.pop(context, selectedId),
          child: const Text('Reopen Selected Session'),
        ),
      ],
    );
  }
}
