import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/component.dart';
import '../../models/presentation.dart';
import '../../models/presentation_component.dart';
import '../../models/slide.dart';
import '../../models/slide_sorter_density.dart';
import '../../models/slide_sorter_selection.dart';
import '../../models/style/presentation_theme.dart';
import '../../services/slide_batch_move_service.dart';
import '../../services/slide_search_service.dart';
import '../../services/slide_sorter_navigation_service.dart';
import '../../services/slide_sorter_selection_service.dart';
import '../../states/editor_view_provider.dart';
import '../../states/presentation_provider.dart';
import '../../states/slide_actions_provider.dart';
import 'slide_sorter_density_control.dart';
import 'slide_sorter_grid.dart';

/// Full-screen editor overlay that adapts presentation state into slide board UI.
class SlideSorterOverlay extends ConsumerStatefulWidget {
  const SlideSorterOverlay({super.key});

  @override
  ConsumerState<SlideSorterOverlay> createState() => _SlideSorterOverlayState();
}

/// Owns slide board search, batch selection, and keyboard command state.
class _SlideSorterOverlayState extends ConsumerState<SlideSorterOverlay> {
  late final TextEditingController _searchController;
  late final FocusNode _shortcutFocusNode;
  SlideSorterSelection _selection = SlideSorterSelection();
  SlideSorterDensity _density = SlideSorterDensity.balanced;
  int _gridColumnCount = 1;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _shortcutFocusNode = FocusNode(debugLabel: 'Slide sorter shortcuts');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _shortcutFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _shortcutFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final matchingIndexes = SlideSearchService.matchingIndexes(
      presentation,
      _query,
    );
    final selectedIndexes = _selectedIndexes(presentation);
    final canMoveSelectedEarlier = SlideBatchMoveService.canMove(
      indexes: selectedIndexes,
      slideCount: presentation.slides.length,
      direction: SlideBatchMoveDirection.earlier,
    );
    final canMoveSelectedLater = SlideBatchMoveService.canMove(
      indexes: selectedIndexes,
      slideCount: presentation.slides.length,
      direction: SlideBatchMoveDirection.later,
    );

