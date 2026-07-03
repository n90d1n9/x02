import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collaboration_state.dart';
import '../models/document_stats.dart';
import '../states/attachment_provider.dart';
import '../states/collaboration_provider.dart';
import '../states/command_provider.dart';
import '../states/docs_provider.dart';
import '../states/layout_provider.dart';
import '../states/provider.dart';
import '../states/word_count_provider.dart';

import '../widgets/widgets/attachment_panel.dart';
import '../widgets/widgets/command_palette.dart';
import '../widgets/widgets/command_palette_button.dart';
import '../widgets/widgets/comment_button.dart';
import '../widgets/widgets/custom_toolbar.dart';
import '../widgets/widgets/save_indicator.dart';
import '../widgets/widgets/sharing_panel.dart';
import '../widgets/widgets/status_bar.dart';
import '../widgets/widgets/template_gallery_dialog.dart';
import '../widgets/widgets/version_history_panel.dart';
import 'editor_with_ruler.dart';

class DocumentEditorScreen extends ConsumerStatefulWidget {
  const DocumentEditorScreen({super.key});

  @override
  ConsumerState<DocumentEditorScreen> createState() =>
      _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  // A dedicated FocusNode for the KeyboardListener so it can be disposed.
  final _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final keyboard = HardwareKeyboard.instance;
    final isMeta = keyboard.isMetaPressed || keyboard.isControlPressed;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyK when isMeta:
        ref.read(commandPaletteProvider.notifier).state = true;

      case LogicalKeyboardKey.keyS when isMeta:
        // Use the full notifier so the async save path (cloud sync, etc.) runs.
        ref.read(documentProvider.notifier).saveDocument();

      case LogicalKeyboardKey.keyP when isMeta:
        _handlePrint();

      case LogicalKeyboardKey.escape:
        if (ref.read(focusModeProvider)) {
          ref.read(focusModeProvider.notifier).state = false;
        }
    }
  }

  void _handlePrint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing document for printing…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusMode = ref.watch(focusModeProvider);
    final showCommandPalette = ref.watch(commandPaletteProvider);
    final toolbarVisible = ref.watch(toolbarVisibilityProvider);
    final layoutMode = ref.watch(layoutModeProvider);
    final controller = ref.watch(
      documentControllerProvider.select((s) => s.controller),
    );

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: layoutMode != LayoutMode.focus ? const _DocumentAppBar() : null,
        body: Stack(
          children: [
            Column(
              children: [
                if (toolbarVisible && !focusMode)
                  CustomToolbar(controller: controller),
                Expanded(
                  child: _DocumentContent(
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                  ),
                ),
                const _StatusBarSection(),
              ],
            ),
            if (showCommandPalette)
              CommandPalette(
                onDismiss: () =>
                    ref.read(commandPaletteProvider.notifier).state = false,
              ),
          ],
        ),
        floatingActionButton: focusMode ? const _ExitFocusModeButton() : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _DocumentAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _DocumentAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(documentControllerProvider.select((s) => s.title));
    final collabState = ref.watch(collaborationProvider);
    final focusMode = ref.watch(focusModeProvider);
    final isDark = ref.watch(themeProvider);

    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: DocumentTitleEditor(
        title: title,
        onTitleChanged: (value) =>
            ref.read(documentControllerProvider.notifier).updateTitle(value),
      ),
      actions: [
        const SaveIndicator(),
        // Single, canonical comments button (badge + panel wiring live there).
        const CommentsButton(),
        const CommandPaletteButton(),
        _CollaboratorsRow(collabState: collabState),
        _AppBarIconButton(
          icon: Icons.people_outline,
          tooltip: 'Share',
          onPressed: () => _showSharingPanel(context),
        ),
        _AppBarIconButton(
          icon: Icons.history,
          tooltip: 'Version History',
          onPressed: () => _showVersionHistory(context),
        ),
        _AttachmentButton(),
        _MoreMenu(focusMode: focusMode, isDark: isDark),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showSharingPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SharingPanel(),
    );
  }

  void _showVersionHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const VersionHistoryPanel(),
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted action widgets (keeps _DocumentAppBar readable)
// ---------------------------------------------------------------------------

