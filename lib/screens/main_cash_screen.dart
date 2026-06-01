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
  bool _setupDialogShown = false;

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
        return Scaffold(
          appBar: AppBar(
            title: const Text('CashVault Local'),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
              ),
            ],
          ),
          body: IgnorePointer(
            ignoring: controller.busy,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStartingBalanceCard(controller),
                      const SizedBox(height: 12),
                      SummaryPanel(
                        startingBalanceCents: controller.startingBalanceCents,
                        totalCashNotesCents: controller.totalCashNotesCents,
                        totalCoinsCents: controller.totalCoinsCents,
                        finalTotalCents: controller.finalTotalCents,
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Cash Notes Input',
                        rows: controller.cashRows,
                        type: EntryType.cash,
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        title: 'Coins Input',
                        rows: controller.coinRows,
                        type: EntryType.coin,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => controller.addRow(EntryType.cash),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Cash Row'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => controller.addRow(EntryType.coin),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Coin Row'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _save(controller),
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _exportCsv(controller),
                            icon: const Icon(Icons.download),
                            label: const Text('Export CSV'),
                          ),
                        ],
                      ),
                      if (controller.lastExportPath != null) ...[
                        const SizedBox(height: 8),
                        Text('Last export: ${controller.lastExportPath}'),
                      ],
                    ],
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
          ),
        );
      },
    );
  }

  Widget _buildStartingBalanceCard(CashVaultController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starting Balance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  MoneyCalculationService.formatCents(
                    controller.startingBalanceCents,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _editStartingBalance,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Edit (Owner)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<CashEntryInput> rows,
    required EntryType type,
  }) {
    final controller = context.read<CashVaultController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('No rows yet. Use Add button to create rows.'),
            ...List<Widget>.generate(rows.length, (index) {
              return CashEntryRow(
                entry: rows[index],
                onChanged: (updated) =>
                    controller.updateRow(type, index, updated),
                onDelete: () => controller.removeRow(type, index),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _save(CashVaultController controller) async {
    final result = await controller.saveEntries();
    if (!mounted) {
      return;
    }

    if (result == null) {
      _showSnack('Saved.');
    } else {
      _showSnack(result);
    }
  }

  Future<void> _exportCsv(CashVaultController controller) async {
    final result = await controller.exportCsv();
    if (!mounted) {
      return;
    }

    if (result == null) {
      _showSnack('CSV exported.');
    } else {
      _showSnack(result);
    }
  }

  Future<void> _editStartingBalance() async {
    final controller = context.read<CashVaultController>();

    final password = await showPasswordDialog(
      context,
      title: 'Owner password required',
      hint: 'Password to edit starting balance',
    );

    if (password == null || password.isEmpty) {
      return;
    }

    final amountController = TextEditingController(
      text: (controller.startingBalanceCents / 100.0).toStringAsFixed(2),
    );

    final amountInput = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Starting Balance'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Starting Balance'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(amountController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amountInput == null) {
      return;
    }

    int newBalanceCents;
    try {
      newBalanceCents = MoneyCalculationService.parseToCents(amountInput);
    } catch (error) {
      _showSnack(error.toString());
      return;
    }

    final updated = await controller.updateStartingBalanceWithPassword(
      password: password,
      newBalanceCents: newBalanceCents,
    );

    if (!mounted) {
      return;
    }

    if (updated) {
      _showSnack('Starting balance updated.');
    } else {
      _showSnack('Wrong owner password. Edit blocked.');
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
        builder: (context) {
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
                      if (!ok) {
                        setState(
                          () => errorMessage = 'Failed to save password.',
                        );
                        return;
                      }

                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Save Password'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
