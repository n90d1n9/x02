import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/command_provider.dart';
import '../../states/docs_provider.dart';
import '../../states/word_count_provider.dart';
import 'document_info_dialog.dart';

class MoreActionsMenu extends ConsumerWidget {
  const MoreActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolbarVisible = ref.watch(toolbarVisibilityProvider);
    final focusMode = ref.watch(focusModeProvider);
    final isDarkMode = ref.watch(themeProvider);

    return PopupMenuButton<dynamic>(
      icon: const Icon(Icons.more_vert, size: 20),
      itemBuilder: (context) {
        return <PopupMenuEntry<dynamic>>[
          _buildMenuItem(
            icon: Icons.add,
            label: 'New Document',
            onTap: () => _handleNewDocument(ref),
          ),
          const PopupMenuDivider(),
          _buildMenuItem(
            icon: Icons.history,
            label: 'Version History',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.download,
            label: 'Export as JSON',
            onTap: () => _handleExportJson(context, ref),
          ),
          _buildMenuItem(
            icon: Icons.text_fields,
            label: 'Export as Markdown',
            onTap: () => _handleExportMarkdown(context, ref),
          ),
          const PopupMenuDivider(),
          _buildMenuItem(
            icon: focusMode ? Icons.fullscreen_exit : Icons.fullscreen,
            label: focusMode ? 'Exit Focus Mode' : 'Focus Mode',
            onTap: () => _toggleFocusMode(ref),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            label: toolbarVisible ? 'Hide Toolbar' : 'Show Toolbar',
            onTap: () => _toggleToolbar(ref),
          ),
          _buildMenuItem(
            icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
            label: isDarkMode ? 'Light Mode' : 'Dark Mode',
            onTap: () => _toggleTheme(ref),
          ),
          const PopupMenuDivider(),
          _buildMenuItem(
            icon: Icons.info_outline,
            label: 'Document Info',
            onTap: () => _showDocumentInfo(context, ref),
          ),
        ];
      },
    );
  }

  PopupMenuItem<dynamic> _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<dynamic>(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _handleNewDocument(WidgetRef ref) {
    ref.read(documentControllerProvider.notifier).newDocument();
  }

  void _handleExportJson(BuildContext context, WidgetRef ref) {
    final json = ref.read(documentControllerProvider.notifier).exportToJson();
    Clipboard.setData(ClipboardData(text: json));
    _showSnackbar(context, 'JSON copied to clipboard');
  }

  void _handleExportMarkdown(BuildContext context, WidgetRef ref) {
    final md = ref.read(documentControllerProvider.notifier).exportToMarkdown();
    Clipboard.setData(ClipboardData(text: md));
    _showSnackbar(context, 'Markdown copied to clipboard');
  }

  void _toggleFocusMode(WidgetRef ref) {
    ref.read(focusModeProvider.notifier).state = !ref.read(focusModeProvider);
  }

  void _toggleToolbar(WidgetRef ref) {
    ref.read(toolbarVisibilityProvider.notifier).state = !ref.read(
      toolbarVisibilityProvider,
    );
  }

  void _toggleTheme(WidgetRef ref) {
    ref.read(themeProvider.notifier).state = !ref.read(themeProvider);
  }

  void _showDocumentInfo(BuildContext context, WidgetRef ref) {
    final stats = ref.read(wordCountProvider);
    showDialog(
      context: context,
      builder: (context) => DocumentInfoDialog(stats: stats),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
