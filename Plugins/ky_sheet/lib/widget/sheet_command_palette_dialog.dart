import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/sheet_command.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_command_catalog.dart';

class SheetCommandPaletteDialog extends StatefulWidget {
  const SheetCommandPaletteDialog({
    super.key,
    this.commands = SheetCommandCatalog.all,
    this.recentCommands = const [],
    this.availability = const SheetCommandAvailability(),
  });

  final List<SheetCommand> commands;
  final List<SheetCommand> recentCommands;
  final SheetCommandAvailability availability;

  @override
  State<SheetCommandPaletteDialog> createState() =>
      _SheetCommandPaletteDialogState();
}

class _SheetCommandPaletteDialogState extends State<SheetCommandPaletteDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'KySheetCommandPaletteSearch');
  var _query = '';
  var _highlightedIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final visibleCommands = _visibleCommands;
    final highlightedIndex = _clampedHighlightedIndex(visibleCommands.length);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveHighlight(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveHighlight(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _submitHighlighted,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PaletteHeader(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _filterCommands,
              ),
              const Divider(height: 1, color: KySheetColors.gridLine),
              Flexible(
                child: visibleCommands.isEmpty
                    ? const _EmptyCommandResults()
                    : ListView(
                        key: const ValueKey('ky-sheet-command-results'),
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(10),
                        children: [
                          for (final section in sections) ...[
                            _CommandSectionHeader(title: section.title),
                            const SizedBox(height: 6),
                            for (final command in section.commands) ...[
                              _CommandResultTile(
                                command: command,
                                highlighted:
                                    visibleCommands.indexOf(command) ==
                                    highlightedIndex,
                                enabled: widget.availability.isEnabled(command),
                                disabledReason: widget.availability.reasonFor(
                                  command,
                                ),
                                onTap: () => _selectCommand(command),
                              ),
                              const SizedBox(height: 6),
                            ],
                            const SizedBox(height: 4),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_CommandPaletteSection> get _sections {
    final filteredCommands = [
      for (final command in widget.commands)
        if (command.matches(_query)) command,
    ];
    if (filteredCommands.isEmpty) return const [];

    final queryIsEmpty = _query.trim().isEmpty;
    final recentIds = widget.recentCommands
        .map((command) => command.id)
        .toSet();
    final sections = <_CommandPaletteSection>[];

    if (queryIsEmpty && widget.recentCommands.isNotEmpty) {
      sections.add(
        _CommandPaletteSection(
          title: 'Recent',
          commands: widget.recentCommands
              .where((command) => command.matches(_query))
              .toList(),
        ),
      );
    }

    for (final category in SheetCommandCategory.values) {
      final commands = [
        for (final command in filteredCommands)
          if (command.category == category &&
              !(queryIsEmpty && recentIds.contains(command.id)))
            command,
      ];
      if (commands.isNotEmpty) {
        sections.add(
          _CommandPaletteSection(
            title: _categoryLabel(category),
            commands: commands,
          ),
        );
      }
    }

    return sections.where((section) => section.commands.isNotEmpty).toList();
  }

  List<SheetCommand> get _visibleCommands {
    return [
      for (final section in _sections)
        for (final command in section.commands) command,
    ];
  }

  void _filterCommands(String value) {
    setState(() {
      _query = value;
      _highlightedIndex = 0;
    });
  }

  void _moveHighlight(int delta) {
    final commands = _visibleCommands;
    if (commands.isEmpty) return;

    setState(() {
      _highlightedIndex =
          (_clampedHighlightedIndex(commands.length) + delta) % commands.length;
      if (_highlightedIndex < 0) {
        _highlightedIndex += commands.length;
      }
    });
  }

  void _submitHighlighted() {
    final commands = _visibleCommands;
    if (commands.isEmpty) return;

    final command = commands[_clampedHighlightedIndex(commands.length)];
    _selectCommand(command);
  }

  void _selectCommand(SheetCommand command) {
    if (!widget.availability.isEnabled(command)) return;
    Navigator.of(context).pop(command);
  }

  int _clampedHighlightedIndex(int commandCount) {
    if (commandCount == 0) return -1;
    return _highlightedIndex.clamp(0, commandCount - 1);
  }

  String _categoryLabel(SheetCommandCategory category) {
    return switch (category) {
      SheetCommandCategory.file => 'File',
      SheetCommandCategory.edit => 'Edit',
      SheetCommandCategory.view => 'View',
      SheetCommandCategory.data => 'Data',
      SheetCommandCategory.formula => 'Formula',
      SheetCommandCategory.review => 'Review',
      SheetCommandCategory.tools => 'Tools',
    };
  }
}

class _CommandPaletteSection {
  const _CommandPaletteSection({required this.title, required this.commands});

  final String title;
  final List<SheetCommand> commands;
}

class _PaletteHeader extends StatelessWidget {
  const _PaletteHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          const Icon(Icons.manage_search, color: KySheetColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const ValueKey('ky-sheet-command-palette-search'),
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Search commands',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _ShortcutPill(label: 'Ctrl+K'),
        ],
      ),
    );
  }
}

class _CommandSectionHeader extends StatelessWidget {
  const _CommandSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Text(
        title,
        style: const TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CommandResultTile extends StatelessWidget {
  const _CommandResultTile({
    required this.command,
    required this.highlighted,
    required this.enabled,
    required this.disabledReason,
    required this.onTap,
  });

  final SheetCommand command;
  final bool highlighted;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? KySheetColors.text : KySheetColors.mutedText;
    final borderColor = highlighted
        ? KySheetColors.accent
        : KySheetColors.gridLine;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('ky-sheet-command-${command.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(
            color: highlighted
                ? KySheetColors.accentSoft
                : KySheetColors.surfaceMuted,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: enabled
                      ? KySheetColors.accentSoft
                      : KySheetColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  command.icon,
                  size: 18,
                  color: enabled
                      ? KySheetColors.accent
                      : KySheetColors.mutedText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            command.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CategoryPill(label: command.categoryLabel),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      disabledReason ?? command.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? KySheetColors.mutedText
                            : KySheetColors.mutedText.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (command.shortcutLabel != null) ...[
                const SizedBox(width: 10),
                _ShortcutPill(label: command.shortcutLabel!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ShortcutPill extends StatelessWidget {
  const _ShortcutPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyCommandResults extends StatelessWidget {
  const _EmptyCommandResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(22),
      child: Row(
        children: [
          Icon(Icons.search_off, color: KySheetColors.mutedText, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No matching commands',
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
