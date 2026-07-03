import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/editor_deck_insight.dart';
import '../../models/sidebar_menu_item.dart';
import '../../states/editor_view_provider.dart';
import '../../states/history_provider.dart';
import '../../states/presentation_provider.dart';
import '../../states/sidebar_panel_provider.dart';
import 'editor_top_bar_widgets.dart';

/// Primary app bar for deck identity, quick commands, and presenter launch.
class EditorTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onOpenCommandPalette;
  final VoidCallback onShowThemes;
  final VoidCallback onShowEffects;
  final VoidCallback onPresent;

  const EditorTopBar({
    super.key,
    required this.onOpenCommandPalette,
    required this.onShowThemes,
    required this.onShowEffects,
    required this.onPresent,
  });

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final history = ref.watch(historyProvider);
    final deckInsight = EditorDeckInsight.fromPresentation(presentation);

    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: EditorTopBarTitle(
        title: presentation.title,
        slideIndex: presentation.currentSlideIndex,
        slideCount: presentation.slides.length,
        primaryColor: presentation.theme.primaryColor,
        secondaryColor: presentation.theme.secondaryColor,
        paletteColors: presentation.theme.colorPalette,
        deckInsight: deckInsight,
      ),
      actions: [
        EditorTopBarCommandGroup(
          children: [
            EditorTopBarIconButton(
              icon: Icons.manage_search_outlined,
              tooltip: 'Command Palette (Cmd/Ctrl+K)',
              onPressed: onOpenCommandPalette,
            ),
          ],
        ),
        const SizedBox(width: 8),
        EditorTopBarCommandGroup(
          children: [
            EditorTopBarIconButton(
              icon: Icons.undo,
              tooltip: _historyTooltip('Undo', history.undoLabel, 'Cmd/Ctrl+Z'),
              onPressed: history.canUndo
                  ? () => ref.read(historyProvider.notifier).undo()
                  : null,
            ),
            EditorTopBarIconButton(
              icon: Icons.redo,
              tooltip: _historyTooltip(
                'Redo',
                history.redoLabel,
                'Cmd/Ctrl+Shift+Z',
              ),
              onPressed: history.canRedo
                  ? () => ref.read(historyProvider.notifier).redo()
                  : null,
            ),
          ],
        ),
        const SizedBox(width: 8),
        EditorTopBarCommandGroup(
          children: [
            EditorTopBarIconButton(
              icon: Icons.folder_open_outlined,
              tooltip: 'Import / Export',
              onPressed: () {
                ref.read(slideNavigatorVisibleProvider.notifier).state = true;
                ref.read(activeSidebarMenuProvider.notifier).state =
                    SidebarMenuItem.files;
              },
            ),
            EditorTopBarIconButton(
              icon: Icons.palette_outlined,
              tooltip: 'Themes',
              onPressed: onShowThemes,
            ),
            EditorTopBarIconButton(
              icon: Icons.auto_awesome,
              tooltip: 'Visual Effects',
              onPressed: onShowEffects,
            ),
          ],
        ),
        const SizedBox(width: 8),
        EditorPresentActionButton(onPressed: onPresent),
        const SizedBox(width: 10),
      ],
    );
  }

  String _historyTooltip(String action, String? label, String shortcut) {
    if (label == null || label.isEmpty) {
      return '$action ($shortcut)';
    }

    return '$action: $label ($shortcut)';
  }
}
