import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/cashvault_controller.dart';
import '../widgets/password_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CashVaultController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Database status'),
              subtitle: Text(
                'Created at: ${controller.databaseCreatedAt ?? 'Unknown'}\n'
                'Last export: ${controller.lastExportPath ?? 'None'}\n'
                'Preferred export directory: ${controller.preferredExportDirectory ?? 'None'}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Change owner password'),
              subtitle: const Text('Owner password required'),
              trailing: const Icon(Icons.lock_reset),
              onTap: () => _changeOwnerPassword(context),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Export location option'),
              subtitle: const Text('Set preferred export folder'),
              trailing: const Icon(Icons.folder_open),
              onTap: () => _pickExportLocation(context),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Reset daily cash entries'),
              subtitle: const Text(
                'Owner password required. Starting balance stays.',
              ),
              trailing: const Icon(Icons.delete_forever),
              onTap: () => _resetEntries(context),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Main Cash Screen'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeOwnerPassword(BuildContext context) async {
    final controller = context.read<CashVaultController>();

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    String? message;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change owner password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(message!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (newController.text != confirmController.text) {
                      setState(() => message = 'New passwords do not match.');
                      return;
                    }

                    final changed = await controller.changeOwnerPassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );

                    if (!changed) {
                      setState(
                        () => message =
                            'Wrong current password or invalid new password.',
                      );
                      return;
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Owner password changed.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetEntries(BuildContext context) async {
    final controller = context.read<CashVaultController>();

    final password = await showPasswordDialog(
      context,
      title: 'Owner password required',
      hint: 'Password to reset daily entries',
    );

    if (password == null || password.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm reset'),
        content: const Text('This will delete all current cash and coin rows.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final ok = await controller.resetDailyEntriesWithPassword(password);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Daily entries reset.' : 'Wrong owner password. Reset blocked.',
        ),
      ),
    );
  }

  Future<void> _pickExportLocation(BuildContext context) async {
    final controller = context.read<CashVaultController>();
    final selected = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select preferred export directory',
    );

    if (selected == null || !context.mounted) {
      return;
    }

    await controller.updatePreferredExportDirectory(selected);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preferred export directory saved: $selected')),
    );
  }
}
