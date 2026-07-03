import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../models/component_arrange_action.dart';
import '../models/presentation.dart';
import '../models/presentation_component.dart';
import '../models/slide.dart';
import '../models/slide_layout.dart';
import '../models/slide_template.dart';
import '../models/slide_transition_type.dart';
import '../models/style/gradient_animation.dart';
import '../models/style/particle_effect.dart';
import '../models/style/presentation_theme.dart';
import '../services/component_layout_service.dart';
import '../services/component_stacking_service.dart';
import '../services/slide_layout_service.dart';
import '../services/slide_template_service.dart';

final presentationProvider =
    StateNotifierProvider<PresentationNotifier, Presentation>((ref) {
      return PresentationNotifier();
    });

class PresentationNotifier extends StateNotifier<Presentation> {
  final ComponentStackingService stackingService;

  PresentationNotifier({
    Presentation? initialPresentation,
    this.stackingService = const ComponentStackingService(),
  }) : super(
         initialPresentation ??
             Presentation(
               id: const Uuid().v4(),
               title: 'New Presentation',
               slides: [
                 Slide(
                   id: const Uuid().v4(),
                   components: [],
                   title: 'Title Slide',
                 ),
               ],
             ),
       );

  void addSlide() {
    final slideNum = state.slides.length + 1;
    state = state.copyWith(
      slides: [
        ...state.slides,
        Slide(
          id: const Uuid().v4(),
          components: [],
          title: 'Slide $slideNum',
          backgroundColor: state.theme.backgroundColor,
        ),
      ],
    );
  }

  void addSlideFromTemplate(
    SlideTemplateType type, {
    SlideTemplateCustomization? customization,
  }) {
    final insertIndex = state.currentSlideIndex + 1;
    final slides = List<Slide>.from(state.slides);
    final slide = SlideTemplateService.createSlide(
      type: type,
      presentation: state,
      customization: customization,
    );

    slides.insert(insertIndex, slide);
    state = state.copyWith(slides: slides, currentSlideIndex: insertIndex);
  }

  void addSlideFromLayout(SlideLayoutType type) {
    final insertIndex = state.currentSlideIndex + 1;
    final slides = List<Slide>.from(state.slides);
    final slide = SlideLayoutService.createSlide(
      type: type,
      presentation: state,
    );

    slides.insert(insertIndex, slide);
    state = state.copyWith(slides: slides, currentSlideIndex: insertIndex);
  }

  void duplicateSlide(int index) {
    final slide = state.slides[index];
    final newComponents = slide.components
        .map(
          (c) => PresentationComponent(
            id: const Uuid().v4(),
            type: c.type,
            position: c.position,
            size: c.size,
            layerName: c.layerName,
            richText: c.richText,
            imageData: c.imageData,
            backgroundColor: c.backgroundColor,
            rotation: c.rotation,
            zIndex: c.zIndex,
            animation: c.animation,
            opacity: c.opacity,
            border: c.border,
            chartData: c.chartData,
            videoUrl: c.videoUrl,
            audioUrl: c.audioUrl,
            animationDelay: c.animationDelay,
            animationDuration: c.animationDuration,
            visualEffect: c.visualEffect,
            glassStyle: c.glassStyle,
            neumoStyle: c.neumoStyle,
            particleEffect: c.particleEffect,
            gradientAnim: c.gradientAnim,
            interactive: c.interactive,
            lottieAsset: c.lottieAsset,
            hasGlow: c.hasGlow,
            glowColor: c.glowColor,
            isVisible: c.isVisible,
            isLocked: c.isLocked,
          ),
        )
        .toList();

    final newSlide = Slide(
      id: const Uuid().v4(),
      components: newComponents,
      backgroundColor: slide.backgroundColor,
      notes: slide.notes,
      title: '${slide.title} (Copy)',
      transition: slide.transition,
      backgroundImage: slide.backgroundImage,
      backgroundGradient: slide.backgroundGradient,
      backgroundParticles: slide.backgroundParticles,
      backgroundVideo: slide.backgroundVideo,
    );

    final slides = List<Slide>.from(state.slides);
    slides.insert(index + 1, newSlide);
    state = state.copyWith(slides: slides);
  }

  void deleteSlide(int index) {
    if (state.slides.length <= 1) return;
    final slides = List<Slide>.from(state.slides);
    slides.removeAt(index);
    state = state.copyWith(
      slides: slides,
      currentSlideIndex: state.currentSlideIndex >= slides.length
          ? slides.length - 1
          : state.currentSlideIndex,
    );
  }

  void reorderSlides(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    moveSlide(oldIndex, newIndex);
  }

  void moveSlide(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    final slides = List<Slide>.from(state.slides);
    final slide = slides.removeAt(oldIndex);
    slides.insert(newIndex, slide);

    int newCurrentIndex = state.currentSlideIndex;
    if (oldIndex == state.currentSlideIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentSlideIndex &&
        newIndex >= state.currentSlideIndex) {
      newCurrentIndex--;
    } else if (oldIndex > state.currentSlideIndex &&
        newIndex <= state.currentSlideIndex) {
      newCurrentIndex++;
    }

    state = state.copyWith(slides: slides, currentSlideIndex: newCurrentIndex);
  }

  void setCurrentSlide(int index) {
    if (index >= 0 && index < state.slides.length) {
      state = state.copyWith(currentSlideIndex: index);
    }
  }

