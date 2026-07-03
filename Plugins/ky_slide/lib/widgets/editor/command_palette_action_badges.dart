import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Compact metadata and shortcut badges shown beside a command palette action.
class CommandPaletteActionBadges extends StatelessWidget {
  final String category;
  final String? shortcutLabel;
  final List<String> metadataLabels;
  final bool enabled;
  final Color accentColor;

  const CommandPaletteActionBadges({
    super.key,
    required this.category,
    required this.shortcutLabel,
    required this.metadataLabels,
    required this.enabled,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final shortcut = shortcutLabel?.trim();
    final metadata = metadataLabels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .take(2)
        .toList(growable: false);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          if (shortcut != null && shortcut.isNotEmpty)
            _CommandShortcutBadge(label: shortcut, enabled: enabled),
          for (final label in metadata)
            _CommandMetadataBadge(label: label, enabled: enabled),
          _CommandCategoryBadge(
            label: category,
            enabled: enabled,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

/// Keyboard shortcut marker for commands with a fast path.
class _CommandShortcutBadge extends StatelessWidget {
  final String label;
  final bool enabled;

  const _CommandShortcutBadge({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return _CommandBadgeFrame(
      backgroundColor: Colors.white.withValues(alpha: enabled ? 0.06 : 0.025),
      borderColor: Colors.white.withValues(alpha: enabled ? 0.12 : 0.06),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: enabled ? Colors.white70 : Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Secondary metadata marker for command behavior such as panels or toggles.
class _CommandMetadataBadge extends StatelessWidget {
  final String label;
  final bool enabled;

  const _CommandMetadataBadge({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return _CommandBadgeFrame(
      backgroundColor: Colors.white.withValues(alpha: enabled ? 0.035 : 0.02),
      borderColor: Colors.white.withValues(alpha: enabled ? 0.08 : 0.05),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: enabled ? Colors.white54 : Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Category marker for command palette rows.
class _CommandCategoryBadge extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color accentColor;

  const _CommandCategoryBadge({
    required this.label,
    required this.enabled,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return _CommandBadgeFrame(
      backgroundColor: enabled
          ? accentColor.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.025),
      borderColor: enabled
          ? accentColor.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.06),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: enabled ? Colors.white60 : Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Shared frame for command palette metadata badges.
class _CommandBadgeFrame extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  const _CommandBadgeFrame({
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor),
      ),
      child: Center(child: child),
    );
  }
}

@Preview(name: 'Command palette action badges', size: Size(360, 100))
Widget commandPaletteActionBadgesPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CommandPaletteActionBadges(
          category: 'Object',
          shortcutLabel: 'Cmd/Ctrl+D',
          metadataLabels: ['Selected', 'Layer'],
          enabled: true,
          accentColor: Color(0xFF38BDF8),
        ),
      ),
    ),
  );
}
