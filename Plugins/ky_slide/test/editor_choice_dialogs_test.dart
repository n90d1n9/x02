import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/enums.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/widgets/dialogs/theme_picker_dialog.dart';
import 'package:ky_slide/widgets/dialogs/visual_effects_dialog.dart';

void main() {
  testWidgets('theme picker dialog emits selected theme', (tester) async {
    PresentationTheme? selectedTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: ThemePickerDialog(
              themes: PresentationTheme.allThemes,
              selectedThemeId: PresentationTheme.modernGlass.id,
              accentColor: const Color(0xFF6366F1),
              onThemeSelected: (theme) => selectedTheme = theme,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Choose Theme'), findsOneWidget);
    expect(find.text('Modern Glass'), findsOneWidget);
    expect(find.text('Neon Cyber'), findsOneWidget);

    await tester.tap(find.text('Neon Cyber'));
    await tester.pumpAndSettle();

    expect(selectedTheme?.id, PresentationTheme.neonCyber.id);
  });

  testWidgets('visual effects dialog emits selected effect', (tester) async {
    VisualEffect? selectedEffect;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: VisualEffectsDialog(
              accentColor: const Color(0xFF38BDF8),
              onEffectSelected: (effect) => selectedEffect = effect,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Visual Effects'), findsOneWidget);
    expect(find.text('Glassmorphism'), findsOneWidget);
    expect(find.text('Glow'), findsOneWidget);

    await tester.tap(find.text('Glow'));
    await tester.pumpAndSettle();

    expect(selectedEffect, VisualEffect.glow);
  });
}
