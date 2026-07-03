/// Immutable selection state for the Slide Board multi-select workflow.
class SlideSorterSelection {
  final Set<String> selectedSlideIds;
  final String? anchorSlideId;

  SlideSorterSelection({
    Set<String> selectedSlideIds = const <String>{},
    this.anchorSlideId,
  }) : selectedSlideIds = Set.unmodifiable(selectedSlideIds);

  bool get isEmpty => selectedSlideIds.isEmpty;

  SlideSorterSelection copyWith({
    Set<String>? selectedSlideIds,
    Object? anchorSlideId = _unchanged,
  }) {
    return SlideSorterSelection(
      selectedSlideIds: selectedSlideIds ?? this.selectedSlideIds,
      anchorSlideId: identical(anchorSlideId, _unchanged)
          ? this.anchorSlideId
          : anchorSlideId as String?,
    );
  }

  static const _unchanged = Object();
}
