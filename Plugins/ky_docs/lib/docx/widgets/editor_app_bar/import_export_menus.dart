import 'package:flutter/material.dart';

class DocumentImportMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final bool enabled;
  final String tooltip;

  const DocumentImportMenu({
    super.key,
    required this.onSelected,
    this.enabled = true,
    this.tooltip = 'Import',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.file_upload),
      tooltip: tooltip,
      enabled: enabled,
      onSelected: enabled ? onSelected : null,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'docx',
          child: Row(
            children: [
              Icon(Icons.description),
              SizedBox(width: 8),
              Text('Import DOCX'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf),
              SizedBox(width: 8),
              Text('Import PDF'),
            ],
          ),
        ),
      ],
    );
  }
}

class DocumentExportMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const DocumentExportMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.file_download),
      tooltip: 'Export',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'docx',
          child: Row(
            children: [
              Icon(Icons.description),
              SizedBox(width: 8),
              Text('Export to DOCX'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf),
              SizedBox(width: 8),
              Text('Export to PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf_advanced',
          child: Row(
            children: [
              Icon(Icons.tune),
              SizedBox(width: 8),
              Text('Export PDF (Advanced)'),
            ],
          ),
        ),
      ],
    );
  }
}
