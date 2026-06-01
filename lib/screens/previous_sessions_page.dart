import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../models/cash_entry_model.dart';
import '../services/previous_sessions_service.dart';
import '../state/app_state.dart';
import '../state/previous_sessions_state.dart';
import '../state/session_detail_state.dart';
import '../widgets/app_card.dart';
import '../widgets/export_csv_dialog.dart';
import '../widgets/password_dialog.dart';
import '../widgets/previous_sessions_table.dart';

class PreviousSessionsPage extends StatefulWidget {
  const PreviousSessionsPage({super.key});

  @override
  State<PreviousSessionsPage> createState() => _PreviousSessionsPageState();
}

class _PreviousSessionsPageState extends State<PreviousSessionsPage> {
  final _service = const PreviousSessionsService();
  final _searchController = TextEditingController();
  final _dateController = TextEditingController();

  List<PreviousSessionListRow> _allRows = <PreviousSessionListRow>[];
  List<PreviousSessionListRow> _filteredRows = <PreviousSessionListRow>[];
  String _statusFilter = 'All';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final appState = context.read<AppState>();
    final sessions = await appState.allSessions();
    final map = <int, List<CashEntryModel>>{};
    for (final session in sessions) {
      map[session.id] = await appState.entriesBySessionId(session.id);
    }
    final rows = _service.buildRows(
      sessions: sessions,
      entriesBySessionId: map,
    );
    if (!mounted) return;
    setState(() {
      _allRows = rows;
      _loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final rows = _service.applyFilters(
      rows: _allRows,
      searchTerm: _searchController.text,
      businessDateFilter: _dateController.text,
      statusFilter: _statusFilter,
    );
    setState(() => _filteredRows = rows);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Sessions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500, minWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'Review saved business days and export or edit session data.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(labelText: 'Search by session name'),
                            onChanged: (_) => _applyFilters(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            decoration: const InputDecoration(labelText: 'Business date (yyyy-mm-dd)'),
                            onChanged: (_) => _applyFilters(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<String>(
                            value: _statusFilter,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: const <String>['All', 'Open', 'Closed']
                                .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _statusFilter = value ?? 'All');
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            _dateController.clear();
                            _statusFilter = 'All';
                            _applyFilters();
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PreviousSessionsTable(
                          rows: _filteredRows,
                          moneyFormatService: appState.moneyFormatService,
                          onView: (row) => _openDetail(
                            row: row,
                            mode: SessionDetailMode.readOnly,
                            logViewed: true,
                          ),
                          onEdit: (row) => _openEdit(row),
                          onExport: (row) => _exportRow(row),
                          onReopen: (row) => _reopenRow(row),
                        ),
                      ),
                    if (!_loading && _filteredRows.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back to Main Cash Screen'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail({
    required PreviousSessionListRow row,
    required SessionDetailMode mode,
    required bool logViewed,
  }) async {
    final appState = context.read<AppState>();
    if (logViewed) {
      await appState.logAuditAction('previous_session_viewed', details: 'id=${row.session.id}');
    }
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.sessionDetail,
      arguments: SessionDetailArgs(sessionId: row.session.id, mode: mode),
    );
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openEdit(PreviousSessionListRow row) async {
    final appState = context.read<AppState>();
    final password = await showDialog<String?>(
      context: context,
      builder: (_) => const PasswordDialog(),
    );
    if (password == null) return;
    final ok = await appState.verifyOwnerPassword(password);
    if (!ok) {
      if (mounted) _snack('Invalid owner password');
      return;
    }
    await _openDetail(row: row, mode: SessionDetailMode.ownerEdit, logViewed: false);
  }

  Future<void> _exportRow(PreviousSessionListRow row) async {
    final appState = context.read<AppState>();
    final filename = 'cashvault_${row.session.businessDate}_${_slug(row.session.sessionName)}.csv';
    final dialogResult = await showDialog<ExportCsvDialogResult>(
      context: context,
      builder: (_) => ExportCsvDialog(
        initialFilename: filename,
        initialFolder: appState.lastExportFolder ?? '',
        onPickFolder: appState.pickExportFolder,
      ),
    );
    if (dialogResult == null) return;
    try {
      final output = await appState.exportSelectedSessionCsv(
        sessionId: row.session.id,
        filenameInput: dialogResult.filename,
        folderPath: dialogResult.folder,
        auditAction: 'previous_session_exported',
      );
      if (mounted) _snack('CSV exported: $output');
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  Future<void> _reopenRow(PreviousSessionListRow row) async {
    final appState = context.read<AppState>();
    final password = await showDialog<String?>(
      context: context,
      builder: (_) => const PasswordDialog(),
    );
    if (password == null) return;
    final ok = await appState.verifyOwnerPassword(password);
    if (!ok) {
      if (mounted) _snack('Invalid owner password');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reopen Session'),
        content: Text('Reopen "${row.session.sessionName}" as active session?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reopen')),
        ],
      ),
    );
    if (confirm != true) return;

    await appState.reopenPreviousSessionWithAudit(row.session.id);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
  }

  String _slug(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
