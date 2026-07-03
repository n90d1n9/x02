import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;

import '../models/slide_layout.dart';
import '../models/slide_template.dart';
import '../services/slide_batch_move_service.dart';
import 'component_provider.dart';
import 'history_provider.dart';
import 'presentation_provider.dart';

final slideActionsProvider = Provider<SlideActions>((ref) {
  return SlideActions(ref);
});

/// Coordinates slide mutations with history and editor selection state.
class SlideActions {
  final Ref ref;

  const SlideActions(this.ref);

  bool get canDeleteCurrentSlide =>
      ref.read(presentationProvider).slides.length > 1;

  int addSlide() {
    var nextIndex = ref.read(presentationProvider).slides.length;
    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.addSlide();
      nextIndex = ref.read(presentationProvider).slides.length - 1;
      notifier.setCurrentSlide(nextIndex);
    }, label: SlideActionLabels.add);

    ref.read(selectedComponentProvider.notifier).state = null;
    return nextIndex;
  }

  bool duplicateSlide({int? index}) {
    final presentation = ref.read(presentationProvider);
    final slideIndex = index ?? presentation.currentSlideIndex;
    if (slideIndex < 0 || slideIndex >= presentation.slides.length) {
      return false;
    }

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.duplicateSlide(slideIndex);
      notifier.setCurrentSlide(slideIndex + 1);
    }, label: SlideActionLabels.duplicate);

    ref.read(selectedComponentProvider.notifier).state = null;
    return true;
  }

  bool duplicateSlides(Iterable<int> indexes) {
    final presentation = ref.read(presentationProvider);
    final slideIndexes = _validUniqueIndexes(
      indexes: indexes,
      slideCount: presentation.slides.length,
    );
    if (slideIndexes.isEmpty) return false;

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      var insertedCopies = 0;
      for (final index in slideIndexes) {
        notifier.duplicateSlide(index + insertedCopies);
        insertedCopies++;
      }

      notifier.setCurrentSlide(slideIndexes.last + insertedCopies);
    }, label: SlideActionLabels.duplicateSelected);

    ref.read(selectedComponentProvider.notifier).state = null;
    return true;
  }

  int addTemplateSlide(
    SlideTemplateType type, {
    SlideTemplateCustomization? customization,
  }) {
    var nextIndex = ref.read(presentationProvider).currentSlideIndex + 1;
    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.addSlideFromTemplate(type, customization: customization);
      nextIndex = ref.read(presentationProvider).currentSlideIndex;
    }, label: SlideActionLabels.addTemplate);

    ref.read(selectedComponentProvider.notifier).state = null;
    return nextIndex;
  }

  int addLayoutSlide(SlideLayoutType type) {
    var nextIndex = ref.read(presentationProvider).currentSlideIndex + 1;
    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.addSlideFromLayout(type);
      nextIndex = ref.read(presentationProvider).currentSlideIndex;
    }, label: SlideActionLabels.addLayout);

    ref.read(selectedComponentProvider.notifier).state = null;
    return nextIndex;
  }

  bool deleteSlide({int? index}) {
    final presentation = ref.read(presentationProvider);
    if (presentation.slides.length <= 1) return false;

    final slideIndex = index ?? presentation.currentSlideIndex;
    if (slideIndex < 0 || slideIndex >= presentation.slides.length) {
      return false;
    }

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.deleteSlide(slideIndex);
    }, label: SlideActionLabels.delete);

    ref.read(selectedComponentProvider.notifier).state = null;
    return true;
  }

  bool deleteSlides(Iterable<int> indexes) {
    final presentation = ref.read(presentationProvider);
    final slideIndexes = _validUniqueIndexes(
      indexes: indexes,
      slideCount: presentation.slides.length,
    );
    if (slideIndexes.isEmpty) return false;
    if (presentation.slides.length - slideIndexes.length < 1) return false;

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      for (final index in slideIndexes.reversed) {
        notifier.deleteSlide(index);
      }
    }, label: SlideActionLabels.deleteSelected);

    ref.read(selectedComponentProvider.notifier).state = null;
    return true;
  }

  bool moveSlidesEarlier(Iterable<int> indexes) {
    return _moveSlides(
      indexes: indexes,
      direction: SlideBatchMoveDirection.earlier,
      label: SlideActionLabels.moveSelectedEarlier,
    );
  }

  bool moveSlidesLater(Iterable<int> indexes) {
    return _moveSlides(
      indexes: indexes,
      direction: SlideBatchMoveDirection.later,
      label: SlideActionLabels.moveSelectedLater,
    );
  }

  bool moveSlide(int oldIndex, int newIndex) {
    final presentation = ref.read(presentationProvider);
    if (oldIndex < 0 ||
        oldIndex >= presentation.slides.length ||
        newIndex < 0 ||
        newIndex >= presentation.slides.length ||
        oldIndex == newIndex) {
      return false;
    }

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.moveSlide(oldIndex, newIndex);
    }, label: SlideActionLabels.move);

    return true;
  }

  bool _moveSlides({
    required Iterable<int> indexes,
    required SlideBatchMoveDirection direction,
    required String label,
  }) {
    final presentation = ref.read(presentationProvider);
    final steps = SlideBatchMoveService.steps(
      indexes: indexes,
      slideCount: presentation.slides.length,
      direction: direction,
    );
    if (steps.isEmpty) return false;

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      for (final step in steps) {
        notifier.moveSlide(step.oldIndex, step.newIndex);
      }
    }, label: label);

    return true;
  }

  List<int> _validUniqueIndexes({
    required Iterable<int> indexes,
    required int slideCount,
  }) {
    return indexes
        .where((index) => index >= 0 && index < slideCount)
        .toSet()
        .toList()
      ..sort();
  }
}

/// Stable labels used by slide history entries.
class SlideActionLabels {
  static const add = 'Add slide';
  static const addLayout = 'Add layout slide';
  static const addTemplate = 'Add template slide';
  static const delete = 'Delete slide';
  static const deleteSelected = 'Delete slides';
  static const duplicate = 'Duplicate slide';
  static const duplicateSelected = 'Duplicate slides';
  static const move = 'Move slide';
  static const moveSelectedEarlier = 'Move slides earlier';
  static const moveSelectedLater = 'Move slides later';

  const SlideActionLabels._();
}
