import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../state/app_state.dart';
import '../widgets/app_card.dart';
import '../widgets/cash_entry_table.dart';
import '../widgets/export_csv_dialog.dart';
import '../widgets/money_input_field.dart';
import '../widgets/new_session_dialog.dart';
import '../widgets/owner_password_setup_dialog.dart';
import '../widgets/password_dialog.dart';
import '../widgets/session_header.dart';
import '../widgets/summary_panel.dart';

class MainCashScreen extends StatefulWidget {
  const MainCashScreen({super.key});

  @override
  State<MainCashScreen> createState() => _MainCashScreenState();
}

class _MainCashScreenState extends State<MainCashScreen> {
  final _startingBalanceController = TextEditingController();

  @override
  void dispose() {
    _startingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.isReady) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (appState.needsOwnerPasswordSetup) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showSetupPasswordDialog(context, appState));
        }

        final session = appState.activeSession;
        if (session == null) {
          return const Scaffold(body: Center(child: Text('No active session')));
        }
        final canStartNewSession = !_isSameDate(session.createdAt, DateTime.now());

        final startingBalanceText = _editableMoney(appState.startingBalanceCents);
        if (_startingBalanceController.text != startingBalanceText) {
          _startingBalanceController.text = startingBalanceText;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('CashVault Local'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Center(child: Text('Session: ${session.sessionName}')),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180, minWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Main Cash',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      FilledButton(
                        onPressed: !session.isOpen || appState.isSaving
                            ? null
                            : () async {
                                final cents = appState.moneyParserService.tryParseToCents(_startingBalanceController.text);
                                await appState.saveSessionData(editedStartingBalanceCents: cents);
                                if (!context.mounted) return;
                                if (appState.errorMessage == null) {
                                  _showSnack(context, 'Session saved');
                                } else {
                                  _showSnack(context, appState.errorMessage!);
                                }
                              },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    title: 'Sessions',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SessionHeader(session: session),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            Tooltip(
                              message: canStartNewSession ? 'Create a new session' : 'New session available tomorrow',
                              child: OutlinedButton(
                                onPressed: canStartNewSession ? () => _startNewSession(context, appState) : null,
                                child: const Text('Start New Session'),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: session.isOpen ? () => _closeCurrentSession(context, appState) : null,
                              child: const Text('Close Current Session'),
                            ),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.previousSessions),
                              child: const Text('View Previous Sessions'),
                            ),
                            OutlinedButton(
                              onPressed: () => _showExportDialog(context, appState),
                              child: const Text('Export CSV'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    title: 'Starting Balance',
                    child: Column(
                      children: <Widget>[
                        MoneyInputField(
                          controller: _startingBalanceController,
                          parser: appState.moneyParserService,
                          readOnly: !appState.isStartingBalanceUnlocked || !session.isOpen,
                          labelText: 'Starting Balance',
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: !session.isOpen
                                ? null
                                : () async {
                                    final password = await showDialog<String?>(
                                      context: context,
                                      builder: (_) => const PasswordDialog(title: 'Unlock Starting Balance'),
                                    );
                                    if (password == null) return;
                                    final ok = await appState.unlockStartingBalance(password);
                                    if (!ok && context.mounted) {
                                      _showSnack(context, 'Invalid owner password');
                                    }
                                  },
                            child: const Text('Edit Starting Balance'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    title: 'Cash Notes',
                    subtitle: 'Enter quantities for saved cash labels.',
                    child: Column(
                      children: <Widget>[
                        CashEntryTable(
                          rows: appState.cashRows,
                          moneyFormatService: appState.moneyFormatService,
                          moneyParserService: appState.moneyParserService,
                          onQuantityChanged: appState.updateRowQuantity,
                          onLabelChanged: appState.updateCustomRowLabel,
                          onAmountChanged: appState.updateCustomRowAmount,
                          onDeleteRow: appState.removeCustomRow,
                          readOnly: !session.isOpen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    title: 'Coins',
                    subtitle: 'Enter quantities for saved coin labels.',
                    child: Column(
                      children: <Widget>[
                        CashEntryTable(
                          rows: appState.coinRows,
                          moneyFormatService: appState.moneyFormatService,
                          moneyParserService: appState.moneyParserService,
                          onQuantityChanged: appState.updateRowQuantity,
                          onLabelChanged: appState.updateCustomRowLabel,
                          onAmountChanged: appState.updateCustomRowAmount,
                          onDeleteRow: appState.removeCustomRow,
                          readOnly: !session.isOpen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    title: 'Summary',
                    child: SummaryPanel(
                      summary: appState.summary,
                      moneyFormatService: appState.moneyFormatService,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSetupPasswordDialog(BuildContext context, AppState appState) async {
    final result = await showDialog<OwnerPasswordSetupResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OwnerPasswordSetupDialog(),
    );
    if (result == null) return;
    await appState.createOwnerPassword(result.password, result.confirmPassword);
  }

  Future<void> _startNewSession(BuildContext context, AppState appState) async {
    final result = await showDialog<NewSessionDialogResult>(
      context: context,
      builder: (_) => NewSessionDialog(
        parser: appState.moneyParserService,
        defaultStartingBalanceCents: appState.summary.finalTotalCents,
      ),
    );
    if (result == null) return;
    await appState.startNewSession(
      sessionName: result.sessionName,
      businessDate: result.businessDate,
      startingBalanceCents: result.startingBalanceCents,
    );
  }

  Future<void> _closeCurrentSession(BuildContext context, AppState appState) async {
    await appState.closeCurrentSession();
  }

  Future<void> _showExportDialog(BuildContext context, AppState appState) async {
    final session = appState.activeSession;
    if (session == null) return;
    final filename = 'cashvault_${session.businessDate}_${_sanitizeSessionName(session.sessionName)}.csv';
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
      final output = await appState.exportCsv(
        filenameInput: dialogResult.filename,
        folderPath: dialogResult.folder,
      );
      if (context.mounted) _showSnack(context, 'CSV exported: $output');
    } catch (e) {
      if (context.mounted) _showSnack(context, e.toString());
    }
  }

  String _sanitizeSessionName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  }

  String _editableMoney(int cents) {
    final dollars = cents ~/ 100;
    final remains = cents % 100;
    return '$dollars.${remains.toString().padLeft(2, '0')}';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