  void nextSlide() {
    if (state.currentSlideIndex < state.slides.length - 1) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex + 1);
    }
  }

  void previousSlide() {
    if (state.currentSlideIndex > 0) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex - 1);
    }
  }

  void addComponent(PresentationComponent component) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final maxZ = currentSlide.components.isEmpty
        ? 0
        : currentSlide.components.map((c) => c.zIndex).reduce(math.max);
    final newComponent = component.copyWith(zIndex: maxZ + 1);
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: [...currentSlide.components, newComponent],
    );
    state = state.copyWith(slides: slides);
  }

  void updateComponent(String componentId, PresentationComponent updated) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = currentSlide.components
        .map((c) => c.id == componentId ? updated : c)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void renameComponentLayer(String componentId, String? name) {
    final normalizedName = name?.trim();
    final nextName = normalizedName == null || normalizedName.isEmpty
        ? null
        : normalizedName;

    _updateCurrentSlideComponents((components) {
      var changed = false;
      final updated = components.map((component) {
        if (component.id != componentId) return component;
        if (component.layerName == nextName) return component;

        changed = true;
        return component.copyWith(layerName: nextName);
      }).toList();

      return changed ? updated : components;
    });
  }

  String? duplicateComponent(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final componentIndex = currentSlide.components.indexWhere(
      (component) => component.id == componentId,
    );
    if (componentIndex == -1) return null;

    final component = currentSlide.components[componentIndex];
    final maxZ = currentSlide.components.isEmpty
        ? 0
        : currentSlide.components.map((c) => c.zIndex).reduce(math.max);
    final duplicateId = const Uuid().v4();
    final duplicate = component.copyWith(
      id: duplicateId,
      position: component.position + const Offset(16, 16),
      zIndex: maxZ + 1,
      isEditing: false,
    );
    final components = List<PresentationComponent>.from(currentSlide.components)
      ..insert(componentIndex + 1, duplicate);

    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);

    return duplicateId;
  }

  void arrangeComponent(
    String componentId,
    ComponentArrangeAction action, {
    double gridSize = 20,
  }) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = currentSlide.components.map((component) {
      if (component.id != componentId) return component;

      return ComponentLayoutService.arrange(
        component: component,
        slideSize: state.slideSize,
        action: action,
        gridSize: gridSize,
      );
    }).toList();

    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void deleteComponent(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = currentSlide.components
        .where((c) => c.id != componentId)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void bringToFront(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final maxZ = currentSlide.components.map((c) => c.zIndex).reduce(math.max);
    final components = currentSlide.components
        .map((c) => c.id == componentId ? c.copyWith(zIndex: maxZ + 1) : c)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void sendToBack(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final minZ = currentSlide.components.map((c) => c.zIndex).reduce(math.min);
    final components = currentSlide.components
        .map((c) => c.id == componentId ? c.copyWith(zIndex: minZ - 1) : c)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void moveComponentForward(String componentId) {
    _updateCurrentSlideComponents(
      (components) => stackingService.moveForward(components, componentId),
    );
  }

  void moveComponentBackward(String componentId) {
    _updateCurrentSlideComponents(
      (components) => stackingService.moveBackward(components, componentId),
    );
  }

  void reorderCurrentSlideComponentsTopToBottom(List<String> topToBottomIds) {
    _updateCurrentSlideComponents(
      (components) =>
          stackingService.reorderTopToBottom(components, topToBottomIds),
    );
  }

  void setComponentVisibility(String componentId, bool isVisible) {
    _updateCurrentSlideComponents(
      (components) => components.map((component) {
        return component.id == componentId
            ? component.copyWith(isVisible: isVisible)
            : component;
      }).toList(),
    );
  }

  void setCurrentSlideComponentsVisibility(bool isVisible) {
    _updateCurrentSlideComponents((components) {
      var changed = false;
      final updated = components.map((component) {
        if (component.isVisible == isVisible) return component;

        changed = true;
        return component.copyWith(isVisible: isVisible);
      }).toList();

      return changed ? updated : components;
    });
  }

  void setComponentLocked(String componentId, bool isLocked) {
    _updateCurrentSlideComponents(
      (components) => components.map((component) {
        return component.id == componentId
            ? component.copyWith(isLocked: isLocked)
            : component;
      }).toList(),
    );
  }

  void setCurrentSlideComponentsLocked(bool isLocked) {
    _updateCurrentSlideComponents((components) {
      var changed = false;
      final updated = components.map((component) {
        if (component.isLocked == isLocked) return component;

        changed = true;
        return component.copyWith(isLocked: isLocked);
      }).toList();

      return changed ? updated : components;
    });
  }

  void _updateCurrentSlideComponents(
    List<PresentationComponent> Function(List<PresentationComponent> components)
    update,
  ) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = update(currentSlide.components);
    if (identical(components, currentSlide.components)) return;

    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setSlideBackground(Color? color) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      backgroundColor: color,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideBackgroundImage(Uint8List? imageData) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      backgroundImage: imageData,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideBackgroundGradient(GradientAnimation? gradient) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      backgroundGradient: gradient,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideBackgroundParticles(ParticleEffect? particles) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      backgroundParticles: particles,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideTitle(String title) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      title: title,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideNotes(String? notes) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      notes: notes,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideTransition(SlideTransitionType transition) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      transition: transition,
    );
    state = state.copyWith(slides: slides);
  }

  void applyTheme(PresentationTheme theme) {
    final slides = state.slides.map((slide) {
      return slide.copyWith(
        backgroundColor: slide.backgroundColor ?? theme.backgroundColor,
      );
    }).toList();
    state = state.copyWith(theme: theme, slides: slides);
  }

  void loadPresentation(Presentation presentation) {
    state = presentation;
  }
}
