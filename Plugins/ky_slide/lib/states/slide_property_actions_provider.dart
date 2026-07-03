import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;

import '../models/slide.dart';
import '../models/slide_transition_type.dart';
import '../models/style/gradient_animation.dart';
import '../models/style/particle_effect.dart';
import 'history_provider.dart';
import 'presentation_provider.dart';

final slidePropertyActionsProvider = Provider<SlidePropertyActions>((ref) {
  return SlidePropertyActions(ref);
});

class SlidePropertyActions {
  final Ref ref;

  const SlidePropertyActions(this.ref);

  Slide get currentSlide {
    final presentation = ref.read(presentationProvider);
    return presentation.slides[presentation.currentSlideIndex];
  }

  bool renameCurrentSlide(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || currentSlide.title == trimmedTitle) {
      return false;
    }

    return _recordMutation(
      label: SlidePropertyActionLabels.rename,
      mutate: (notifier) {
        notifier.setSlideTitle(trimmedTitle);
      },
    );
  }

  bool updateSpeakerNotes(String notes) {
    final trimmedTrailingNotes = notes.trimRight();
    final nextNotes = trimmedTrailingNotes.trim().isEmpty
        ? null
        : trimmedTrailingNotes;
    if (currentSlide.notes == nextNotes) return false;

    return _recordMutation(
      label: SlidePropertyActionLabels.notes,
      mutate: (notifier) {
        notifier.setSlideNotes(nextNotes);
      },
    );
  }

  bool updateBackgroundColor(Color? color) {
    if (currentSlide.backgroundColor == color) return false;

    return _recordMutation(
      label: color == null
          ? SlidePropertyActionLabels.clearBackground
          : SlidePropertyActionLabels.background,
      mutate: (notifier) {
        notifier.setSlideBackground(color);
      },
    );
  }

  bool updateTransition(SlideTransitionType transition) {
    if (currentSlide.transition == transition) return false;

    return _recordMutation(
      label: SlidePropertyActionLabels.transition,
      mutate: (notifier) {
        notifier.setSlideTransition(transition);
      },
    );
  }

  bool applyBackgroundGradient() {
    final presentation = ref.read(presentationProvider);
    final palette = presentation.theme.colorPalette;
    final colors = palette.length >= 3 ? palette.take(3).toList() : palette;
    if (colors.isEmpty) return false;

    return _recordMutation(
      label: SlidePropertyActionLabels.gradient,
      mutate: (notifier) {
        notifier.setSlideBackgroundGradient(
          GradientAnimation(colors: colors, duration: 4),
        );
      },
    );
  }

  bool clearBackgroundGradient() {
    if (currentSlide.backgroundGradient == null) return false;

    return _recordMutation(
      label: SlidePropertyActionLabels.clearGradient,
      mutate: (notifier) {
        notifier.setSlideBackgroundGradient(null);
      },
    );
  }

  bool applyBackgroundParticles() {
    final presentation = ref.read(presentationProvider);

    return _recordMutation(
      label: SlidePropertyActionLabels.particles,
      mutate: (notifier) {
        notifier.setSlideBackgroundParticles(
          ParticleEffect(
            particleCount: 50,
            color: presentation.theme.primaryColor.withValues(alpha: 0.5),
            speed: 0.5,
            size: 3,
          ),
        );
      },
    );
  }

  bool clearBackgroundParticles() {
    if (currentSlide.backgroundParticles == null) return false;

    return _recordMutation(
      label: SlidePropertyActionLabels.clearParticles,
      mutate: (notifier) {
        notifier.setSlideBackgroundParticles(null);
      },
    );
  }

  bool _recordMutation({
    required String label,
    required void Function(PresentationNotifier notifier) mutate,
  }) {
    final before = ref.read(presentationProvider);
    ref
        .read(historyProvider.notifier)
        .recordPresentationMutation(mutate, label: label);

    return !identical(before, ref.read(presentationProvider));
  }
}

class SlidePropertyActionLabels {
  static const background = 'Update slide background';
  static const clearBackground = 'Clear slide background';
  static const clearGradient = 'Remove slide gradient';
  static const clearParticles = 'Remove slide particles';
  static const gradient = 'Apply slide gradient';
  static const notes = 'Update speaker notes';
  static const particles = 'Apply slide particles';
  static const rename = 'Rename slide';
  static const transition = 'Update slide transition';

  const SlidePropertyActionLabels._();
}
