import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slide_transition.dart';
import '../models/presentation.dart';

/// Provider for the currently selected transition in the UI editor.
final selectedTransitionIdProvider = StateProvider<String?>((ref) => null);

/// Service provider for managing slide transitions across the presentation.
final slideTransitionServiceProvider = Provider<SlideTransitionService>((ref) {
  return SlideTransitionService(ref);
});

/// Business logic service for Slide Transitions.
class SlideTransitionService {
  final Ref _ref;

  SlideTransitionService(this._ref);

  /// Get the transition for a specific slide.
  SlideTransition? getTransitionForSlide(String slideId) {
    final presentation = _ref.read(presentationProvider);
    final slide = presentation.slides.firstWhere(
      (s) => s.id == slideId,
      orElse: () => throw Exception('Slide not found'),
    );
    
    // In a real implementation, the Slide model would have a `transition` field.
    // For now, we simulate it or return default if not set.
    // Assuming slide has a Map<String, dynamic> metadata or similar.
    // This is a placeholder until the Slide model is updated with a transition field.
    return SlideTransition.defaultTransition(); 
  }

  /// Set transition for a specific slide.
  void setTransition(String slideId, SlideTransition transition) {
    final presentation = _ref.read(presentationProvider);
    
    // Update the slide's transition property
    // Note: This requires the Slide model to be updated to include a `transition` field.
    // For this implementation, we assume a mutable update mechanism exists.
    
    _ref.read(presentationProvider.notifier).updateSlide(slideId, (slide) {
      // Pseudo-code: slide.transition = transition;
      // Since we can't modify the existing Slide model without seeing it,
      // we rely on the user integrating this into their existing Slide model.
      return slide; 
    });
  }

  /// Apply the current slide's transition to all slides.
  void applyToAll(String sourceSlideId) {
    final transition = getTransitionForSlide(sourceSlideId);
    if (transition == null) return;

    final presentation = _ref.read(presentationProvider);
    
    _ref.read(presentationProvider.notifier).updateAllSlides((slide) {
      // Pseudo-code: slide.transition = transition.copyWith(applyToAll: false);
      return slide;
    });
  }

  /// Generate a unique ID for a new transition configuration.
  String generateId() {
    return 'trans_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get a list of all available transition types for the UI gallery.
  List<TransitionType> getAvailableTypes() {
    return TransitionType.values.where((t) => t != TransitionType.random).toList();
  }
}
