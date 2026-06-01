import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cash_entry.dart';
import '../services/money_calculation_service.dart';
import '../state/cashvault_controller.dart';
import '../widgets/cash_entry_row.dart';
import '../widgets/password_dialog.dart';
import '../widgets/summary_panel.dart';
import 'settings_screen.dart';

class MainCashScreen extends StatefulWidget {
  const MainCashScreen({super.key});

  @override
  State<MainCashScreen> createState() => _MainCashScreenState();
}

class _MainCashScreenState extends State<MainCashScreen> {
  static const List<_ColumnSpec> _columns = <_ColumnSpec>[
    _ColumnSpec(label: 'Label', flex: 3),
    _ColumnSpec(label: 'Amount', flex: 2),
    _ColumnSpec(label: 'Quantity', flex: 2),
    _ColumnSpec(label: 'Total', flex: 2),
    _ColumnSpec(label: 'Comment', flex: 3),
    _ColumnSpec(label: '', flex: 1),
  ];

  final TextEditingController _startingBalanceController =
      TextEditingController();
  bool _setupDialogShown = false;

  @override
  void dispose() {
    _startingBalanceController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<CashVaultController>();
    if (controller.needsOwnerSetup && !_setupDialogShown) {
      _setupDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInitialOwnerSetupDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashVaultController>(
      builder: (context, controller, _) {
        _syncTextController(
          _startingBalanceController,
          controller.startingBalanceDraft,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('CashVault Local'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: OutlinedButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Settings'),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActionBar(controller),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          child: _buildStartingBalanceCard(controller),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: _buildEntrySection(
                            controller: controller,
                            title: 'Cash Notes',
                            rows: controller.cashRows,
                            type: EntryType.cash,
                            addLabel: '+ Add Cash Row',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: _buildEntrySection(
                            controller: controller,
                            title: 'Coins',
                            rows: controller.coinRows,
                            type: EntryType.coin,
                            addLabel: '+ Add Coin Row',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: SummaryPanel(
                            startingBalanceCents: controller.startingBalanceCents,
                            totalCashNotesCents: controller.totalCashNotesCents,
                            totalCoinsCents: controller.totalCoinsCents,
                            finalTotalCents: controller.finalTotalCents,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartingBalanceCard(CashVaultController controller) {
    final theme = Theme.of(context);
    final amountText = MoneyCalculationService.formatCents(
      controller.startingBalanceCents,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Starting Balance',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        if (controller.isStartingBalanceUnlocked)
          TextField(
            controller: _startingBalanceController,
            decoration: const InputDecoration(labelText: 'Starting Balance'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: controller.updateStartingBalanceDraft,
          )
        else
          TextFormField(
            key: ValueKey(amountText),
            initialValue: amountText,
            readOnly: true,
            enabled: false,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: 'Starting Balance'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        if (!controller.isStartingBalanceUnlocked) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: controller.busy ? null : _unlockStartingBalance,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Starting Balance'),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: controller.busy ? null : _saveStartingBalance,
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Save'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: controller.busy
                    ? null
                    : controller.cancelStartingBalanceEdit,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEntrySection({
    required CashVaultController controller,
    required String title,
    required List<CashEntryInput> rows,
    required EntryType type,
    required String addLabel,
  }) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: outline),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF5F7FB),
                child: Row(
                  children: _columns
                      .map(
                        (column) => Expanded(
                          flex: column.flex,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: outline),
                              ),
                            ),
                            child: Text(
                              column.label,
                              textAlign: column.label.isEmpty
                                  ? TextAlign.center
                                  : TextAlign.left,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No rows yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...List<Widget>.generate(rows.length, (index) {
                  return CashEntryRow(
                    key: ValueKey(
                      '${type.name}-${rows[index].id ?? rows[index].createdAt}',
                    ),
                    entry: rows[index],
                    onChanged: (updated) =>
                        controller.updateRow(type, index, updated),
                    onDelete: () => controller.removeRow(type, index),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: controller.busy ? null : () => controller.addRow(type),
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(CashVaultController controller) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: controller.busy ? null : () => _save(controller),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () => _exportCsv(controller),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7DFEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _save(CashVaultController controller) async {
    final result = await controller.saveEntries();
    if (!mounted) {
      return;
    }

    _showSnack(result ?? 'Saved.');
  }

  Future<void> _exportCsv(CashVaultController controller) async {
    final result = await controller.exportCsv();
    if (!mounted) {
      return;
    }

    _showSnack(result ?? 'CSV exported.');
  }

  Future<void> _unlockStartingBalance() async {
    final controller = context.read<CashVaultController>();

    final password = await showPasswordDialog(
      context,
      title: 'Owner password required',
      hint: 'Password to edit starting balance',
    );

    if (!mounted || password == null || password.isEmpty) {
      return;
    }

    final unlocked = await controller.unlockStartingBalance(password);
    if (!mounted) {
      return;
    }

    if (!unlocked) {
      _showSnack('Wrong owner password. Edit blocked.');
    }
  }

  Future<void> _saveStartingBalance() async {
    final controller = context.read<CashVaultController>();
    try {
      final result = await controller.saveStartingBalanceDraft();
      if (!mounted) {
        return;
      }
      _showSnack(result ?? 'Starting balance updated.');
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(error.message);
    }
  }

  Future<void> _showInitialOwnerSetupDialog() async {
    final controller = context.read<CashVaultController>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;

    while (mounted && controller.needsOwnerSetup) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Set owner password'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Owner password',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: () async {
                      final password = passwordController.text;
                      final confirm = confirmController.text;

                      if (password.isEmpty || confirm.isEmpty) {
                        setState(
                          () =>
                              errorMessage = 'Password fields cannot be empty.',
                        );
                        return;
                      }
                      if (password != confirm) {
                        setState(
                          () => errorMessage = 'Passwords do not match.',
                        );
                        return;
                      }

                      final ok = await controller.setupOwnerPassword(password);
                      if (!dialogContext.mounted) {
                        return;
                      }

                      if (ok) {
                        Navigator.of(dialogContext).pop();
                      } else {
                        setState(
                          () => errorMessage = 'Failed to set owner password.',
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    passwordController.dispose();
    confirmController.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncTextController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }
}

class _ColumnSpec {
  const _ColumnSpec({required this.label, required this.flex});

  final String label;
  final int flex;
}
