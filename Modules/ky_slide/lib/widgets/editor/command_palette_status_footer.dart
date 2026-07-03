import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'command_palette_keyboard_hints.dart';

/// Compact status strip that summarizes command palette search results.
class CommandPaletteStatusFooter extends StatelessWidget {
  final int resultCount;
  final int selectedIndex;
  final String query;
  final Color accentColor;

  const CommandPaletteStatusFooter({
    super.key,
    required this.resultCount,
    required this.selectedIndex,
    required this.query,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final hasResults = resultCount > 0;
    final safeSelectedIndex = hasResults
        ? selectedIndex.clamp(0, resultCount - 1).toInt()
        : 0;
    final selectedLabel = hasResults
        ? '${safeSelectedIndex + 1} of $resultCount'
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHints = constraints.maxWidth < 560;

        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasResults ? Icons.bolt_outlined : Icons.search_off,
                color: hasResults ? accentColor : Colors.white30,
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _countLabel(hasQuery: hasQuery, resultCount: resultCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selectedLabel != null) ...[
                const SizedBox(width: 8),
                _CommandPaletteStatusPill(
                  label: selectedLabel,
                  accentColor: accentColor,
                ),
              ],
              const SizedBox(width: 8),
              CommandPaletteKeyboardHints(
                accentColor: accentColor,
                compact: compactHints,
                canNavigate: hasResults,
                canRun: hasResults,
              ),
            ],
          ),
        );
      },
    );
  }

  String _countLabel({required bool hasQuery, required int resultCount}) {
    if (resultCount == 0) return 'No matches';

    final noun = hasQuery ? 'match' : 'command';
    final suffix = resultCount == 1 ? '' : 's';

    return '$resultCount $noun$suffix';
  }
}

/// Small status token used by the command palette footer.
class _CommandPaletteStatusPill extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _CommandPaletteStatusPill({
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color.lerp(accentColor, Colors.white, 0.22) ?? accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

@Preview(name: 'Command palette status footer', size: Size(520, 90))
Widget commandPaletteStatusFooterPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 460,
          child: CommandPaletteStatusFooter(
            resultCount: 7,
            selectedIndex: 2,
            query: 'slide',
            accentColor: Color(0xFF38BDF8),
          ),
        ),
      ),
    ),
  );
}
