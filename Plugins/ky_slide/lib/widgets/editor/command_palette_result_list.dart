import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/command_palette_action.dart';
import '../../models/command_palette_section.dart';
import 'command_palette_action_tile.dart';
import 'command_palette_section_header.dart';

/// Scrollable command palette result list that keeps keyboard selection visible.
class CommandPaletteResultList extends StatefulWidget {
  final List<CommandPaletteSection> sections;
  final int selectedIndex;
  final String query;
  final Color accentColor;
  final ValueChanged<CommandPaletteAction> onInvoke;

  const CommandPaletteResultList({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.query,
    required this.accentColor,
    required this.onInvoke,
  });

  @override
  State<CommandPaletteResultList> createState() =>
      _CommandPaletteResultListState();
}

/// State that keeps selected command rows visible during keyboard navigation.
class _CommandPaletteResultListState extends State<CommandPaletteResultList> {
  static const _listTopPadding = 8.0;
  static const _tileEstimatedExtent = 64.0;
  static const _sectionHeaderEstimatedExtent = 24.0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleSelectedActionVisibility();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommandPaletteResultList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.sections != widget.sections) {
      _scheduleSelectedActionVisibility();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: _sectionChildren(),
    );
  }

  int get _actionCount {
    return widget.sections.fold<int>(
      0,
      (count, section) => count + section.actions.length,
    );
  }

  List<Widget> _sectionChildren() {
    final children = <Widget>[];
    var actionIndex = 0;

    for (final section in widget.sections) {
      children.add(CommandPaletteSectionHeader(title: section.title));

      for (final action in section.actions) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: CommandPaletteActionTile(
              action: action,
              selected: actionIndex == widget.selectedIndex,
              accentColor: widget.accentColor,
              query: widget.query,
              onTap: () => widget.onInvoke(action),
            ),
          ),
        );
        actionIndex++;
      }
    }

    return children;
  }

  void _scheduleSelectedActionVisibility() {
    if (_actionCount == 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;

      final visibleOffset =
          _selectedActionTopOffset() -
          (position.viewportDimension - _tileEstimatedExtent) * 0.42;
      final targetOffset = visibleOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      if ((targetOffset - position.pixels).abs() < 0.5) return;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      );
    });
  }

  double _selectedActionTopOffset() {
    final selectedIndex = widget.selectedIndex.clamp(0, _actionCount - 1);
    var actionIndex = 0;
    var offset = _listTopPadding;

    for (final section in widget.sections) {
      offset += _sectionHeaderEstimatedExtent;

      for (var index = 0; index < section.actions.length; index++) {
        if (actionIndex == selectedIndex) return offset;

        offset += _tileEstimatedExtent;
        actionIndex++;
      }
    }

    return offset;
  }
}

@Preview(name: 'Command palette result list', size: Size(620, 320))
Widget commandPaletteResultListPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 540,
          height: 260,
          child: CommandPaletteResultList(
            selectedIndex: 3,
            query: 'slide',
            accentColor: const Color(0xFF38BDF8),
            onInvoke: (_) {},
            sections: [
              CommandPaletteSection(
                title: 'Slides',
                actions: [
                  for (var index = 1; index <= 6; index++)
                    CommandPaletteAction(
                      id: 'preview-slide-$index',
                      title: 'Slide Command $index',
                      description: 'Run slide workflow $index',
                      category: 'Slides',
                      icon: Icons.view_carousel_outlined,
                      keywords: const ['slide'],
                      metadataLabels: const ['Slide'],
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
