import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/command_palette_action.dart';
import '../../models/command_palette_section.dart';
import 'command_palette_empty_state.dart';
import 'command_palette_header.dart';
import 'command_palette_result_list.dart';
import 'command_palette_search_field.dart';
import 'command_palette_status_footer.dart';

/// Visual shell for the command palette search field and results list.
class CommandPaletteSurface extends StatelessWidget {
  final TextEditingController queryController;
  final FocusNode focusNode;
  final String query;
  final List<CommandPaletteSection> sections;
  final int selectedIndex;
  final Color accentColor;
  final double maxResultsHeight;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback onClose;
  final ValueChanged<CommandPaletteAction> onInvoke;

  const CommandPaletteSurface({
    super.key,
    required this.queryController,
    required this.focusNode,
    required this.query,
    required this.sections,
    required this.selectedIndex,
    required this.accentColor,
    this.maxResultsHeight = 390,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onClose,
    required this.onInvoke,
  });

  @override
  Widget build(BuildContext context) {
    final resultCount = _resultCount();
    final visibleSelectedIndex = resultCount == 0
        ? 0
        : selectedIndex.clamp(0, resultCount - 1).toInt();

    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.36),
              blurRadius: 34,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommandPaletteHeader(accentColor: accentColor, onClose: onClose),
            CommandPaletteSearchField(
              controller: queryController,
              focusNode: focusNode,
              value: query,
              accentColor: accentColor,
              onChanged: onQueryChanged,
              onClear: onClearQuery,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxResultsHeight),
              child: sections.isEmpty
                  ? CommandPaletteEmptyState(
                      query: query,
                      accentColor: accentColor,
                      onClearQuery: onClearQuery,
                    )
                  : CommandPaletteResultList(
                      sections: sections,
                      selectedIndex: visibleSelectedIndex,
                      query: query,
                      accentColor: accentColor,
                      onInvoke: onInvoke,
                    ),
            ),
            CommandPaletteStatusFooter(
              resultCount: resultCount,
              selectedIndex: visibleSelectedIndex,
              query: query,
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  int _resultCount() {
    return sections.fold<int>(
      0,
      (count, section) => count + section.actions.length,
    );
  }
}

@Preview(name: 'Command palette surface', size: Size(700, 460))
Widget commandPaletteSurfacePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 620,
          child: CommandPaletteSurface(
            queryController: TextEditingController(text: 'duplicate'),
            focusNode: FocusNode(),
            query: 'duplicate',
            selectedIndex: 0,
            accentColor: const Color(0xFF38BDF8),
            onQueryChanged: (_) {},
            onClearQuery: () {},
            onClose: () {},
            onInvoke: (_) {},
            sections: [
              CommandPaletteSection(
                title: 'Recent',
                actions: [
                  CommandPaletteAction(
                    id: 'preview-slide-board',
                    title: 'Open Slide Board',
                    description: 'Review and organize slides',
                    category: 'View',
                    icon: Icons.view_module_outlined,
                    keywords: const ['sorter', 'slides'],
                    metadataLabels: const ['Overlay'],
                    onInvoke: () {},
                  ),
                ],
              ),
              CommandPaletteSection(
                title: 'Object',
                actions: [
                  CommandPaletteAction(
                    id: 'preview-duplicate',
                    title: 'Duplicate Selected Object',
                    description: 'Create a copy of the selected object',
                    category: 'Object',
                    icon: Icons.copy_all_outlined,
                    keywords: const ['duplicate', 'object'],
                    shortcutLabel: 'Cmd/Ctrl+D',
                    metadataLabels: const ['Selected'],
                    onInvoke: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
