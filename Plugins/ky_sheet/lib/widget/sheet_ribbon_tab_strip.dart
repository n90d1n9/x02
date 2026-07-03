import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';
import 'sheet_ribbon_overflow_scroller.dart';
import 'sheet_ribbon_tab.dart';

/// Keyboard-aware ribbon tab selector for switching between command groups.
class SheetRibbonTabStrip extends StatefulWidget {
  const SheetRibbonTabStrip({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  final SheetRibbonTab selectedTab;
  final ValueChanged<SheetRibbonTab> onSelected;

  @override
  State<SheetRibbonTabStrip> createState() => _SheetRibbonTabStripState();
}

/// Coordinates focus, keyboard navigation, and selected-tab visibility.
class _SheetRibbonTabStripState extends State<SheetRibbonTabStrip> {
  final _focusNode = FocusNode(debugLabel: 'SheetRibbonTabStrip');
  final _scrollController = ScrollController();
  final _tabKeys = {
    for (final spec in SheetRibbonTabCatalog.all) spec.tab: GlobalKey(),
  };
  bool _visibilityUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleSelectedTabVisibility();
  }

  @override
  void didUpdateWidget(covariant SheetRibbonTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      _scheduleSelectedTabVisibility();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);

    return Focus(
      key: const ValueKey('ky-sheet-ribbon-tab-strip-focus'),
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: SizedBox(
        height: density.tabStripHeight,
        child: SheetRibbonOverflowScroller(
          controller: _scrollController,
          fadeWidth: density.tabOverflowFadeWidth,
          child: Row(
            children: [
              for (final spec in SheetRibbonTabCatalog.all)
                KeyedSubtree(
                  key: _tabKeys[spec.tab],
                  child: _RibbonTabButton(
                    key: ValueKey('ky-sheet-ribbon-tab-${spec.tab.name}'),
                    spec: spec,
                    selected: widget.selectedTab == spec.tab,
                    onPressed: () {
                      _focusNode.requestFocus();
                      widget.onSelected(spec.tab);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final tabs = SheetRibbonTabCatalog.all.map((spec) => spec.tab).toList();
    final currentIndex = tabs.indexOf(widget.selectedTab);
    if (currentIndex < 0) return KeyEventResult.ignored;

    final nextTab = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => tabs[(currentIndex + 1) % tabs.length],
      LogicalKeyboardKey.arrowLeft =>
        tabs[(currentIndex - 1 + tabs.length) % tabs.length],
      LogicalKeyboardKey.home => tabs.first,
      LogicalKeyboardKey.end => tabs.last,
      _ => null,
    };

    if (nextTab == null) return KeyEventResult.ignored;
    widget.onSelected(nextTab);
    return KeyEventResult.handled;
  }

  void _scheduleSelectedTabVisibility() {
    if (_visibilityUpdateScheduled) return;
    _visibilityUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityUpdateScheduled = false;
      if (!mounted) return;

      final tabContext = _tabKeys[widget.selectedTab]?.currentContext;
      if (tabContext == null) return;

      Scrollable.ensureVisible(
        tabContext,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    });
  }
}

/// Compact ribbon tab pill with selected and hover feedback.
class _RibbonTabButton extends StatelessWidget {
  const _RibbonTabButton({
    super.key,
    required this.spec,
    required this.selected,
    required this.onPressed,
  });

  final SheetRibbonTabSpec spec;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final radius = BorderRadius.circular(density.tabButtonRadius);

    return Padding(
      padding: EdgeInsets.only(right: density.tabButtonSpacing),
      child: Tooltip(
        message: '${spec.label} ribbon',
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              height: density.tabButtonHeight,
              constraints: BoxConstraints(minWidth: density.tabButtonMinWidth),
              padding: density.tabButtonPadding,
              decoration: BoxDecoration(
                color: selected
                    ? KySheetColors.accentSoft
                    : KySheetColors.surface,
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      ? KySheetColors.accent
                      : KySheetColors.gridLine,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    spec.icon,
                    size: density.tabButtonIconSize,
                    color: selected
                        ? KySheetColors.accent
                        : KySheetColors.mutedText,
                  ),
                  SizedBox(width: density.tabButtonLabelGap),
                  Text(
                    spec.label,
                    style: TextStyle(
                      color: selected
                          ? KySheetColors.accent
                          : KySheetColors.text,
                      fontSize: density.tabButtonFontSize,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
