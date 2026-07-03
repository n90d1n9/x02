import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/style/presentation_theme.dart';
import 'editor_dialog_frame.dart';

/// Dialog for choosing a presentation-wide visual theme.
class ThemePickerDialog extends StatelessWidget {
  final List<PresentationTheme> themes;
  final String? selectedThemeId;
  final Color accentColor;
  final ValueChanged<PresentationTheme> onThemeSelected;

  const ThemePickerDialog({
    super.key,
    required this.themes,
    required this.selectedThemeId,
    required this.accentColor,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return EditorDialogFrame(
      title: 'Choose Theme',
      icon: Icons.palette_outlined,
      accentColor: accentColor,
      width: 520,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 430),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final theme in themes) ...[
                ThemeOptionCard(
                  theme: theme,
                  isSelected: theme.id == selectedThemeId,
                  onSelect: () => onThemeSelected(theme),
                ),
                if (theme != themes.last) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.maybePop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Selectable preview card for a presentation theme.
class ThemeOptionCard extends StatelessWidget {
  final PresentationTheme theme;
  final bool isSelected;
  final VoidCallback onSelect;

  const ThemeOptionCard({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? theme.primaryColor
        : Colors.white.withValues(alpha: 0.08);

    return Semantics(
      button: true,
      selected: isSelected,
      label: theme.name,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            theme.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.primaryColor,
                            size: 17,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final color in theme.colorPalette.take(5))
                          _ThemeSwatch(color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small color sample used by [ThemeOptionCard].
class _ThemeSwatch extends StatelessWidget {
  final Color color;

  const _ThemeSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }
}

@Preview(name: 'Theme picker dialog', size: Size(620, 560))
Widget themePickerDialogPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: ThemePickerDialog(
          themes: PresentationTheme.allThemes,
          selectedThemeId: PresentationTheme.modernGlass.id,
          accentColor: const Color(0xFF6366F1),
          onThemeSelected: (_) {},
        ),
      ),
    ),
  );
}

@Preview(name: 'Theme option card', size: Size(560, 120))
Widget themeOptionCardPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 500,
          child: ThemeOptionCard(
            theme: PresentationTheme.neonCyber,
            isSelected: true,
            onSelect: () {},
          ),
        ),
      ),
    ),
  );
}
