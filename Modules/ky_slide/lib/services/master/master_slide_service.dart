import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/master/master_slide_model.dart';
import '../models/presentation.dart';

/// Provider for the current master slide
final masterSlideProvider = StateNotifierProvider<MasterSlideNotifier, MasterSlide>((ref) {
  return MasterSlideNotifier();
});

/// Provider for the currently selected layout in master view
final selectedLayoutProvider = StateProvider<MasterLayout?>((ref) => null);

/// Provider for master view mode (editing preview, etc.)
final masterViewModeProvider = StateProvider<MasterViewMode>((ref) => MasterViewMode.edit);

enum MasterViewMode {
  edit,
  preview,
  themeEdit,
}

class MasterSlideNotifier extends StateNotifier<MasterSlide> {
  MasterSlideNotifier() : super(MasterSlide.createDefault());

  /// Update master slide name
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  /// Add a new layout to the master slide
  void addLayout(MasterLayout layout) {
    final updatedLayouts = [...state.layouts, layout];
    state = state.copyWith(layouts: updatedLayouts);
  }

  /// Update an existing layout
  void updateLayout(String layoutId, MasterLayout updatedLayout) {
    final updatedLayouts = state.layouts.map((layout) {
      if (layout.id == layoutId) {
        return updatedLayout;
      }
      return layout;
    }).toList();
    state = state.copyWith(layouts: updatedLayouts);
  }

  /// Remove a layout from the master slide
  void removeLayout(String layoutId) {
    final updatedLayouts = state.layouts.where((l) => l.id != layoutId).toList();
    state = state.copyWith(layouts: updatedLayouts);
  }

  /// Reorder layouts
  void reorderLayouts(int oldIndex, int newIndex) {
    final updatedLayouts = List<MasterLayout>.from(state.layouts);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final layout = updatedLayouts.removeAt(oldIndex);
    updatedLayouts.insert(newIndex, layout);
    state = state.copyWith(layouts: updatedLayouts);
  }

  /// Update master slide background
  void updateBackground(Map<String, dynamic> background) {
    state = state.copyWith(background: background);
  }

  /// Update text style defaults
  void updateTextStyles(TextStyleDefaults textStyles) {
    state = state.copyWith(textStyles: textStyles);
  }

  /// Update theme
  void updateTheme(ThemeData theme) {
    state = state.copyWith(theme: theme);
  }

  /// Get layout by ID
  MasterLayout? getLayoutById(String layoutId) {
    try {
      return state.layouts.firstWhere((l) => l.id == layoutId);
    } catch (e) {
      return null;
    }
  }

  /// Get visible layouts (not hidden)
  List<MasterLayout> getVisibleLayouts() {
    return state.layouts.where((l) => !l.isHidden).toList();
  }

  /// Import master slide from JSON
  void importFromJson(Map<String, dynamic> json) {
    state = MasterSlide.fromJson(json);
  }

  /// Export master slide to JSON
  Map<String, dynamic> exportToJson() {
    return state.toJson();
  }

  /// Reset to default master slide
  void resetToDefault() {
    state = MasterSlide.createDefault();
  }

  /// Create a new custom layout
  MasterLayout createCustomLayout({
    required String name,
    List<Component> placeholders = const [],
    Map<String, dynamic> background = const {},
  }) {
    return MasterLayout(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: MasterLayoutType.custom,
      placeholders: placeholders,
      background: background,
    );
  }

  /// Duplicate an existing layout
  MasterLayout duplicateLayout(String layoutId) {
    final original = getLayoutById(layoutId);
    if (original == null) {
      throw Exception('Layout not found: $layoutId');
    }

    final duplicated = MasterLayout(
      id: '${original.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      type: original.type,
      placeholders: original.placeholders.map((p) {
        return p.copyWith(id: '${p.id}_copy');
      }).toList(),
      background: Map<String, dynamic>.from(original.background),
      textStyles: original.textStyles,
    );

    addLayout(duplicated);
    return duplicated;
  }
}

/// Provider for applying master slide changes to presentation slides
final masterSlideApplicationProvider = Provider<MasterSlideApplicationService>((ref) {
  return MasterSlideApplicationService(ref);
});

class MasterSlideApplicationService {
  final Ref _ref;

  MasterSlideApplicationService(this._ref);

  /// Apply a master layout to a specific slide
  void applyLayoutToSlide(String slideId, String layoutId) {
    final presentation = _ref.read(presentationProvider.notifier);
    final masterSlide = _ref.read(masterSlideProvider);
    final layout = masterSlide.getLayoutById(layoutId);

    if (layout == null) {
      throw Exception('Layout not found: $layoutId');
    }

    // Update slide's layout reference
    presentation.updateSlideLayout(slideId, layoutId);

    // Optionally apply placeholder styles to existing components
    _applyPlaceholderStyles(slideId, layout);
  }

  /// Apply master theme to all slides
  void applyThemeToAllSlides() {
    final presentation = _ref.read(presentationProvider.notifier);
    final masterSlide = _ref.read(masterSlideProvider);

    if (masterSlide.theme != null) {
      presentation.applyThemeToAllSlides(masterSlide.theme!);
    }
  }

  /// Sync text styles from master to slides using that layout
  void syncTextStyles(String layoutId) {
    final presentation = _ref.read(presentationProvider.notifier);
    final masterSlide = _ref.read(masterSlideProvider);
    final layout = masterSlide.getLayoutById(layoutId);

    if (layout == null || layout.textStyles == null) {
      return;
    }

    // Find all slides using this layout and update their text styles
    final slides = presentation.state.slides;
    for (final slide in slides) {
      if (slide.layoutId == layoutId) {
        _updateSlideTextStyles(slide.id, layout.textStyles!);
      }
    }
  }

  void _applyPlaceholderStyles(String slideId, MasterLayout layout) {
    // Implementation for applying placeholder styles to slide components
    // This would match components to placeholders and inherit styles
  }

  void _updateSlideTextStyles(String slideId, TextStyleDefaults textStyles) {
    // Implementation for updating text styles on a slide
  }
}
