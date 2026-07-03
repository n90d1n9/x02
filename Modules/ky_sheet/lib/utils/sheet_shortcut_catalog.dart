import 'package:flutter/material.dart';

import '../model/sheet_shortcut.dart';

/// Catalog of keyboard shortcuts currently supported by the spreadsheet UI.
class SheetShortcutCatalog {
  const SheetShortcutCatalog._();

  static const all = <SheetShortcut>[
    SheetShortcut(
      id: 'edit.undo',
      title: 'Undo',
      description: 'Revert the latest spreadsheet edit.',
      category: SheetShortcutCategory.editing,
      icon: Icons.undo,
      shortcutLabel: SheetShortcutLabels.undo,
      keywords: ['history', 'revert'],
    ),
    SheetShortcut(
      id: 'edit.redo',
      title: 'Redo',
      description: 'Restore the latest undone spreadsheet edit.',
      category: SheetShortcutCategory.editing,
      icon: Icons.redo,
      shortcutLabel: SheetShortcutLabels.redo,
      keywords: ['history', 'restore'],
    ),
    SheetShortcut(
      id: 'format.bold',
      title: 'Bold',
      description: 'Toggle bold formatting on the selected cells.',
      category: SheetShortcutCategory.editing,
      icon: Icons.format_bold,
      shortcutLabel: SheetShortcutLabels.bold,
      keywords: ['format', 'text', 'font'],
    ),
    SheetShortcut(
      id: 'format.italic',
      title: 'Italic',
      description: 'Toggle italic formatting on the selected cells.',
      category: SheetShortcutCategory.editing,
      icon: Icons.format_italic,
      shortcutLabel: SheetShortcutLabels.italic,
      keywords: ['format', 'text', 'font'],
    ),
    SheetShortcut(
      id: 'format.underline',
      title: 'Underline',
      description: 'Toggle underline formatting on the selected cells.',
      category: SheetShortcutCategory.editing,
      icon: Icons.format_underlined,
      shortcutLabel: SheetShortcutLabels.underline,
      keywords: ['format', 'text', 'font'],
    ),
    SheetShortcut(
      id: 'edit.cell',
      title: 'Edit Cell',
      description: 'Start editing the active cell without replacing its value.',
      category: SheetShortcutCategory.editing,
      icon: Icons.edit,
      shortcutLabel: SheetShortcutLabels.editCell,
      keywords: ['formula', 'value'],
    ),
    SheetShortcut(
      id: 'edit.copy',
      title: 'Copy',
      description: 'Copy the current selection to the clipboard.',
      category: SheetShortcutCategory.editing,
      icon: Icons.content_copy,
      shortcutLabel: SheetShortcutLabels.copy,
      keywords: ['clipboard'],
    ),
    SheetShortcut(
      id: 'edit.cut',
      title: 'Cut',
      description: 'Move the current selection through the clipboard.',
      category: SheetShortcutCategory.editing,
      icon: Icons.content_cut,
      shortcutLabel: SheetShortcutLabels.cut,
      keywords: ['clipboard'],
    ),
    SheetShortcut(
      id: 'edit.paste',
      title: 'Paste',
      description: 'Paste clipboard values into the active selection.',
      category: SheetShortcutCategory.editing,
      icon: Icons.content_paste,
      shortcutLabel: SheetShortcutLabels.paste,
      keywords: ['clipboard'],
    ),
    SheetShortcut(
      id: 'edit.clearSelection',
      title: 'Clear Selection',
      description: 'Clear values from the selected cells.',
      category: SheetShortcutCategory.editing,
      icon: Icons.backspace_outlined,
      shortcutLabel: SheetShortcutLabels.clearSelection,
      keywords: ['delete', 'backspace', 'values'],
    ),
    SheetShortcut(
      id: 'navigation.moveSelection',
      title: 'Move Selection',
      description: 'Move the active selection one cell at a time.',
      category: SheetShortcutCategory.navigation,
      icon: Icons.open_with,
      shortcutLabel: SheetShortcutLabels.moveSelection,
      keywords: ['cell', 'cursor'],
    ),
    SheetShortcut(
      id: 'navigation.extendSelection',
      title: 'Extend Selection',
      description: 'Expand the active range while moving across cells.',
      category: SheetShortcutCategory.navigation,
      icon: Icons.select_all,
      shortcutLabel: SheetShortcutLabels.extendSelection,
      keywords: ['range', 'highlight'],
    ),
    SheetShortcut(
      id: 'navigation.moveDown',
      title: 'Move Down',
      description: 'Move the selection to the next row.',
      category: SheetShortcutCategory.navigation,
      icon: Icons.keyboard_return,
      shortcutLabel: SheetShortcutLabels.moveDown,
      keywords: ['row', 'enter'],
    ),
    SheetShortcut(
      id: 'navigation.moveUp',
      title: 'Move Up',
      description: 'Move the selection to the previous row.',
      category: SheetShortcutCategory.navigation,
      icon: Icons.north,
      shortcutLabel: SheetShortcutLabels.moveUp,
      keywords: ['row', 'enter'],
    ),
    SheetShortcut(
      id: 'navigation.moveRight',
      title: 'Move Right',
      description: 'Move the selection to the next column.',
      category: SheetShortcutCategory.navigation,
      icon: Icons.east,
      shortcutLabel: SheetShortcutLabels.moveRight,
      keywords: ['column', 'tab'],
    ),
    SheetShortcut(
      id: 'navigation.moveLeft',
      title: 'Move Left',
      description: 'Move the selection to the previous column.',
      category: SheetShortcutCategory.navigation,
      icon: Icons.west,
      shortcutLabel: SheetShortcutLabels.moveLeft,
      keywords: ['column', 'tab'],
    ),
    SheetShortcut(
      id: 'tools.findReplace',
      title: 'Find & Replace',
      description: 'Open the find and replace sidebar panel.',
      category: SheetShortcutCategory.tools,
      icon: Icons.find_replace,
      shortcutLabel: SheetShortcutLabels.findReplace,
      keywords: ['search', 'replace'],
    ),
    SheetShortcut(
      id: 'tools.replace',
      title: 'Replace',
      description: 'Open Find & Replace with the replace field focused.',
      category: SheetShortcutCategory.tools,
      icon: Icons.find_replace,
      shortcutLabel: SheetShortcutLabels.replace,
      keywords: ['find', 'search', 'replace'],
    ),
    SheetShortcut(
      id: 'tools.sortFilter',
      title: 'Sort & Filter',
      description: 'Open sorting and column filter controls.',
      category: SheetShortcutCategory.tools,
      icon: Icons.filter_alt,
      shortcutLabel: SheetShortcutLabels.sortFilter,
      keywords: ['filter', 'sort', 'criteria'],
    ),
    SheetShortcut(
      id: 'tools.commandPalette',
      title: 'Command Palette',
      description: 'Search spreadsheet commands and panels.',
      category: SheetShortcutCategory.tools,
      icon: Icons.manage_search,
      shortcutLabel: SheetShortcutLabels.commandPalette,
      keywords: ['actions', 'launcher'],
    ),
    SheetShortcut(
      id: 'tools.shortcuts',
      title: 'Shortcut Guide',
      description: 'Open the keyboard shortcut reference sidebar.',
      category: SheetShortcutCategory.tools,
      icon: Icons.keyboard_alt_outlined,
      shortcutLabel: SheetShortcutLabels.shortcuts,
      keywords: ['help', 'guide', 'keyboard', 'hotkeys'],
    ),
    SheetShortcut(
      id: 'tools.help',
      title: 'Help',
      description: 'Open the shortcut guide with the standard help key.',
      category: SheetShortcutCategory.tools,
      icon: Icons.help_outline,
      shortcutLabel: SheetShortcutLabels.help,
      keywords: ['f1', 'guide', 'keyboard', 'shortcuts'],
    ),
    SheetShortcut(
      id: 'tools.closePanel',
      title: 'Close Panel',
      description: 'Dismiss the active sidebar panel and return to the sheet.',
      category: SheetShortcutCategory.tools,
      icon: Icons.keyboard_hide,
      shortcutLabel: SheetShortcutLabels.closePanel,
      keywords: ['sidebar', 'dismiss', 'escape'],
    ),
    SheetShortcut(
      id: 'sheets.previousVisible',
      title: 'Previous Visible Sheet',
      description: 'Switch to the previous visible sheet tab.',
      category: SheetShortcutCategory.sheets,
      icon: Icons.navigate_before,
      shortcutLabel: SheetShortcutLabels.previousVisibleSheet,
      keywords: ['tab', 'workbook'],
    ),
    SheetShortcut(
      id: 'sheets.nextVisible',
      title: 'Next Visible Sheet',
      description: 'Switch to the next visible sheet tab.',
      category: SheetShortcutCategory.sheets,
      icon: Icons.navigate_next,
      shortcutLabel: SheetShortcutLabels.nextVisibleSheet,
      keywords: ['tab', 'workbook'],
    ),
    SheetShortcut(
      id: 'sheets.previousVisibleMac',
      title: 'Previous Sheet on macOS',
      description: 'Use the macOS tab navigation alternate shortcut.',
      category: SheetShortcutCategory.sheets,
      icon: Icons.keyboard_double_arrow_left,
      shortcutLabel: SheetShortcutLabels.previousVisibleSheetMac,
      keywords: ['tab', 'workbook', 'mac'],
    ),
    SheetShortcut(
      id: 'sheets.nextVisibleMac',
      title: 'Next Sheet on macOS',
      description: 'Use the macOS tab navigation alternate shortcut.',
      category: SheetShortcutCategory.sheets,
      icon: Icons.keyboard_double_arrow_right,
      shortcutLabel: SheetShortcutLabels.nextVisibleSheetMac,
      keywords: ['tab', 'workbook', 'mac'],
    ),
  ];

  static List<SheetShortcut> search(
    String query, {
    SheetShortcutCategory? category,
  }) {
    return all
        .where((shortcut) => category == null || shortcut.category == category)
        .where((shortcut) => shortcut.matches(query))
        .toList(growable: false);
  }

  static Map<SheetShortcutCategory, List<SheetShortcut>> groupByCategory(
    Iterable<SheetShortcut> shortcuts,
  ) {
    final groups = {
      for (final category in SheetShortcutCategory.values)
        category: <SheetShortcut>[],
    };

    for (final shortcut in shortcuts) {
      groups[shortcut.category]!.add(shortcut);
    }

    return {
      for (final entry in groups.entries)
        if (entry.value.isNotEmpty) entry.key: List.unmodifiable(entry.value),
    };
  }
}
