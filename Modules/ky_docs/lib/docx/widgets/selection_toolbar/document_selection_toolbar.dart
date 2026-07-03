import 'package:flutter/material.dart';

import '../../models/document_editing_mode.dart';
import 'document_selection_toolbar_policy.dart';

/// Renders quick document actions for the currently selected text range.
class DocumentSelectionToolbar extends StatelessWidget {
  static const toolbarKey = ValueKey('document-selection-toolbar');
  static const selectedCountKey = ValueKey('document-selection-count');
  static const modeBadgeKey = ValueKey('document-selection-mode-badge');
  static const copyActionKey = ValueKey('document-selection-copy-action');
  static const underlineActionKey = ValueKey(
    'document-selection-underline-action',
  );
  static const quoteActionKey = ValueKey('document-selection-quote-action');
  static const clearFormattingActionKey = ValueKey(
    'document-selection-clear-formatting-action',
  );

  final bool visible;
  final int selectedCharacterCount;
  final DocumentEditingMode editingMode;
  final bool boldActive;
  final bool italicActive;
  final bool underlineActive;
  final bool quoteActive;
  final bool aiProcessing;
  final VoidCallback? onCopy;
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUnderline;
  final VoidCallback? onQuote;
  final VoidCallback? onClearFormatting;
  final VoidCallback? onComment;
  final VoidCallback? onImprove;
  final VoidCallback? onSuggestChange;

  const DocumentSelectionToolbar({
    super.key,
    required this.visible,
    required this.selectedCharacterCount,
    this.editingMode = DocumentEditingMode.editing,
    this.boldActive = false,
    this.italicActive = false,
    this.underlineActive = false,
    this.quoteActive = false,
    this.aiProcessing = false,
    this.onCopy,
    this.onBold,
    this.onItalic,
    this.onUnderline,
    this.onQuote,
    this.onClearFormatting,
    this.onComment,
    this.onImprove,
    this.onSuggestChange,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final policy = DocumentSelectionToolbarPolicy(editingMode: editingMode);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: DecoratedBox(
            key: toolbarKey,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.64),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SelectedCountBadge(count: selectedCharacterCount),
                  const SizedBox(width: 6),
                  if (policy.showsModeBadge) ...[
                    _SelectionModeBadge(policy: policy),
                    const SizedBox(width: 6),
                  ],
                  _SelectionToolbarAction(
                    key: copyActionKey,
                    icon: Icons.content_copy_outlined,
                    tooltip: 'Copy',
                    onPressed: onCopy,
                  ),
                  if (policy.showsFormattingActions) ...[
                    const _SelectionToolbarDivider(),
                    _SelectionToolbarAction(
                      icon: Icons.format_bold,
                      tooltip: 'Bold',
                      active: boldActive,
                      onPressed: onBold,
                    ),
                    _SelectionToolbarAction(
                      icon: Icons.format_italic,
                      tooltip: 'Italic',
                      active: italicActive,
                      onPressed: onItalic,
                    ),
                    _SelectionToolbarAction(
                      key: underlineActionKey,
                      icon: Icons.format_underlined,
                      tooltip: 'Underline',
                      active: underlineActive,
                      onPressed: onUnderline,
                    ),
                    _SelectionToolbarAction(
                      key: quoteActionKey,
                      icon: Icons.format_quote,
                      tooltip: 'Quote',
                      active: quoteActive,
                      onPressed: onQuote,
                    ),
                    _SelectionToolbarAction(
                      key: clearFormattingActionKey,
                      icon: Icons.format_clear,
                      tooltip: 'Clear formatting',
                      onPressed: onClearFormatting,
                    ),
                  ],
                  if (policy.showsReviewActions) ...[
                    const _SelectionToolbarDivider(),
                    _SelectionToolbarAction(
                      icon: Icons.mode_comment_outlined,
                      tooltip: 'Comment',
                      onPressed: onComment,
                    ),
                    _SelectionToolbarAction(
                      icon: aiProcessing
                          ? Icons.hourglass_top
                          : Icons.auto_fix_high_outlined,
                      tooltip: aiProcessing ? 'Improving selection' : 'Improve',
                      onPressed: aiProcessing ? null : onImprove,
                    ),
                    _SelectionToolbarAction(
                      icon: Icons.rule_folder_outlined,
                      tooltip: 'Suggest change',
                      onPressed: onSuggestChange,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the active review or read-only mode for the current selection.
class _SelectionModeBadge extends StatelessWidget {
  final DocumentSelectionToolbarPolicy policy;

  const _SelectionModeBadge({required this.policy});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = policy.editingMode == DocumentEditingMode.suggesting
        ? colorScheme.primary
        : colorScheme.secondary;

    return Tooltip(
      message: policy.modeTooltip,
      child: Container(
        key: DocumentSelectionToolbar.modeBadgeKey,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(policy.modeIcon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              policy.modeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays how many characters are covered by the active selection.
class _SelectedCountBadge extends StatelessWidget {
  final int count;

  const _SelectedCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = count == 1 ? '1 selected' : '$count selected';

    return Container(
      key: DocumentSelectionToolbar.selectedCountKey,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Renders one compact action in the contextual selection toolbar.
class _SelectionToolbarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onPressed;

  const _SelectionToolbarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(36),
          minimumSize: const Size.square(36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: active
              ? colorScheme.primaryContainer.withValues(alpha: 0.86)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          foregroundColor: active
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
            alpha: 0.42,
          ),
          disabledBackgroundColor: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

/// Separates formatting and review command groups inside the toolbar.
class _SelectionToolbarDivider extends StatelessWidget {
  const _SelectionToolbarDivider();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 22,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}
