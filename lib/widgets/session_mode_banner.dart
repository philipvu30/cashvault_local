import 'package:flutter/material.dart';

import '../state/session_detail_state.dart';

class SessionModeBanner extends StatelessWidget {
  const SessionModeBanner({
    super.key,
    required this.mode,
  });

  final SessionDetailMode mode;

  @override
  Widget build(BuildContext context) {
    final isEdit = mode == SessionDetailMode.ownerEdit;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEdit ? const Color(0xFFFFF3E0) : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEdit ? const Color(0xFFE0A96D) : const Color(0xFF9EB8E6),
        ),
      ),
      child: Text(
        isEdit
            ? 'Owner Edit Mode — You are editing saved session history.'
            : 'Viewing previous session',
      ),
    );
  }
}
