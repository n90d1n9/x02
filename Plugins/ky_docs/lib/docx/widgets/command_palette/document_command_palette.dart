import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'document_command.dart';
import 'document_command_active_result.dart';
import 'document_command_availability_badge.dart';
import 'document_command_category_option.dart';
import 'document_command_empty_state.dart';
import 'document_command_preview_model.dart';
import 'document_command_preview_panel.dart';
import 'document_command_search.dart';
import 'document_command_section.dart';
import 'document_command_shortcut_chip.dart';
import 'document_command_suggestion_strip.dart';
import 'document_command_suggestions.dart';
import 'document_command_tile_registry.dart';

/// Shows a searchable command surface for document editing actions.
class DocumentCommandPalette extends StatefulWidget {
  static const searchFieldKey = ValueKey('document-command-palette-search');
  static const resultCountKey = ValueKey(
    'document-command-palette-result-count',
  );
  static const commandPreviewKey = ValueKey('document-command-palette-preview');
  static const commandTilePrefixKey = 'document-command-palette-tile';
  static const categoryFilterPrefixKey = 'document-command-category-filter';

  final List<DocumentCommand> commands;
  final ValueChanged<DocumentCommand>? onCommandSelected;

  const DocumentCommandPalette({
    super.key,
    required this.commands,
    this.onCommandSelected,
  });

  static Future<DocumentCommand?> show(
    BuildContext context, {
    required List<DocumentCommand> commands,
  }) {
    return showDialog<DocumentCommand>(
      context: context,
      builder: (context) => DocumentCommandPalette(commands: commands),
    );
  }

  @override
  State<DocumentCommandPalette> createState() => _DocumentCommandPaletteState();
}

class _DocumentCommandPaletteState extends State<DocumentCommandPalette> {
  final _searchController = TextEditingController();
  final _tileRegistry = DocumentCommandTileRegistry();
  String _query = '';
  String _selectedCategoryKey = DocumentCommandCategoryOption.allKey;
  int _activeResultIndex = 0;

