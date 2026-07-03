import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../models/document_editing_mode.dart';
import 'find_replace_controller.dart';
import 'find_replace_mode_policy.dart';
import 'find_replace_replacement_preview.dart';
import 'find_replace_summary.dart';

/// Provides a compact document find-and-replace surface for the editor chrome.
class DocxFindReplacePanel extends StatefulWidget {
  static const findFieldKey = ValueKey('docx-find-replace-find-field');
  static const replaceFieldKey = ValueKey('docx-find-replace-replace-field');
  static const matchCaseKey = ValueKey('docx-find-replace-match-case');
  static const wholeWordKey = ValueKey('docx-find-replace-whole-word');
  static const closeButtonKey = ValueKey('docx-find-replace-close');
  static const modeBadgeKey = ValueKey('docx-find-replace-mode-badge');
  static const replacementPreviewKey = ValueKey(
    'docx-find-replace-replacement-preview',
  );

  final QuillController controller;
  final DocumentEditingMode editingMode;
  final VoidCallback? onClose;
  final bool showHeader;

  const DocxFindReplacePanel({
    super.key,
    required this.controller,
    this.editingMode = DocumentEditingMode.editing,
    this.onClose,
    this.showHeader = true,
  });

  @override
  State<DocxFindReplacePanel> createState() => _DocxFindReplacePanelState();
}

/// Owns the lifecycle of the find-and-replace controller used by the panel.
class _DocxFindReplacePanelState extends State<DocxFindReplacePanel> {
  late DocxFindReplaceController _findReplaceController;

  @override
  void initState() {
    super.initState();
    _findReplaceController = DocxFindReplaceController(
      editorController: widget.controller,
    );
  }

  @override
  void didUpdateWidget(covariant DocxFindReplacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _findReplaceController.dispose();
      _findReplaceController = DocxFindReplaceController(
        editorController: widget.controller,
      );
    }
  }

  @override
  void dispose() {
    _findReplaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _findReplaceController,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final policy = DocxFindReplaceModePolicy(
          editingMode: widget.editingMode,
        );
        final replacementSummary = DocxFindReplaceSummary.fromController(
          _findReplaceController,
        );

        return Material(
          color: colorScheme.surfaceContainerHigh,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.18),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showHeader)
                        _FindReplaceHeader(
                          controller: _findReplaceController,
                          policy: policy,
                          onClose: widget.onClose,
                        )
                      else
                        _FindReplaceEmbeddedControls(
                          controller: _findReplaceController,
                          policy: policy,
                        ),
                      const SizedBox(height: 10),
                      _FindReplaceBody(
                        controller: _findReplaceController,
                        policy: policy,
                        compact: compact,
                        onReplaceAll: _showReplaceAllResult,
                      ),
                      if (policy.canReplace &&
                          replacementSummary.shouldShow) ...[
                        const SizedBox(height: 10),
                        DocxFindReplaceReplacementPreview(
                          key: DocxFindReplacePanel.replacementPreviewKey,
                          summary: replacementSummary,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReplaceAllResult(int replacementCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Replaced $replacementCount occurrence(s)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Shows find state and options when the dock already owns the panel title.
class _FindReplaceEmbeddedControls extends StatelessWidget {
  final DocxFindReplaceController controller;
  final DocxFindReplaceModePolicy policy;

  const _FindReplaceEmbeddedControls({
    required this.controller,
    required this.policy,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final status = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MatchStatusBadge(controller: controller),
            if (policy.showsModeBadge) _FindReplaceModeBadge(policy: policy),
          ],
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              status,
              const SizedBox(height: 8),
              _FindOptions(controller: controller),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: status),
            const SizedBox(width: 12),
            _FindOptions(controller: controller),
          ],
        );
      },
    );
  }
}

/// Displays the find-and-replace title, match state, and search options.
class _FindReplaceHeader extends StatelessWidget {
  final DocxFindReplaceController controller;
  final DocxFindReplaceModePolicy policy;
  final VoidCallback? onClose;

  const _FindReplaceHeader({
    required this.controller,
    required this.policy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final titleRow = Row(
          children: [
            Icon(Icons.find_replace, color: colorScheme.primary),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                policy.title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            _MatchStatusBadge(controller: controller),
            if (policy.showsModeBadge) ...[
              const SizedBox(width: 8),
              _FindReplaceModeBadge(policy: policy),
            ],
            if (onClose != null) ...[
              const Spacer(),
              IconButton(
                key: DocxFindReplacePanel.closeButtonKey,
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              const SizedBox(height: 8),
              _FindOptions(controller: controller),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 16),
            _FindOptions(controller: controller),
          ],
        );
      },
    );
  }
}

/// Explains mode-specific limitations in the find-and-replace surface.
class _FindReplaceModeBadge extends StatelessWidget {
  final DocxFindReplaceModePolicy policy;

  const _FindReplaceModeBadge({required this.policy});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = policy.canReplace ? colorScheme.primary : colorScheme.error;

