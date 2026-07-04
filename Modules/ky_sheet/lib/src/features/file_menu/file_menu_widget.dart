import 'package:flutter/material.dart';
import 'package:ky_sheet/src/core/services/file_service.dart';
import 'package:ky_sheet/src/shared/widgets/common_widgets.dart';

/// File Menu widget - completely decoupled from business logic.
/// Uses callbacks to communicate with the rest of the application.
class FileMenu extends StatelessWidget {
  final FileService fileService;
  final VoidCallback onNew;
  final Future<void> Function()? onSave;
  final Future<void> Function()? onSaveAs;
  final Future<void> Function()? onOpen;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final VoidCallback onClose;

  const FileMenu({
    Key? key,
    required this.fileService,
    required this.onNew,
    this.onSave,
    this.onSaveAs,
    this.onOpen,
    this.onExport,
    this.onImport,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Text(
        'File',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      offset: const Offset(0, 40),
      onSelected: (value) => _handleSelection(context, value),
      itemBuilder: (context) => [
        _buildMenuItem(
          icon: Icons.note_add,
          label: 'New',
          value: 'new',
          shortcut: 'Ctrl+N',
        ),
        const MenuSeparator(),
        _buildMenuItem(
          icon: Icons.folder_open,
          label: 'Open...',
          value: 'open',
          shortcut: 'Ctrl+O',
        ),
        const MenuSeparator(),
        _buildMenuItem(
          icon: Icons.save,
          label: 'Save',
          value: 'save',
          shortcut: 'Ctrl+S',
          enabled: fileService.isSaved,
        ),
        _buildMenuItem(
          icon: Icons.save_as,
          label: 'Save As...',
          value: 'save_as',
          shortcut: 'Ctrl+Shift+S',
        ),
        const MenuSeparator(),
        _buildMenuItem(
          icon: Icons.download,
          label: 'Export',
          value: 'export',
          subItems: ['CSV', 'PDF', 'Excel'],
        ),
        _buildMenuItem(
          icon: Icons.upload,
          label: 'Import',
          value: 'import',
          subItems: ['CSV', 'Excel'],
        ),
        const MenuSeparator(),
        _buildMenuItem(
          icon: Icons.close,
          label: 'Close',
          value: 'close',
        ),
      ],
    );
  }

  void _handleSelection(BuildContext context, String value) async {
    switch (value) {
      case 'new':
        _showConfirmDialog(context, 'New Workbook', 
          'Any unsaved changes will be lost.', onNew);
        break;
      case 'open':
        if (onOpen != null) await onOpen!();
        break;
      case 'save':
        if (onSave != null) await onSave!();
        break;
      case 'save_as':
        if (onSaveAs != null) await onSaveAs!();
        break;
      case 'export':
        _showExportDialog(context);
        break;
      case 'import':
        _showImportDialog(context);
        break;
      case 'close':
        onClose();
        break;
    }
  }

  PopupMenuItem<String> _buildMenuItem({
    required IconData icon,
    required String label,
    required String value,
    String? shortcut,
    bool enabled = true,
    List<String>? subItems,
  }) {
    if (subItems != null) {
      return PopupMenuItem<String>(
        enabled: enabled,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
        // In a real implementation, you'd use a submenu library
        // For now, we'll handle this in the selection handler
        value: value,
      );
    }

    return PopupMenuItem<String>(
      enabled: enabled,
      child: MenuShortcutItem(
        icon: icon,
        label: label,
        shortcut: shortcut,
        onTap: () {}, // Handled by onSelected
      ),
      value: value,
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export As', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('Comma-separated values'),
              onTap: () {
                Navigator.pop(ctx);
                if (onExport != null) onExport!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              subtitle: const Text('Portable Document Format'),
              onTap: () {
                Navigator.pop(ctx);
                if (onExport != null) onExport!();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Import From', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('CSV'),
              subtitle: const Text('Comma-separated values'),
              onTap: () {
                Navigator.pop(ctx);
                if (onImport != null) onImport!();
              },
            ),
          ],
        ),
      ),
    );
  }
}
