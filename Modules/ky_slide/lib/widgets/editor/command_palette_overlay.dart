import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/command_palette_action.dart';
import '../../services/command_palette_service.dart';
import 'command_palette_surface.dart';

/// Modal command palette for searching and invoking editor commands.
class CommandPaletteOverlay extends StatefulWidget {
  final List<CommandPaletteAction> actions;
  final VoidCallback onClose;
  final Color accentColor;
  final List<String> recentCommandIds;
  final ValueChanged<CommandPaletteAction>? onCommandInvoked;

  const CommandPaletteOverlay({
    super.key,
    required this.actions,
    required this.onClose,
    this.accentColor = const Color(0xFF38BDF8),
    this.recentCommandIds = const [],
    this.onCommandInvoked,
  });

  @override
  State<CommandPaletteOverlay> createState() => _CommandPaletteOverlayState();
}

/// Owns command palette query, active result, and keyboard interaction state.
class _CommandPaletteOverlayState extends State<CommandPaletteOverlay> {
  late final TextEditingController _queryController;
  late final FocusNode _focusNode;
  var _query = '';
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _focusNode = FocusNode(debugLabel: 'Command palette search');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredActions = CommandPaletteService.filter(
      actions: widget.actions,
      query: _query,
    );
    final sections = CommandPaletteService.sections(
      actions: filteredActions,
      query: _query,
      recentCommandIds: widget.recentCommandIds,
    );
    final selectableActions = CommandPaletteService.flattenSections(sections);
    final selectedIndex = selectableActions.isEmpty
        ? 0
        : _selectedIndex.clamp(0, selectableActions.length - 1);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event, selectableActions),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: 'Command palette',
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: ColoredBox(
                  color: const Color(0xFF020617).withValues(alpha: 0.64),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 72),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = math.min(
                          constraints.maxWidth - 32,
                          660.0,
                        );
                        final maxResultsHeight = _maxResultsHeight(
                          constraints.maxHeight,
                        );

                        return SizedBox(
                          width: math.max(width, 320),
                          child: CommandPaletteSurface(
                            queryController: _queryController,
                            focusNode: _focusNode,
                            query: _query,
                            sections: sections,
                            selectedIndex: selectedIndex,
                            accentColor: widget.accentColor,
                            maxResultsHeight: maxResultsHeight,
                            onQueryChanged: _handleQueryChanged,
                            onClearQuery: _clearQuery,
                            onClose: widget.onClose,
                            onInvoke: _invoke,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(
    KeyEvent event,
    List<CommandPaletteAction> actions,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(actions, 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(actions, -1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (actions.isNotEmpty) {
        final selectedIndex = _selectedIndex.clamp(0, actions.length - 1);
        _invoke(actions[selectedIndex]);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  double _maxResultsHeight(double availableHeight) {
    if (!availableHeight.isFinite) return 390;

    const reservedChromeHeight = 190.0;
    final adaptiveHeight = availableHeight - reservedChromeHeight;

    return adaptiveHeight.clamp(180.0, 390.0).toDouble();
  }

  void _moveSelection(List<CommandPaletteAction> actions, int delta) {
    if (actions.isEmpty) return;

    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(0, actions.length - 1);
    });
  }

  void _handleQueryChanged(String value) {
    setState(() {
      _query = value;
      _selectedIndex = 0;
    });
  }

  void _clearQuery() {
    _queryController.clear();
    _handleQueryChanged('');
    _focusNode.requestFocus();
  }

  void _invoke(CommandPaletteAction action) {
    if (!action.enabled) return;

    action.onInvoke();
    widget.onCommandInvoked?.call(action);
    widget.onClose();
  }
}

@Preview(name: 'Command palette overlay', size: Size(760, 560))
Widget commandPaletteOverlayPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CommandPaletteOverlay(
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
          CommandPaletteAction(
            id: 'preview-present',
            title: 'Start Presenting',
            description: 'Open presenter mode',
            category: 'Present',
            icon: Icons.play_arrow,
            keywords: const ['slideshow'],
            shortcutLabel: 'F5',
            onInvoke: () {},
          ),
        ],
        onClose: () {},
      ),
    ),
  );
}