    return Tooltip(
      message: policy.modeDescription,
      child: DecoratedBox(
        key: DocxFindReplacePanel.modeBadgeKey,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            policy.modeLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the current match count in a small status badge.
class _MatchStatusBadge extends StatelessWidget {
  final DocxFindReplaceController controller;

  const _MatchStatusBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNoMatches = controller.hasQuery && !controller.hasMatches;
    final color = hasNoMatches ? colorScheme.error : colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          controller.matchLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Renders search option toggles that mirror familiar word processor behavior.
class _FindOptions extends StatelessWidget {
  final DocxFindReplaceController controller;

  const _FindOptions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        Tooltip(
          message: 'Match case',
          child: FilterChip(
            key: DocxFindReplacePanel.matchCaseKey,
            label: const Text('Aa'),
            selected: controller.matchCase,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: controller.setMatchCase,
          ),
        ),
        Tooltip(
          message: 'Whole word',
          child: FilterChip(
            key: DocxFindReplacePanel.wholeWordKey,
            label: const Text('Word'),
            selected: controller.wholeWord,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: controller.setWholeWord,
          ),
        ),
      ],
    );
  }
}

/// Arranges the find, navigation, replacement, and action controls responsively.
class _FindReplaceBody extends StatelessWidget {
  final DocxFindReplaceController controller;
  final DocxFindReplaceModePolicy policy;
  final bool compact;
  final ValueChanged<int> onReplaceAll;

  const _FindReplaceBody({
    required this.controller,
    required this.policy,
    required this.compact,
    required this.onReplaceAll,
  });

  @override
  Widget build(BuildContext context) {
    final findField = _FindField(controller: controller);
    final navigation = _MatchNavigation(controller: controller);
    final replaceField = _ReplaceField(controller: controller);
    final actions = _ReplaceActions(
      controller: controller,
      onReplaceAll: onReplaceAll,
    );

    if (!policy.canReplace) {
      return Row(
        children: [
          Expanded(child: findField),
          const SizedBox(width: 8),
          navigation,
        ],
      );
    }

    if (compact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: findField),
              const SizedBox(width: 8),
              navigation,
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: replaceField),
              const SizedBox(width: 8),
              actions,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 5, child: findField),
        const SizedBox(width: 8),
        navigation,
        const SizedBox(width: 12),
        Expanded(flex: 4, child: replaceField),
        const SizedBox(width: 8),
        actions,
      ],
    );
  }
}

/// Text input for the active search query.
class _FindField extends StatelessWidget {
  final DocxFindReplaceController controller;

  const _FindField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: DocxFindReplacePanel.findFieldKey,
      controller: controller.findTextController,
      decoration: InputDecoration(
        labelText: 'Find',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: controller.hasQuery
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
                onPressed: controller.clearSearch,
              )
            : null,
      ),
      textInputAction: TextInputAction.search,
      onChanged: controller.performSearch,
    );
  }
}

/// Previous and next controls for cycling through current matches.
class _MatchNavigation extends StatelessWidget {
  final DocxFindReplaceController controller;

  const _MatchNavigation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_FindDirection>(
      showSelectedIcon: false,
      emptySelectionAllowed: true,
      selected: const <_FindDirection>{},
      segments: const [
        ButtonSegment(
          value: _FindDirection.previous,
          icon: Icon(Icons.keyboard_arrow_up),
          tooltip: 'Previous match',
        ),
        ButtonSegment(
          value: _FindDirection.next,
          icon: Icon(Icons.keyboard_arrow_down),
          tooltip: 'Next match',
        ),
      ],
      onSelectionChanged: controller.hasMatches
          ? (selection) {
              if (selection.contains(_FindDirection.previous)) {
                controller.goToPreviousMatch();
              } else if (selection.contains(_FindDirection.next)) {
                controller.goToNextMatch();
              }
            }
          : null,
    );
  }
}

/// Text input for the replacement value.
class _ReplaceField extends StatelessWidget {
  final DocxFindReplaceController controller;

  const _ReplaceField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: DocxFindReplacePanel.replaceFieldKey,
      controller: controller.replaceTextController,
      decoration: const InputDecoration(
        labelText: 'Replace',
        prefixIcon: Icon(Icons.edit_outlined),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      textInputAction: TextInputAction.done,
    );
  }
}

/// Replace action buttons for the active match set.
class _ReplaceActions extends StatelessWidget {
  final DocxFindReplaceController controller;
  final ValueChanged<int> onReplaceAll;

  const _ReplaceActions({required this.controller, required this.onReplaceAll});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        Tooltip(
          message: 'Replace current match',
          child: IconButton.filledTonal(
            icon: const Icon(Icons.swap_horiz),
            onPressed: controller.hasMatches
                ? controller.replaceCurrentMatch
                : null,
          ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.done_all),
          label: const Text('All'),
          onPressed: controller.hasMatches ? _replaceAllMatches : null,
        ),
      ],
    );
  }

  void _replaceAllMatches() {
    final replacementCount = controller.replaceAllMatches();
    if (replacementCount > 0) {
      onReplaceAll(replacementCount);
    }
  }
}

enum _FindDirection { previous, next }
