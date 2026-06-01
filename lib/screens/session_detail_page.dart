import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cash_entry_model.dart';
import '../models/cash_session_model.dart';
import '../state/app_state.dart';
import '../state/cash_entries_state.dart';
import '../state/session_detail_state.dart';
import '../widgets/app_card.dart';
import '../widgets/export_csv_dialog.dart';
import '../widgets/password_dialog.dart';
import '../widgets/session_detail_header.dart';
import '../widgets/session_mode_banner.dart';
import '../widgets/session_totals_row.dart';

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({
    super.key,
    required this.args,
  });

  final SessionDetailArgs args;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  CashSessionModel? _session;
  SessionDetailMode _mode = SessionDetailMode.readOnly;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _sessionNameController = TextEditingController();
  final _businessDateController = TextEditingController();
  final _eftPosController = TextEditingController();

  List<CashEntryDraft> _cashRows = <CashEntryDraft>[];
  List<CashEntryDraft> _coinRows = <CashEntryDraft>[];

  @override
  void initState() {
    super.initState();
    _mode = widget.args.mode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSession());
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _businessDateController.dispose();
    _eftPosController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final appState = context.read<AppState>();
    final session = await appState.sessionById(widget.args.sessionId);
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Session not found';
      });
      return;
    }
    final entries = await appState.entriesBySessionId(session.id);
    final cash = <CashEntryDraft>[];
    final coin = <CashEntryDraft>[];
    for (final entry in entries) {
      final draft = CashEntryDraft.fromModel(entry);
      if (entry.entryType == 'cash') {
        cash.add(draft);
      } else {
        coin.add(draft);
      }
    }

    if (!mounted) return;
    setState(() {
      _session = session;
      _cashRows = cash;
      _coinRows = coin;
      _sessionNameController.text = session.sessionName;
      _businessDateController.text = session.businessDate;
      _eftPosController.text = _editableMoney(session.eftPosCents);
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Details')),
        body: Center(child: Text(_error ?? 'Session not found')),
      );
    }
    final session = _session!;
    final edit = _mode == SessionDetailMode.ownerEdit;
    final startingBalanceCents = session.startingBalanceCents;
    final eftPosCents = appState.moneyParserService.tryParseToCents(_eftPosController.text) ?? session.eftPosCents;
    final totalCash = _cashRows.fold<int>(0, (sum, row) => sum + row.rowTotalCents);
    final totalCoin = _coinRows.fold<int>(0, (sum, row) => sum + row.rowTotalCents);
    final finalTotal = startingBalanceCents + totalCash + totalCoin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => _exportSession(),
            child: const Text('Export CSV'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180, minWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              SessionModeBanner(mode: _mode),
              const SizedBox(height: 16),
              AppCard(
                title: 'Session Info',
                child: SessionDetailHeader(
                  session: session,
                  mode: _mode,
                  sessionNameController: _sessionNameController,
                  businessDateController: _businessDateController,
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'Starting Balance',
                child: Text(appState.moneyFormatService.formatCents(startingBalanceCents)),
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'EFT POS',
                child: edit
                    ? TextField(
                        controller: _eftPosController,
                        decoration: const InputDecoration(labelText: 'EFT POS', prefixText: '\$'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      )
                    : Text(appState.moneyFormatService.formatCents(eftPosCents)),
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'Cash Notes',
                child: Column(
                  children: <Widget>[
                    _entryTable(
                      rows: _cashRows,
                      entryType: 'cash',
                      editable: edit,
                      appState: appState,
                    ),
                    if (edit) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _cashRows = <CashEntryDraft>[
                              ..._cashRows,
                              CashEntryDraft(
                                sessionId: session.id,
                                entryType: 'cash',
                                label: '',
                                amountCents: 0,
                                quantity: 0,
                                comment: '',
                                isCustom: true,
                              ),
                            ];
                          }),
                          icon: const Icon(Icons.add),
                          label: const Text('Custom Cash Row'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'Coins',
                child: Column(
                  children: <Widget>[
                    _entryTable(
                      rows: _coinRows,
                      entryType: 'coin',
                      editable: edit,
                      appState: appState,
                    ),
                    if (edit) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _coinRows = <CashEntryDraft>[
                              ..._coinRows,
                              CashEntryDraft(
                                sessionId: session.id,
                                entryType: 'coin',
                                label: '',
                                amountCents: 0,
                                quantity: 0,
                                comment: '',
                                isCustom: true,
                              ),
                            ];
                          }),
                          icon: const Icon(Icons.add),
                          label: const Text('Custom Coin Row'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'Summary',
                child: Column(
                  children: <Widget>[
                    SessionTotalsRow(
                      label: 'Starting Balance',
                      valueCents: startingBalanceCents,
                      moneyFormatService: appState.moneyFormatService,
                    ),
                    SessionTotalsRow(
                      label: 'Total Cash Notes',
                      valueCents: totalCash,
                      moneyFormatService: appState.moneyFormatService,
                    ),
                    SessionTotalsRow(
                      label: 'Total Coins',
                      valueCents: totalCoin,
                      moneyFormatService: appState.moneyFormatService,
                    ),
                    const Divider(),
                    SessionTotalsRow(
                      label: 'FINAL TOTAL',
                      valueCents: finalTotal,
                      moneyFormatService: appState.moneyFormatService,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: edit
                    ? <Widget>[
                        FilledButton(
                          onPressed: _saving ? null : _saveChanges,
                          child: const Text('Save Changes'),
                        ),
                        OutlinedButton(
                          onPressed: _saving ? null : () => _cancelEditing(),
                          child: const Text('Cancel Editing'),
                        ),
                        OutlinedButton(
                          onPressed: _saving ? null : _exportSession,
                          child: const Text('Export CSV'),
                        ),
                      ]
                    : <Widget>[
                        OutlinedButton(
                          onPressed: _exportSession,
                          child: const Text('Export CSV'),
                        ),
                      ],
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryTable({
    required List<CashEntryDraft> rows,
    required String entryType,
    required bool editable,
    required AppState appState,
  }) {
    final readOnly = !editable;
    return Column(
      children: <Widget>[
        const Row(
          children: <Widget>[
            Expanded(flex: 3, child: Text('Label', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            Expanded(flex: 3, child: Text('Comment', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            SizedBox(width: 50, child: Text('')),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) {
            final presetRow = row.presetId != null;
            final lockLabelAmount = readOnly || presetRow;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: lockLabelAmount
                        ? Text(row.label)
                        : TextFormField(
                            initialValue: row.label,
                            decoration: const InputDecoration(labelText: 'Label'),
                            onChanged: (value) => setState(() => row.label = value),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: lockLabelAmount
                        ? Text(appState.moneyFormatService.formatCents(row.amountCents))
                        : TextFormField(
                            initialValue: _editableMoney(row.amountCents),
                            decoration: const InputDecoration(labelText: 'Amount'),
                            onChanged: (value) {
                              final cents = appState.moneyParserService.tryParseToCents(value);
                              if (cents != null) {
                                setState(() => row.amountCents = cents);
                              }
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: readOnly
                        ? Text('${row.quantity}')
                        : TextFormField(
                            initialValue: '${row.quantity}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                            onChanged: (value) => setState(() => row.quantity = int.tryParse(value) ?? 0),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      appState.moneyFormatService.formatCents(row.rowTotalCents),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: readOnly
                        ? Text(row.comment.isEmpty ? '-' : row.comment)
                        : TextFormField(
                            initialValue: row.comment,
                            decoration: const InputDecoration(labelText: 'Comment'),
                            onChanged: (value) => setState(() => row.comment = value),
                          ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: row.isCustom && editable
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                if (entryType == 'cash') {
                                  _cashRows = _cashRows.where((r) => !identical(r, row)).toList();
                                } else {
                                  _coinRows = _coinRows.where((r) => !identical(r, row)).toList();
                                }
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _enableEditMode() async {
    final appState = context.read<AppState>();
    final password = await showDialog<String?>(
      context: context,
      builder: (_) => const PasswordDialog(),
    );
    if (password == null) return;
    final ok = await appState.verifyOwnerPassword(password);
    if (!ok) {
      if (mounted) setState(() => _error = 'Invalid owner password');
      return;
    }
    if (mounted) setState(() => _mode = SessionDetailMode.ownerEdit);
  }

  Future<void> _saveChanges() async {
    final appState = context.read<AppState>();
    final session = _session;
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sessionName = _sessionNameController.text.trim();
      final businessDate = _businessDateController.text.trim();
      final eftPosCents = appState.moneyParserService.tryParseToCents(_eftPosController.text);
      if (sessionName.isEmpty || businessDate.isEmpty || eftPosCents == null || eftPosCents < 0) {
        throw StateError('Invalid session info values');
      }

      final merged = <CashEntryDraft>[..._cashRows, ..._coinRows];
      final saveRows = <CashEntryModel>[];
      for (final row in merged) {
        final touched = row.quantity > 0 || row.comment.trim().isNotEmpty;
        if (!touched) continue;
        if (row.quantity <= 0) {
          throw StateError('Quantity must be greater than 0 for saved rows');
        }
        if (row.amountCents < 0) {
          throw StateError('Amount must be non-negative');
        }
        if (row.isCustom && row.label.trim().isEmpty) {
          throw StateError('Custom row label cannot be empty');
        }
        saveRows.add(
          CashEntryModel(
            id: row.id,
            sessionId: session.id,
            presetId: row.presetId,
            entryType: row.entryType,
            label: row.label.trim(),
            amountCents: row.amountCents,
            quantity: row.quantity,
            rowTotalCents: row.amountCents * row.quantity,
            comment: row.comment.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isCustom: row.isCustom,
          ),
        );
      }

      await appState.updatePreviousSession(
        sessionId: session.id,
        sessionName: sessionName,
        businessDate: businessDate,
        startingBalanceCents: session.startingBalanceCents,
        eftPosCents: eftPosCents,
        entries: saveRows,
      );
      await appState.logAuditAction(
        'previous_session_edited',
        details: 'id=${session.id} at=${DateTime.now().toIso8601String()}',
      );
      await _loadSession();
      if (mounted) {
        setState(() => _mode = SessionDetailMode.readOnly);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _cancelEditing() async {
    await _loadSession();
    if (mounted) {
      setState(() => _mode = SessionDetailMode.readOnly);
    }
  }

  Future<void> _exportSession() async {
    final appState = context.read<AppState>();
    final session = _session;
    if (session == null) return;

    final filename = 'cashvault_${session.businessDate}_${_slug(session.sessionName)}.csv';
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
        sessionId: session.id,
        filenameInput: dialogResult.filename,
        folderPath: dialogResult.folder,
        auditAction: 'previous_session_exported',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported: $output')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  String _editableMoney(int cents) {
    final dollars = cents ~/ 100;
    final remains = cents % 100;
    return '$dollars.${remains.toString().padLeft(2, '0')}';
  }

  String _slug(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  }
}
