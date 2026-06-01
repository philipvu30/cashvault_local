import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/denomination_preset_model.dart';
import '../state/app_state.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/denomination_preset_editor_dialog.dart';
import '../widgets/new_session_dialog.dart';
import '../widgets/password_dialog.dart';
import '../widgets/reopen_session_dialog.dart';
import '../widgets/settings_section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final session = appState.activeSession;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180, minWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    'Manage security, database, labels, sessions, and app preferences.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Owner Security',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Owner Password Status: Password Set'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _changePassword(context, appState),
                          child: const Text('Change Owner Password'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionCard(
                    title: 'Starting Balance Protection',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Starting balance editing requires owner password.'),
                        SizedBox(height: 8),
                        Text('Status: Enabled'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Database',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Storage Mode: Local Only'),
                        const Text('Database Encryption: Enabled'),
                        const Text('Database Location: App Folder'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _snack(context, 'Database status: local encrypted SQLite active'),
                          child: const Text('Show Database Status'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Export Settings',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Last Export Folder: ${appState.lastExportFolder?.isNotEmpty == true ? appState.lastExportFolder : 'Not Set'}'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () async => appState.pickExportFolder(),
                          child: const Text('Choose Default Export Folder'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Labels / Denominations',
                    subtitle: 'Manage reusable cash and coin labels shown on Main Cash Screen.',
                    child: Column(
                      children: <Widget>[
                        _presetTable(
                          context: context,
                          appState: appState,
                          title: 'Cash Labels',
                          type: 'cash',
                          presets: appState.cashPresets,
                        ),
                        const SizedBox(height: 16),
                        _presetTable(
                          context: context,
                          appState: appState,
                          title: 'Coin Labels',
                          type: 'coin',
                          presets: appState.coinPresets,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Sessions',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Current Session: ${session?.sessionName ?? '-'}'),
                        Text('Business Date: ${session?.businessDate ?? '-'}'),
                        Text('Status: ${session?.status ?? '-'}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: () => _startNewSession(context, appState),
                              child: const Text('Start New Session'),
                            ),
                            OutlinedButton(
                              onPressed: session == null ? null : () => _closeCurrentSession(context, appState),
                              child: const Text('Close Current Session'),
                            ),
                            OutlinedButton(
                              onPressed: () => _reopenSession(context, appState),
                              child: const Text('Reopen Previous Session'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'App Info',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('App Name: CashVault Local'),
                        const Text('Version: 1.0.0'),
                        const Text('Platform: Windows'),
                        Text('Database Created: ${appState.databaseCreatedAt ?? '-'}'),
                      ],
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

  Widget _presetTable({
    required BuildContext context,
    required AppState appState,
    required String title,
    required String type,
    required List<DenominationPresetModel> presets,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              onPressed: () => _editPreset(context, appState, type: type, preset: null),
              icon: const Icon(Icons.add),
              label: Text('Add ${type == 'cash' ? 'Cash' : 'Coin'} Label'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: <Widget>[
            Expanded(flex: 3, child: Text('Label', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text('Sort', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 6),
        ...presets.map(
          (preset) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text(preset.label)),
                Expanded(flex: 2, child: Text(appState.moneyFormatService.formatCents(preset.amountCents))),
                Expanded(child: Text(preset.isActive ? 'Active' : 'Inactive')),
                Expanded(child: Text('${preset.sortOrder}')),
                Expanded(
                  flex: 2,
                  child: Wrap(
                    spacing: 6,
                    children: <Widget>[
                      OutlinedButton(
                        onPressed: () => _editPreset(context, appState, type: type, preset: preset),
                        child: const Text('Edit'),
                      ),
                      TextButton(
                        onPressed: () => _togglePreset(context, appState, preset),
                        child: Text(preset.isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context, AppState appState) async {
    final data = await showDialog<ChangePasswordResult>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (data == null) return;
    final ok = await appState.changeOwnerPassword(
      currentPassword: data.currentPassword,
      newPassword: data.newPassword,
      confirmPassword: data.confirmPassword,
    );
    if (!context.mounted) return;
    _snack(context, ok ? 'Owner password updated' : 'Failed to update owner password');
  }

  Future<void> _editPreset(
    BuildContext context,
    AppState appState, {
    required String type,
    required DenominationPresetModel? preset,
  }) async {
    final auth = await _askOwnerPassword(context, appState);
    if (!auth) return;
    if (!context.mounted) return;
    final result = await showDialog<DenominationPresetEditorResult>(
      context: context,
      builder: (_) => DenominationPresetEditorDialog(
        parser: appState.moneyParserService,
        defaultType: type,
        initial: preset,
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;
    await appState.createOrUpdatePreset(
      id: preset?.id,
      entryType: result.entryType,
      label: result.label,
      amountCents: result.amountCents,
      sortOrder: result.sortOrder,
      isActive: result.isActive,
    );
  }

  Future<void> _togglePreset(BuildContext context, AppState appState, DenominationPresetModel preset) async {
    final auth = await _askOwnerPassword(context, appState);
    if (!auth) return;
    await appState.setPresetActive(
      id: preset.id,
      isActive: !preset.isActive,
      label: preset.label,
    );
  }

  Future<void> _startNewSession(BuildContext context, AppState appState) async {
    final auth = await _askOwnerPassword(context, appState);
    if (!auth) return;
    if (!context.mounted) return;
    final result = await showDialog<NewSessionDialogResult>(
      context: context,
      builder: (_) => NewSessionDialog(
        parser: appState.moneyParserService,
        defaultStartingBalanceCents: appState.summary.finalTotalCents,
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;
    await appState.startNewSession(
      sessionName: result.sessionName,
      businessDate: result.businessDate,
      startingBalanceCents: result.startingBalanceCents,
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _closeCurrentSession(BuildContext context, AppState appState) async {
    final auth = await _askOwnerPassword(context, appState);
    if (!auth) return;
    await appState.closeCurrentSession();
  }

  Future<void> _reopenSession(BuildContext context, AppState appState) async {
    final auth = await _askOwnerPassword(context, appState);
    if (!auth) return;
    final sessions = await appState.allSessions();
    if (!context.mounted) return;
    final selectedId = await showDialog<int?>(
      context: context,
      builder: (_) => ReopenSessionDialog(sessions: sessions),
    );
    if (selectedId == null) return;
    if (!context.mounted) return;
    await appState.reopenSession(selectedId);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<bool> _askOwnerPassword(BuildContext context, AppState appState) async {
    final password = await showDialog<String?>(
      context: context,
      builder: (_) => const PasswordDialog(),
    );
    if (password == null) return false;
    final ok = await appState.verifyOwnerPassword(password);
    if (!ok) return false;
    return ok;
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
