import 'package:flutter/material.dart';

class ExportCsvDialogResult {
  const ExportCsvDialogResult({
    required this.filename,
    required this.folder,
  });

  final String filename;
  final String folder;
}

class ExportCsvDialog extends StatefulWidget {
  const ExportCsvDialog({
    super.key,
    required this.initialFilename,
    required this.initialFolder,
    required this.onPickFolder,
  });

  final String initialFilename;
  final String initialFolder;
  final Future<String?> Function() onPickFolder;

  @override
  State<ExportCsvDialog> createState() => _ExportCsvDialogState();
}

class _ExportCsvDialogState extends State<ExportCsvDialog> {
  late TextEditingController _filenameController;
  late TextEditingController _folderController;

  @override
  void initState() {
    super.initState();
    _filenameController = TextEditingController(text: widget.initialFilename);
    _folderController = TextEditingController(text: widget.initialFolder);
  }

  @override
  void dispose() {
    _filenameController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export CSV'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: _filenameController, decoration: const InputDecoration(labelText: 'Filename')),
            const SizedBox(height: 8),
            TextField(controller: _folderController, decoration: const InputDecoration(labelText: 'Export Folder')),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () async {
                  final folder = await widget.onPickFolder();
                  if (folder != null && mounted) {
                    setState(() => _folderController.text = folder);
                  }
                },
                child: const Text('Choose Folder'),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              ExportCsvDialogResult(
                filename: _filenameController.text.trim(),
                folder: _folderController.text.trim(),
              ),
            );
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}
