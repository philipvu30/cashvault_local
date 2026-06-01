import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/denomination_preset_model.dart';
import '../state/app_state.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/denomination_preset_editor_dialog.dart';
import '../widgets/password_dialog.dart';
import '../widgets/settings_section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAuthenticating = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticateOnEntry());
  }

  Future<void> _authenticateOnEntry() async {
    final appState = context.read<AppState>();
    final password = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PasswordDialog(title: 'Owner Password Required'),
    );

    if (!mounted) return;
    if (password == null) {
      Navigator.of(context).pop();
      return;
    }

    final ok = await appState.verifyOwnerPassword(password);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid owner password')));
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isAuthenticated = true;
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating || !_isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, _) {
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
                    'Manage owner password, export defaults, and reusable labels.',
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
                  SettingsSectionCard(
                    title: 'Export Settings',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Last Export Folder: ${appState.lastExportFolder?.isNotEmpty == true ? appState.lastExportFolder : 'Not Set'}',
                        ),
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
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
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
            Expanded(flex: 3, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 6),
        if (presets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No labels yet. Add first label.'),
          ),
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
                  flex: 3,
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
                      TextButton(
                        onPressed: () => _deletePreset(context, appState, preset),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
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
    if (!_isAuthenticated) return;
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
    _snack(context, ok ? 'Owner password updated' : 'Failed to update owner password');
  }

  Future<void> _editPreset(
    BuildContext context,
    AppState appState, {
    required String type,
    required DenominationPresetModel? preset,
  }) async {
    if (!_isAuthenticated) return;
    final result = await showDialog<DenominationPresetEditorResult>(
      context: context,
      builder: (_) => DenominationPresetEditorDialog(
        defaultType: type,
        initial: preset,
      ),
    );
    if (result == null) return;
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
    if (!_isAuthenticated) return;
    await appState.setPresetActive(
      id: preset.id,
      isActive: !preset.isActive,
      label: preset.label,
    );
  }

  Future<void> _deletePreset(BuildContext context, AppState appState, DenominationPresetModel preset) async {
    if (!_isAuthenticated) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Label'),
        content: Text('Delete "${preset.label}" permanently?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await appState.deletePreset(id: preset.id, label: preset.label);
    } catch (e) {
      if (context.mounted) {
        _snack(context, e.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
