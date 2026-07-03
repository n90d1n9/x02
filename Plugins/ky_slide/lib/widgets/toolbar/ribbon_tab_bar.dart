import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/editor_ribbon_tab.dart';

/// Horizontal editor ribbon tab selector with optional contextual tabs.
class RibbonTabBar extends StatelessWidget {
  final EditorRibbonTab activeTab;
  final List<EditorRibbonTab> tabs;
  final ValueChanged<EditorRibbonTab> onSelected;

  const RibbonTabBar({
    super.key,
    required this.activeTab,
    required this.tabs,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          for (final tab in tabs)
            _RibbonTabButton(
              tab: tab,
              isActive: tab == activeTab,
              onPressed: () => onSelected(tab),
            ),
        ],
      ),
    );
  }
}

/// Individual ribbon tab trigger styled for the editor chrome.
class _RibbonTabButton extends StatelessWidget {
  final EditorRibbonTab tab;
  final bool isActive;
  final VoidCallback onPressed;

  const _RibbonTabButton({
    required this.tab,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = tab.isContextual
        ? const Color(0xFF38BDF8)
        : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: isActive ? Colors.white : Colors.white60,
          backgroundColor: isActive
              ? accentColor.withValues(alpha: tab.isContextual ? 0.16 : 0.1)
              : Colors.transparent,
          side: tab.isContextual
              ? BorderSide(
                  color: isActive
                      ? accentColor.withValues(alpha: 0.42)
                      : accentColor.withValues(alpha: 0.18),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          tab.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Ribbon tab bar', size: Size(420, 72))
Widget ribbonTabBarPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: RibbonTabBar(
          activeTab: EditorRibbonTab.format,
          tabs: EditorRibbonTabLabel.visibleTabs(hasSelection: true),
          onSelected: (_) {},
        ),
      ),
    ),
  );
}
