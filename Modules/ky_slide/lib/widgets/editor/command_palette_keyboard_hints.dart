import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Keyboard hint cluster for command palette navigation and execution.
class CommandPaletteKeyboardHints extends StatelessWidget {
  final Color accentColor;
  final bool compact;
  final bool canNavigate;
  final bool canRun;

  const CommandPaletteKeyboardHints({
    super.key,
    required this.accentColor,
    this.compact = false,
    this.canNavigate = true,
    this.canRun = true,
  });

  @override
  Widget build(BuildContext context) {
    final hints = [
      if (canNavigate)
        _CommandPaletteKeyboardHint(
          keys: 'Up/Down',
          label: 'Navigate',
          accentColor: accentColor,
          compact: compact,
        ),
      if (canRun)
        _CommandPaletteKeyboardHint(
          keys: 'Enter',
          label: 'Run',
          accentColor: accentColor,
          compact: compact,
        ),
      _CommandPaletteKeyboardHint(
        keys: 'Esc',
        label: 'Close',
        accentColor: accentColor,
        compact: compact,
      ),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: hints,
    );
  }
}

/// Individual keyboard shortcut hint used by the command palette footer.
class _CommandPaletteKeyboardHint extends StatelessWidget {
  final String keys;
  final String label;
  final Color accentColor;
  final bool compact;

  const _CommandPaletteKeyboardHint({
    required this.keys,
    required this.label,
    required this.accentColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keys,
            style: TextStyle(
              color: Color.lerp(accentColor, Colors.white, 0.18) ?? accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(message: '$keys $label', child: content);
  }
}

@Preview(name: 'Command palette keyboard hints', size: Size(520, 90))
Widget commandPaletteKeyboardHintsPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CommandPaletteKeyboardHints(accentColor: Color(0xFF38BDF8)),
      ),
    ),
  );
}