    return Focus(
      focusNode: _shortcutFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        return _handleShortcutKey(
          event: event,
          context: context,
          presentation: presentation,
          matchingIndexes: matchingIndexes,
        );
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: 'Slide sorter',
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: ColoredBox(
                  color: const Color(0xFF020617).withValues(alpha: 0.72),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = math.min(constraints.maxWidth - 32, 1040.0);
                    final height = math.min(constraints.maxHeight - 32, 720.0);

                    return SizedBox(
                      width: math.max(width, 320),
                      height: math.max(height, 460),
                      child: _SlideSorterSurface(
                        presentation: presentation,
                        matchingIndexes: matchingIndexes,
                        searchValue: _query,
                        searchController: _searchController,
                        onSearchChanged: (value) {
                          setState(() => _query = value);
                        },
                        onClearSearch: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        selectedSlideIds: _selection.selectedSlideIds,
                        selectedCount: selectedIndexes.length,
                        canMoveSelectedEarlier: canMoveSelectedEarlier,
                        canMoveSelectedLater: canMoveSelectedLater,
                        density: _density,
                        onClose: _close,
                        onOpenCurrent: _close,
                        onDensityChanged: (value) {
                          setState(() => _density = value);
                        },
                        onSelectSlide: _selectSlide,
                        onToggleSlideSelection: (index, extendRange) {
                          _toggleSlideSelection(
                            index: index,
                            visibleIndexes: matchingIndexes,
                            extendRange: extendRange,
                          );
                        },
                        onSelectVisibleSlides: () =>
                            _selectVisibleSlides(presentation, matchingIndexes),
                        onClearSelection: _clearSelection,
                        onDuplicateSlide: _duplicateSlide,
                        onDuplicateSelectedSlides: () {
                          _duplicateSelectedSlides(presentation);
                        },
                        onMoveSelectedSlidesEarlier: () {
                          _moveSelectedSlidesEarlier(presentation);
                        },
                        onMoveSelectedSlidesLater: () {
                          _moveSelectedSlidesLater(presentation);
                        },
                        onDeleteSlide: (index) => _deleteSlide(context, index),
                        onDeleteSelectedSlides: () {
                          _deleteSelectedSlides(context, presentation);
                        },
                        onMoveSlide: _moveSlide,
                        onColumnCountChanged: _setGridColumnCount,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleShortcutKey({
    required KeyEvent event,
    required BuildContext context,
    required Presentation presentation,
    required List<int> matchingIndexes,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _handleEscape();
      return KeyEventResult.handled;
    }

    if (_textInputFocused) return KeyEventResult.ignored;

    final navigationIntent = _navigationIntentFor(event.logicalKey);
    if (navigationIntent != null) {
      _navigateSlides(
        presentation: presentation,
        matchingIndexes: matchingIndexes,
        intent: navigationIntent,
      );
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _close();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _toggleCurrentSlideSelection(
        presentation: presentation,
        visibleIndexes: matchingIndexes,
      );
      return KeyEventResult.handled;
    }

    final isModifierPressed = _controlPressed || _metaPressed;
    if (isModifierPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      _selectVisibleSlides(presentation, matchingIndexes);
      return KeyEventResult.handled;
    }

    if (isModifierPressed && event.logicalKey == LogicalKeyboardKey.keyD) {
      _duplicateSelectedSlides(presentation);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      _deleteSelectedSlides(context, presentation);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  SlideSorterNavigationIntent? _navigationIntentFor(LogicalKeyboardKey key) {
    return switch (key) {
      LogicalKeyboardKey.arrowLeft => SlideSorterNavigationIntent.previous,
      LogicalKeyboardKey.arrowRight => SlideSorterNavigationIntent.next,
      LogicalKeyboardKey.arrowUp => SlideSorterNavigationIntent.up,
      LogicalKeyboardKey.arrowDown => SlideSorterNavigationIntent.down,
      LogicalKeyboardKey.home => SlideSorterNavigationIntent.first,
      LogicalKeyboardKey.end => SlideSorterNavigationIntent.last,
      _ => null,
    };
  }

  void _navigateSlides({
    required Presentation presentation,
    required List<int> matchingIndexes,
    required SlideSorterNavigationIntent intent,
  }) {
    final targetIndex = SlideSorterNavigationService.resolve(
      visibleIndexes: matchingIndexes,
      currentIndex: presentation.currentSlideIndex,
      intent: intent,
      crossAxisCount: _gridColumnCount,
    );
    if (targetIndex == null) return;

    _selectSlide(targetIndex);
  }

  void _toggleCurrentSlideSelection({
    required Presentation presentation,
    required List<int> visibleIndexes,
  }) {
    final currentIndex = presentation.currentSlideIndex;
    if (!visibleIndexes.contains(currentIndex)) return;

    _toggleSlideSelection(
      index: currentIndex,
      visibleIndexes: visibleIndexes,
      extendRange: _shiftPressed,
    );
  }

  bool get _controlPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  bool get _metaPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  bool get _shiftPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }

  bool get _textInputFocused {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return false;

    return focusedContext.widget is EditableText;
  }

  void _close() {
    ref.read(slideSorterVisibleProvider.notifier).state = false;
  }

  void _handleEscape() {
    if (!_selection.isEmpty) {
      _clearSelection();
      return;
    }

    _close();
  }

  void _selectSlide(int index) {
    ref.read(presentationProvider.notifier).setCurrentSlide(index);
  }

  void _duplicateSlide(int index) {
    ref.read(slideActionsProvider).duplicateSlide(index: index);
  }

  void _deleteSlide(BuildContext context, int index) {
    final slides = ref.read(presentationProvider).slides;
    final slideId = index >= 0 && index < slides.length
        ? slides[index].id
        : null;
    final deleted = ref.read(slideActionsProvider).deleteSlide(index: index);
    if (deleted && slideId != null) {
      setState(() {
        _selection = SlideSorterSelectionService.removeSlideId(
          selection: _selection,
          slideId: slideId,
        );
      });
    }
    if (deleted || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A presentation needs at least one slide.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _moveSlide(int oldIndex, int newIndex) {
    ref.read(slideActionsProvider).moveSlide(oldIndex, newIndex);
  }

  void _setGridColumnCount(int count) {
    if (!mounted || count == _gridColumnCount) return;

    setState(() => _gridColumnCount = count);
  }

  void _toggleSlideSelection({
    required int index,
    required List<int> visibleIndexes,
    required bool extendRange,
  }) {
    final presentation = ref.read(presentationProvider);
    setState(() {
      _selection = SlideSorterSelectionService.toggle(
        slides: presentation.slides,
        selection: _selection,
        index: index,
        visibleIndexes: visibleIndexes,
        extendRange: extendRange,
      );
    });
  }

  void _selectVisibleSlides(
    Presentation presentation,
    List<int> visibleIndexes,
  ) {
    setState(() {
      _selection = SlideSorterSelectionService.selectVisible(
        slides: presentation.slides,
        selection: _selection,
        visibleIndexes: visibleIndexes,
      );
    });
  }

  void _clearSelection() {
    setState(() => _selection = SlideSorterSelection());
  }

  void _duplicateSelectedSlides(Presentation presentation) {
    final selectedIndexes = _selectedIndexes(presentation);
    if (selectedIndexes.isEmpty) return;

    final duplicated = ref
        .read(slideActionsProvider)
        .duplicateSlides(selectedIndexes);
    if (!duplicated) return;

    setState(() {});
  }

  void _moveSelectedSlidesEarlier(Presentation presentation) {
    final selectedIndexes = _selectedIndexes(presentation);
    if (selectedIndexes.isEmpty) return;

    ref.read(slideActionsProvider).moveSlidesEarlier(selectedIndexes);
  }

  void _moveSelectedSlidesLater(Presentation presentation) {
    final selectedIndexes = _selectedIndexes(presentation);
    if (selectedIndexes.isEmpty) return;

    ref.read(slideActionsProvider).moveSlidesLater(selectedIndexes);
  }

  void _deleteSelectedSlides(BuildContext context, Presentation presentation) {
    final selectedIndexes = _selectedIndexes(presentation);
    if (selectedIndexes.isEmpty) return;

    final deleted = ref
        .read(slideActionsProvider)
        .deleteSlides(selectedIndexes);
    if (deleted) {
      _clearSelection();
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A presentation needs at least one slide.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<int> _selectedIndexes(Presentation presentation) {
    return SlideSorterSelectionService.selectedIndexes(
      slides: presentation.slides,
      selection: _selection,
    );
  }
}

/// Modal slide board shell that composes header, search, selection, grid, and footer.
class _SlideSorterSurface extends StatelessWidget {
  final Presentation presentation;
  final List<int> matchingIndexes;
  final String searchValue;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Set<String> selectedSlideIds;
  final int selectedCount;
  final bool canMoveSelectedEarlier;
  final bool canMoveSelectedLater;
  final SlideSorterDensity density;
  final VoidCallback onClose;
  final VoidCallback onOpenCurrent;
  final ValueChanged<SlideSorterDensity> onDensityChanged;
  final ValueChanged<int> onSelectSlide;
  final void Function(int index, bool extendRange) onToggleSlideSelection;
  final VoidCallback onSelectVisibleSlides;
  final VoidCallback onClearSelection;
  final ValueChanged<int> onDuplicateSlide;
  final VoidCallback onDuplicateSelectedSlides;
  final VoidCallback onMoveSelectedSlidesEarlier;
  final VoidCallback onMoveSelectedSlidesLater;
  final ValueChanged<int> onDeleteSlide;
  final VoidCallback onDeleteSelectedSlides;
  final void Function(int oldIndex, int newIndex) onMoveSlide;
  final ValueChanged<int> onColumnCountChanged;

  const _SlideSorterSurface({
    required this.presentation,
    required this.matchingIndexes,
    required this.searchValue,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedSlideIds,
    required this.selectedCount,
    required this.canMoveSelectedEarlier,
    required this.canMoveSelectedLater,
    required this.density,
    required this.onClose,
    required this.onOpenCurrent,
    required this.onDensityChanged,
    required this.onSelectSlide,
    required this.onToggleSlideSelection,
    required this.onSelectVisibleSlides,
    required this.onClearSelection,
    required this.onDuplicateSlide,
    required this.onDuplicateSelectedSlides,
    required this.onMoveSelectedSlidesEarlier,
    required this.onMoveSelectedSlidesLater,
    required this.onDeleteSlide,
    required this.onDeleteSelectedSlides,
    required this.onMoveSlide,
    required this.onColumnCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = presentation.theme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 34,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _SlideSorterHeader(
              presentation: presentation,
              matchingCount: matchingIndexes.length,
              onClose: onClose,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: _SlideSorterSearchField(
                controller: searchController,
                value: searchValue,
                accentColor: theme.primaryColor,
                onChanged: onSearchChanged,
                onClear: onClearSearch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: _SlideSorterSelectionBar(
                selectedCount: selectedCount,
                visibleCount: matchingIndexes.length,
                slideCount: presentation.slides.length,
                canMoveEarlier: canMoveSelectedEarlier,
                canMoveLater: canMoveSelectedLater,
                accentColor: theme.primaryColor,
                onSelectVisible: onSelectVisibleSlides,
                onClearSelection: onClearSelection,
                onDuplicateSelected: onDuplicateSelectedSlides,
                onMoveEarlier: onMoveSelectedSlidesEarlier,
                onMoveLater: onMoveSelectedSlidesLater,
                onDeleteSelected: onDeleteSelectedSlides,
              ),
            ),
            Expanded(
              child: SlideSorterGrid(
                slides: presentation.slides,
                visibleIndexes: matchingIndexes,
                currentSlideIndex: presentation.currentSlideIndex,
                selectedSlideIds: selectedSlideIds,
                theme: theme,
                slideSize: presentation.slideSize,
                density: density,
                canDeleteSlides: presentation.slides.length > 1,
                onSelectSlide: onSelectSlide,
                onToggleSlideSelection: onToggleSlideSelection,
                onDuplicateSlide: onDuplicateSlide,
                onDeleteSlide: onDeleteSlide,
                onMoveSlide: onMoveSlide,
                onColumnCountChanged: onColumnCountChanged,
              ),
            ),
            _SlideSorterFooter(
              currentSlideNumber: presentation.currentSlideIndex + 1,
              slideCount: presentation.slides.length,
              density: density,
              accentColor: theme.primaryColor,
              onClose: onClose,
              onOpenCurrent: onOpenCurrent,
              onDensityChanged: onDensityChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Header row for slide board identity, deck counts, and close action.
class _SlideSorterHeader extends StatelessWidget {
  final Presentation presentation;
  final int matchingCount;
  final VoidCallback onClose;

  const _SlideSorterHeader({
    required this.presentation,
    required this.matchingCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = presentation.theme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.36),
              ),
            ),
            child: Icon(
              Icons.view_module_outlined,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Slide Board',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SorterStatChip(
            label: '${presentation.slides.length} slides',
            accentColor: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          _SorterStatChip(
            label: '$matchingCount shown',
            accentColor: theme.secondaryColor,
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Close slide board',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Compact count badge used in the slide board header.
class _SorterStatChip extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _SorterStatChip({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Search input for filtering slides by title, notes, text, or slide number.
class _SlideSorterSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String value;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SlideSorterSearchField({
    required this.controller,
    required this.value,
    required this.accentColor,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: accentColor,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search slides',
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 17),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 40,
          ),
          suffixIcon: hasValue
              ? IconButton(
                  tooltip: 'Clear slide search',
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 40,
                  ),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Batch-selection command bar for visible, move, duplicate, clear, and delete actions.
class _SlideSorterSelectionBar extends StatelessWidget {
  final int selectedCount;
  final int visibleCount;
  final int slideCount;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final Color accentColor;
  final VoidCallback onSelectVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onDuplicateSelected;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onDeleteSelected;

  const _SlideSorterSelectionBar({
    required this.selectedCount,
    required this.visibleCount,
    required this.slideCount,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.accentColor,
    required this.onSelectVisible,
    required this.onClearSelection,
    required this.onDuplicateSelected,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final canDeleteSelection =
        selectedCount > 0 && slideCount - selectedCount >= 1;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabels = constraints.maxWidth >= 620;
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectionBarAction(
                icon: Icons.select_all,
                label: 'Shown',
                tooltip: 'Select shown slides',
                enabled: visibleCount > 0,
                showLabel: showLabels,
                onPressed: onSelectVisible,
              ),
              const SizedBox(width: 6),
              _SelectionBarAction(
                icon: Icons.backspace_outlined,
                label: 'Clear',
                tooltip: 'Clear slide selection',
                enabled: hasSelection,
                showLabel: showLabels,
                onPressed: onClearSelection,
              ),
              const SizedBox(width: 6),
              _SelectionBarAction(
                icon: Icons.arrow_back,
                label: 'Earlier',
                tooltip: 'Move selected slides earlier',
                enabled: canMoveEarlier,
                showLabel: showLabels,
                onPressed: onMoveEarlier,
              ),
              const SizedBox(width: 6),
              _SelectionBarAction(
                icon: Icons.arrow_forward,
                label: 'Later',
                tooltip: 'Move selected slides later',
                enabled: canMoveLater,
                showLabel: showLabels,
                onPressed: onMoveLater,
              ),
              const SizedBox(width: 6),
              _SelectionBarAction(
                icon: Icons.content_copy_outlined,
                label: 'Copy',
                tooltip: 'Duplicate selected slides',
                enabled: hasSelection,
                showLabel: showLabels,
                onPressed: onDuplicateSelected,
              ),
              const SizedBox(width: 6),
              _SelectionBarAction(
                icon: canDeleteSelection
                    ? Icons.delete_outline
                    : Icons.lock_outline,
                label: 'Delete',
                tooltip: canDeleteSelection
                    ? 'Delete selected slides'
                    : 'Keep at least one slide',
                enabled: canDeleteSelection,
                destructive: canDeleteSelection,
                showLabel: showLabels,
                onPressed: onDeleteSelected,
              ),
            ],
          );

          return Row(
            children: [
              Icon(Icons.checklist, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$selectedCount selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: SingleChildScrollView(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  child: actions,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small reusable command button used by the slide board selection bar.
class _SelectionBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool enabled;
  final bool destructive;
  final bool showLabel;
  final VoidCallback onPressed;

  const _SelectionBarAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
    required this.showLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.white24
        : destructive
        ? const Color(0xFFFCA5A5)
        : Colors.white70;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 30,
        child: showLabel
            ? TextButton.icon(
                onPressed: enabled ? onPressed : null,
                icon: Icon(icon, size: 15),
                label: Text(label),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  disabledForegroundColor: Colors.white24,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              )
            : IconButton(
                onPressed: enabled ? onPressed : null,
                icon: Icon(icon, size: 15, color: color),
                tooltip: tooltip,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: enabled
                      ? Colors.white.withValues(alpha: 0.055)
                      : Colors.white.withValues(alpha: 0.025),
                  disabledBackgroundColor: Colors.white.withValues(
                    alpha: 0.025,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Footer row for current-slide context and modal exit actions.
class _SlideSorterFooter extends StatelessWidget {
  final int currentSlideNumber;
  final int slideCount;
  final SlideSorterDensity density;
  final Color accentColor;
  final VoidCallback onClose;
  final VoidCallback onOpenCurrent;
  final ValueChanged<SlideSorterDensity> onDensityChanged;

  const _SlideSorterFooter({
    required this.currentSlideNumber,
    required this.slideCount,
    required this.density,
    required this.accentColor,
    required this.onClose,
    required this.onOpenCurrent,
    required this.onDensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final status = Row(
            children: [
              Icon(Icons.check_circle, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current $currentSlideNumber of $slideCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
          final densityControl = SlideSorterDensityControl(
            value: density,
            accentColor: accentColor,
            onChanged: onDensityChanged,
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onClose, child: const Text('Close')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onOpenCurrent,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open current'),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor:
                      ThemeData.estimateBrightnessForColor(accentColor) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 560) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 10),
                    densityControl,
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: status),
              densityControl,
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

@Preview(name: 'Slide sorter overlay', size: Size(1040, 720))
Widget slideSorterOverlayPreview() {
  return ProviderScope(
    overrides: [
      presentationProvider.overrideWith(
        (ref) =>
            PresentationNotifier(initialPresentation: _previewPresentation()),
      ),
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF020617),
        body: SlideSorterOverlay(),
      ),
    ),
  );
}

Presentation _previewPresentation() {
  return Presentation(
    id: 'slide-sorter-overlay-preview',
    title: 'Quarter Story',
    currentSlideIndex: 1,
    slides: [
      _previewSlide('slide-1', 'Opening', const Color(0xFF111827)),
      _previewSlide('slide-2', 'Audience need', const Color(0xFF0F766E)),
      _previewSlide('slide-3', 'Quarter plan', const Color(0xFF1D4ED8)),
      _previewSlide('slide-4', 'Close', const Color(0xFF4338CA)),
    ],
    theme: PresentationTheme(
      id: 'sorter-overlay-preview-theme',
      name: 'Sorter Overlay Preview',
      primaryColor: const Color(0xFF38BDF8),
      secondaryColor: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
    ),
  );
}

Slide _previewSlide(String id, String title, Color color) {
  return Slide(
    id: id,
    title: title,
    backgroundColor: color,
    components: [
      PresentationComponent(
        id: '$id-title',
        type: ComponentType.shape,
        position: const Offset(160, 130),
        size: const Size(860, 110),
        zIndex: 1,
        backgroundColor: Colors.white,
      ),
      PresentationComponent(
        id: '$id-chart',
        type: ComponentType.chart,
        position: const Offset(920, 360),
        size: const Size(600, 360),
        zIndex: 2,
      ),
    ],
  );
}
