import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/presentation.dart';
import '../../models/slide.dart';
import '../../models/style/presentation_theme.dart';
import '../../services/presentation_command_palette_catalog.dart';
import '../../states/command_palette_provider.dart';
import '../../states/editor_view_provider.dart';
import '../../states/presentation_provider.dart';
import 'command_palette_overlay.dart';

/// Editor-aware command palette overlay that maps commands to provider actions.
class PresentationCommandPaletteOverlay extends ConsumerWidget {
  final VoidCallback onShowThemes;
  final VoidCallback onShowEffects;
  final VoidCallback onPresent;

  const PresentationCommandPaletteOverlay({
    super.key,
    required this.onShowThemes,
    required this.onShowEffects,
    required this.onPresent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final recentCommandIds = ref.watch(commandPaletteRecentCommandIdsProvider);

    return Positioned.fill(
      child: CommandPaletteOverlay(
        accentColor: presentation.theme.primaryColor,
        recentCommandIds: recentCommandIds,
        actions: PresentationCommandPaletteCatalog(
          ref: ref,
          presentation: presentation,
          onShowThemes: onShowThemes,
          onShowEffects: onShowEffects,
          onPresent: onPresent,
        ).actions(),
        onCommandInvoked: (action) {
          ref
              .read(commandPaletteRecentCommandIdsProvider.notifier)
              .record(action.id);
        },
        onClose: () => _close(ref),
      ),
    );
  }

  void _close(WidgetRef ref) {
    ref.read(commandPaletteVisibleProvider.notifier).state = false;
  }
}

@Preview(name: 'Presentation command palette overlay', size: Size(760, 560))
Widget presentationCommandPaletteOverlayPreview() {
  return ProviderScope(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(initialPresentation: _previewDeck()),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            PresentationCommandPaletteOverlay(
              onShowThemes: () {},
              onShowEffects: () {},
              onPresent: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

Presentation _previewDeck() {
  return Presentation(
    id: 'command-palette-preview',
    title: 'Quarterly Business Review',
    slides: [Slide(id: 'intro', title: 'Intro', components: [])],
    theme: PresentationTheme(
      id: 'command-palette-preview-theme',
      name: 'Command Palette Preview',
      primaryColor: const Color(0xFF38BDF8),
      secondaryColor: const Color(0xFF22C55E),
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: const [Color(0xFF38BDF8), Color(0xFF22C55E)],
    ),
  );
}