  @override
  void didUpdateWidget(covariant DocumentCommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    final availableKeys = _categoryOptions.map((option) => option.key).toSet();
    if (!availableKeys.contains(_selectedCategoryKey)) {
      _selectedCategoryKey = DocumentCommandCategoryOption.allKey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryOptions = _categoryOptions;
    final scopedCommands = _commandsForSelectedCategory;
    final filteredCommands = DocumentCommandSearch.filterAndSort(
      commands: scopedCommands,
      query: _query,
    );
    final sections = DocumentCommandSection.fromCommands(filteredCommands);
    final suggestedCommands = _query.trim().isEmpty
        ? DocumentCommandSuggestions.fromCommands(scopedCommands)
        : const <DocumentCommand>[];
    final selectedCategory = _selectedCategory(categoryOptions);
    final activeResult = DocumentCommandActiveResult.fromCommands(
      filteredCommands,
      preferredIndex: _activeResultIndex,
    );
    _tileRegistry.retainCommandIds(
      filteredCommands.map((command) => command.id),
    );

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _MoveActiveResultIntent.next,
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _MoveActiveResultIntent.previous,
      },
      child: Actions(
        actions: {
          _MoveActiveResultIntent: CallbackAction<_MoveActiveResultIntent>(
            onInvoke: (intent) {
              _moveActiveResult(
                activeResult,
                filteredCommands,
                intent.direction,
              );
              return null;
            },
          ),
        },
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: TextField(
                    key: DocumentCommandPalette.searchFieldKey,
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search commands',
                      prefixIcon: const Icon(Icons.manage_search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: _clearSearch,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                    onChanged: _updateQuery,
                    onSubmitted: (_) => _submitActiveResult(activeResult),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                _CommandCategoryFilterBar(
                  options: categoryOptions,
                  selectedKey: _selectedCategoryKey,
                  onSelected: _selectCategory,
                ),
                DocumentCommandSuggestionStrip(
                  commands: suggestedCommands,
                  onSelected: _selectCommand,
                ),
                _CommandPaletteMeta(count: filteredCommands.length),
                Flexible(
                  child: filteredCommands.isEmpty
                      ? DocumentCommandEmptyState(
                          query: _query,
                          categoryLabel: selectedCategory.label,
                          canClearSearch: _query.trim().isNotEmpty,
                          canResetCategory:
                              _selectedCategoryKey !=
                              DocumentCommandCategoryOption.allKey,
                          onClearSearch: _clearSearch,
                          onResetCategory: _resetCategory,
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            for (final section in sections)
                              _CommandSectionView(
                                section: section,
                                activeCommandId: activeResult.commandId,
                                tileRegistry: _tileRegistry,
                                onSelected: _selectCommand,
                              ),
                          ],
                        ),
                ),
                if (activeResult.hasCommand) ...[
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  DocumentCommandPreviewPanel(
                    key: DocumentCommandPalette.commandPreviewKey,
                    model: DocumentCommandPreviewModel(
                      command: activeResult.command!,
                    ),
                    onSelected: _selectCommand,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectCommand(DocumentCommand command) {
    if (!command.enabled) return;

    if (widget.onCommandSelected != null) {
      widget.onCommandSelected!(command);
      return;
    }

    Navigator.of(context).pop(command);
  }

  void _submitActiveResult(DocumentCommandActiveResult activeResult) {
    final command = activeResult.runnableCommand;
    if (command == null) return;
    _selectCommand(command);
  }

  void _moveActiveResult(
    DocumentCommandActiveResult activeResult,
    List<DocumentCommand> commands,
    _MoveActiveResultDirection direction,
  ) {
    if (!activeResult.canMove) return;

    final nextActiveIndex = switch (direction) {
      _MoveActiveResultDirection.next => activeResult.nextIndex,
      _MoveActiveResultDirection.previous => activeResult.previousIndex,
    };
    final nextCommandId = commands[nextActiveIndex].id;

    setState(() {
      _activeResultIndex = nextActiveIndex;
    });
    _scheduleActiveResultReveal(nextCommandId);
  }

  void _scheduleActiveResultReveal(String? commandId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealActiveResult(commandId);
    });
  }

  void _revealActiveResult(String? commandId) {
    if (!mounted) return;

    final activeContext = _tileRegistry.contextFor(commandId);
    if (activeContext == null) return;

    Scrollable.ensureVisible(
      activeContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
    );
  }

  void _updateQuery(String value) {
    setState(() {
      _query = value;
      _activeResultIndex = 0;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _activeResultIndex = 0;
    });
  }

  List<DocumentCommandCategoryOption> get _categoryOptions {
    return DocumentCommandCategoryOption.fromCommands(widget.commands);
  }

  DocumentCommandCategoryOption _selectedCategory(
    List<DocumentCommandCategoryOption> options,
  ) {
    return options.firstWhere(
      (option) => option.key == _selectedCategoryKey,
      orElse: () => options.first,
    );
  }

  List<DocumentCommand> get _commandsForSelectedCategory {
    if (_selectedCategoryKey == DocumentCommandCategoryOption.allKey) {
      return widget.commands;
    }

    return widget.commands.where((command) {
      final category = command.category.trim().isEmpty
          ? 'General'
          : command.category.trim();
      return category == _selectedCategoryKey;
    }).toList();
  }

  void _selectCategory(String categoryKey) {
    setState(() {
      _selectedCategoryKey = categoryKey;
      _activeResultIndex = 0;
    });
  }

  void _resetCategory() {
    setState(() {
      _selectedCategoryKey = DocumentCommandCategoryOption.allKey;
      _activeResultIndex = 0;
    });
  }
}

/// Filters command palette results by command category.
class _CommandCategoryFilterBar extends StatelessWidget {
  final List<DocumentCommandCategoryOption> options;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const _CommandCategoryFilterBar({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.length <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            for (final option in options) ...[
              ChoiceChip(
                key: Key(
                  '${DocumentCommandPalette.categoryFilterPrefixKey}-${option.key}',
                ),
                label: Text('${option.label} ${option.count}'),
                selected: option.key == selectedKey,
                onSelected: (_) => onSelected(option.key),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Displays result count metadata above the command list.
class _CommandPaletteMeta extends StatelessWidget {
  final int count;

  const _CommandPaletteMeta({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = count == 1 ? '1 command' : '$count commands';

    return Container(
      key: DocumentCommandPalette.resultCountKey,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Renders one command category and its command rows.
class _CommandSectionView extends StatelessWidget {
  final DocumentCommandSection section;
  final String? activeCommandId;
  final DocumentCommandTileRegistry tileRegistry;
  final ValueChanged<DocumentCommand> onSelected;

  const _CommandSectionView({
    required this.section,
    required this.activeCommandId,
    required this.tileRegistry,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommandSectionHeader(section: section),
          for (final command in section.commands)
            _CommandTile(
              key: tileRegistry.keyFor(command.id),
              command: command,
              active: command.id == activeCommandId,
              onSelected: onSelected,
            ),
        ],
      ),
    );
  }
}

/// Labels one category inside the command palette.
class _CommandSectionHeader extends StatelessWidget {
  final DocumentCommandSection section;

  const _CommandSectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = section.commands.length;
    final countLabel = count == 1 ? '1' : '$count';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            section.category,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            countLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final DocumentCommand command;
  final bool active;
  final ValueChanged<DocumentCommand> onSelected;

  const _CommandTile({
    super.key,
    required this.command,
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor = command.enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.42);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        key: Key(
          '${DocumentCommandPalette.commandTilePrefixKey}-${command.id}',
        ),
        enabled: command.enabled,
        selected: active,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.28),
        selectedColor: command.enabled
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(command.icon, color: contentColor),
        title: Text(
          command.title,
          style: TextStyle(fontWeight: FontWeight.w700, color: contentColor),
        ),
        subtitle: Text(command.subtitle),
        trailing: _CommandTileTrailing(command: command),
        onTap: command.enabled ? () => onSelected(command) : null,
      ),
    );
  }
}

class _CommandTileTrailing extends StatelessWidget {
  final DocumentCommand command;

  const _CommandTileTrailing({required this.command});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (!command.enabled)
        DocumentCommandAvailabilityBadge(
          label: command.disabledLabel ?? 'Unavailable',
          reason: command.disabledReason,
          icon: command.disabledIcon ?? Icons.info_outline,
        ),
      if (command.shortcut != null) ...[
        if (!command.enabled) const SizedBox(width: 8),
        DocumentCommandShortcutChip(shortcut: command.shortcut!),
      ],
    ];

    if (children.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

enum _MoveActiveResultDirection { previous, next }

class _MoveActiveResultIntent extends Intent {
  static const previous = _MoveActiveResultIntent(
    _MoveActiveResultDirection.previous,
  );
  static const next = _MoveActiveResultIntent(_MoveActiveResultDirection.next);

  final _MoveActiveResultDirection direction;

  const _MoveActiveResultIntent(this.direction);
}
