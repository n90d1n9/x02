import 'package:flutter/material.dart';

/// Describes a visual section marker in the document formatting ribbon.
class DocumentFormattingRibbonSection {
  final IconData icon;
  final String label;

  const DocumentFormattingRibbonSection({
    required this.icon,
    required this.label,
  });
}

/// Provides polished, responsive ribbon chrome around document editing tools.
class DocumentFormattingRibbonShell extends StatelessWidget {
  static const toolbarSlotKey = ValueKey('document-formatting-ribbon-slot');

  final bool compact;
  final List<DocumentFormattingRibbonSection> sections;
  final Widget child;

  const DocumentFormattingRibbonShell({
    super.key,
    required this.compact,
    required this.sections,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 6 : 10,
            compact ? 4 : 6,
            compact ? 6 : 10,
            compact ? 5 : 7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                _RibbonHeader(sections: sections),
                const SizedBox(height: 6),
              ],
              DecoratedBox(
                key: toolbarSlotKey,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: compact ? 0.16 : 0.22,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.48),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 2 : 6,
                    vertical: compact ? 1 : 3,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonHeader extends StatelessWidget {
  final List<DocumentFormattingRibbonSection> sections;

  const _RibbonHeader({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RibbonTab(
          icon: Icons.edit_note_outlined,
          label: 'Home',
          selected: true,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final section in sections) ...[
                  _RibbonSectionPill(section: section),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RibbonTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _RibbonTab({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.78)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.18)
              : colorScheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RibbonSectionPill extends StatelessWidget {
  final DocumentFormattingRibbonSection section;

  const _RibbonSectionPill({required this.section});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(section.icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            section.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
