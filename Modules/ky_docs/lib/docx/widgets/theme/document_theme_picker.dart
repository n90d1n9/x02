import 'package:flutter/material.dart';

import '../../models/document_theme.dart';

class DocumentThemePicker extends StatelessWidget {
  static Key themeTileKey(String themeName) {
    return ValueKey('document-theme-tile-$themeName');
  }

  final List<DocumentTheme> themes;
  final String selectedThemeName;
  final ValueChanged<DocumentTheme> onThemeSelected;

  const DocumentThemePicker({
    super.key,
    required this.themes,
    required this.selectedThemeName,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 640.0;
        final columnCount = width >= 560 ? 2 : 1;
        final spacing = columnCount == 2 ? 12.0 : 0.0;
        final tileWidth = (width - spacing) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final theme in themes)
              SizedBox(
                width: tileWidth,
                child: _DocumentThemeTile(
                  theme: theme,
                  isSelected: theme.name == selectedThemeName,
                  onSelected: () => onThemeSelected(theme),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DocumentThemeTile extends StatelessWidget {
  final DocumentTheme theme;
  final bool isSelected;
  final VoidCallback onSelected;

  const _DocumentThemeTile({
    required this.theme,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? theme.primaryColor
        : colorScheme.outlineVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${theme.name} theme',
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: DocumentThemePicker.themeTileKey(theme.name),
          borderRadius: BorderRadius.circular(8),
          onTap: onSelected,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemePreview(theme: theme),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        theme.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: theme.primaryColor,
                      )
                    else
                      const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Font: ${theme.defaultFont}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                _ThemeSample(theme: theme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final DocumentTheme theme;

  const _ThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.primaryColor, theme.accentColor],
              ),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreviewLine(
                    widthFactor: 0.48,
                    height: 8,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 10),
                  _PreviewLine(
                    widthFactor: 0.88,
                    height: 5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  _PreviewLine(
                    widthFactor: 0.68,
                    height: 5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final double widthFactor;
  final double height;
  final Color color;

  const _PreviewLine({
    required this.widthFactor,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

class _ThemeSample extends StatelessWidget {
  final DocumentTheme theme;

  const _ThemeSample({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          'Aa',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.primaryColor,
            fontFamily: theme.defaultFont,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${theme.defaultFontSize.toStringAsFixed(0)} pt base',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _ColorSwatch(color: theme.primaryColor),
        const SizedBox(width: 4),
        _ColorSwatch(color: theme.accentColor),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}
