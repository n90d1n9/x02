import 'package:flutter/material.dart';

import '../model/sheet_shortcut.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_shortcut_catalog.dart';
import 'sheet_shortcut_category_filter.dart';
import 'sheet_shortcut_hint.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel that helps users discover supported spreadsheet shortcuts.
class SheetShortcutsPanel extends StatefulWidget {
  const SheetShortcutsPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<SheetShortcutsPanel> createState() => _SheetShortcutsPanelState();
}

/// State holder for shortcut guide filtering.
class _SheetShortcutsPanelState extends State<SheetShortcutsPanel> {
  final _searchController = TextEditingController();
  var _query = '';
  SheetShortcutCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = SheetShortcutCatalog.search(
      _query,
      category: _selectedCategory,
    );
    final groups = SheetShortcutCatalog.groupByCategory(shortcuts);

    return SheetSidebarPanelSurface(
      icon: Icons.keyboard_alt_outlined,
      title: 'Shortcuts',
      subtitle: 'Keyboard reference',
      trailing: SheetSidebarPanelCountBadge(count: shortcuts.length),
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              key: const ValueKey('ky-sheet-shortcuts-search'),
              controller: _searchController,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Search shortcuts',
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SheetShortcutCategoryFilter(
              selectedCategory: _selectedCategory,
              onChanged: (category) =>
                  setState(() => _selectedCategory = category),
            ),
          ),
          Expanded(
            child: shortcuts.isEmpty
                ? const _EmptyShortcuts()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                    children: [
                      for (final entry in groups.entries) ...[
                        _ShortcutSectionHeader(category: entry.key),
                        const SizedBox(height: 8),
                        for (final shortcut in entry.value) ...[
                          _ShortcutTile(
                            key: ValueKey('ky-sheet-shortcut-${shortcut.id}'),
                            shortcut: shortcut,
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Section label for a shortcut category.
class _ShortcutSectionHeader extends StatelessWidget {
  const _ShortcutSectionHeader({required this.category});

  final SheetShortcutCategory category;

  @override
  Widget build(BuildContext context) {
    return Text(
      category.label,
      style: const TextStyle(
        color: KySheetColors.mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

/// Repeated shortcut row used by the shortcut guide.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({super.key, required this.shortcut});

  final SheetShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: KySheetColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(shortcut.icon, color: KySheetColors.accent, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortcut.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    shortcut.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SheetShortcutHint(label: shortcut.shortcutLabel, dense: false),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown when no shortcut matches the search query.
class _EmptyShortcuts extends StatelessWidget {
  const _EmptyShortcuts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: KySheetColors.mutedText, size: 28),
            SizedBox(height: 8),
            Text(
              'No shortcuts found',
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
