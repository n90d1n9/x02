/// Identifies a supported document page size for print and export layouts.
enum PageSize { a4, letter, legal }

/// Provides compact display labels for supported page sizes.
extension PageSizeLabel on PageSize {
  String get label {
    return switch (this) {
      PageSize.a4 => 'A4',
      PageSize.letter => 'Letter',
      PageSize.legal => 'Legal',
    };
  }

  String get shortLabel {
    return switch (this) {
      PageSize.a4 => 'A4',
      PageSize.letter => 'LTR',
      PageSize.legal => 'LGL',
    };
  }
}