/// Thin wrapper so every app-bar icon button has a consistent size.
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _CollaboratorsRow extends StatelessWidget {
  final CollaborationState collabState;

  const _CollaboratorsRow({required this.collabState});

  @override
  Widget build(BuildContext context) {
    if (!collabState.isConnected || collabState.activeUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final users = collabState.activeUsers;
    final visible = users.take(3).toList();
    final overflow = users.length - visible.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final user in visible)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Tooltip(
                message: user.name,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: user.color,
                  child: Text(
                    user.name[0],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey,
                child: Text(
                  '+$overflow',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentButton extends ConsumerWidget {
  const _AttachmentButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(attachmentsProvider.select((a) => a.length));

    return IconButton(
      icon: Badge(
        label: Text('$count'),
        isLabelVisible: count > 0,
        child: const Icon(Icons.attach_file, size: 20),
      ),
      tooltip: 'Attachments',
      onPressed: () => _showAttachmentsPanel(context),
    );
  }

  void _showAttachmentsPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AttachmentsPanel(),
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  final bool focusMode;
  final bool isDark;

  const _MoreMenu({required this.focusMode, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_MenuAction>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) => _onAction(action, context, ref),
      itemBuilder: (_) => [
        _menuItem(_MenuAction.newFromTemplate, Icons.add, 'New from Template'),
        _menuItem(_MenuAction.uploadFile, Icons.upload_file, 'Upload File'),
        const PopupMenuDivider(),
        _menuItem(_MenuAction.exportJson, Icons.download, 'Export as JSON'),
        _menuItem(
          _MenuAction.toggleFocus,
          focusMode ? Icons.fullscreen_exit : Icons.fullscreen,
          focusMode ? 'Exit Focus Mode' : 'Focus Mode',
        ),
        _menuItem(
          _MenuAction.toggleTheme,
          isDark ? Icons.light_mode : Icons.dark_mode,
          isDark ? 'Light Mode' : 'Dark Mode',
        ),
        const PopupMenuDivider(),
        _menuItem(_MenuAction.docInfo, Icons.info_outline, 'Document Info'),
      ],
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<_MenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _onAction(_MenuAction action, BuildContext context, WidgetRef ref) {
    switch (action) {
      case _MenuAction.newFromTemplate:
        showDialog<void>(
          context: context,
          builder: (_) => const TemplateGalleryDialog(),
        );

      case _MenuAction.uploadFile:
        ref
            .read(attachmentsProvider.notifier)
            .addAttachment('example_document.pdf', 'application/pdf', 1024576);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );

      case _MenuAction.exportJson:
        final json = ref
            .read(documentControllerProvider.notifier)
            .exportToJson();
        Clipboard.setData(ClipboardData(text: json));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exported to clipboard')));

      case _MenuAction.toggleFocus:
        ref.read(focusModeProvider.notifier).state = !focusMode;

      case _MenuAction.toggleTheme:
        ref.read(themeProvider.notifier).state = !isDark;

      case _MenuAction.docInfo:
        final stats = ref.read(wordCountProvider);
        showDialog<void>(
          context: context,
          builder: (_) => _DocumentInfoDialog(stats: stats),
        );
    }
  }
}

enum _MenuAction {
  newFromTemplate,
  uploadFile,
  exportJson,
  toggleFocus,
  toggleTheme,
  docInfo,
}

// ---------------------------------------------------------------------------
// Document info dialog
// ---------------------------------------------------------------------------

class _DocumentInfoDialog extends StatelessWidget {
  final DocumentStats stats;

  const _DocumentInfoDialog({required this.stats});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Document Statistics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('Words', '${stats.words}'),
          _InfoRow('Characters', '${stats.characters}'),
          _InfoRow('Characters (no spaces)', '${stats.charactersNoSpaces}'),
          _InfoRow('Paragraphs', '${stats.paragraphs}'),
          _InfoRow('Reading time', '${stats.readingTime} min'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title editor
// ---------------------------------------------------------------------------

class DocumentTitleEditor extends StatefulWidget {
  final String title;
  final ValueChanged<String> onTitleChanged;

  const DocumentTitleEditor({
    super.key,
    required this.title,
    required this.onTitleChanged,
  });

  @override
  State<DocumentTitleEditor> createState() => _DocumentTitleEditorState();
}

class _DocumentTitleEditorState extends State<DocumentTitleEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(covariant DocumentTitleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only overwrite when the external value changed AND the field isn't
    // currently being edited (avoids clobbering the cursor position).
    if (oldWidget.title != widget.title && _controller.text != widget.title) {
      _controller.value = _controller.value.copyWith(text: widget.title);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.description_outlined, color: colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Untitled Document',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              isDense: true,
            ),
            onChanged: widget.onTitleChanged,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Editor content area
// ---------------------------------------------------------------------------

class _DocumentContent extends ConsumerWidget {
  final FocusNode focusNode;
  final ScrollController scrollController;

  const _DocumentContent({
    required this.focusNode,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusMode = ref.watch(focusModeProvider);
    final controller = ref.watch(
      documentControllerProvider.select((s) => s.controller),
    );

    return ColoredBox(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: focusMode ? 900 : 800),
          margin: EdgeInsets.all(focusMode ? 48 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(focusMode ? 0 : 8),
            boxShadow: focusMode
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(focusMode ? 0 : 8),
            child: EnhancedEditorWithRuler(
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status bar
// ---------------------------------------------------------------------------

class _StatusBarSection extends ConsumerWidget {
  const _StatusBarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusMode = ref.watch(focusModeProvider);
    if (focusMode) return const SizedBox.shrink();

    final stats = ref.watch(wordCountProvider);
    final lastModified = ref.watch(
      documentControllerProvider.select((s) => s.lastModified),
    );

    return StatusBar(stats: stats, lastModified: lastModified);
  }
}

// ---------------------------------------------------------------------------
// Focus-mode FAB
// ---------------------------------------------------------------------------

class _ExitFocusModeButton extends ConsumerWidget {
  const _ExitFocusModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      onPressed: () => ref.read(focusModeProvider.notifier).state = false,
      tooltip: 'Exit Focus Mode',
      child: const Icon(Icons.fullscreen_exit, size: 20),
    );
  }
}
