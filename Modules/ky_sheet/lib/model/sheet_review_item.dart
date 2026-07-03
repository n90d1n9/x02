import 'cell/cell_address.dart';

enum SheetReviewItemKind { comment, hyperlink }

extension SheetReviewItemKindLabel on SheetReviewItemKind {
  String get label {
    return switch (this) {
      SheetReviewItemKind.comment => 'Comment',
      SheetReviewItemKind.hyperlink => 'Hyperlink',
    };
  }

  String get pluralLabel {
    return switch (this) {
      SheetReviewItemKind.comment => 'Comments',
      SheetReviewItemKind.hyperlink => 'Hyperlinks',
    };
  }
}

class SheetReviewItem {
  const SheetReviewItem({
    required this.kind,
    required this.address,
    required this.text,
    required this.cellValue,
  });

  final SheetReviewItemKind kind;
  final CellAddress address;
  final String text;
  final String cellValue;

  String get label => '${address.label} ${kind.label}';

  String get preview {
    final trimmed = text.trim();
    if (trimmed.length <= 72) return trimmed;
    return '${trimmed.substring(0, 69)}...';
  }

  String get valueLabel {
    final trimmed = cellValue.trim();
    if (trimmed.isEmpty) return 'Blank cell';
    if (trimmed.length <= 40) return trimmed;
    return '${trimmed.substring(0, 37)}...';
  }
}

class SheetReviewSummary {
  const SheetReviewSummary({
    required this.items,
    required this.commentCount,
    required this.hyperlinkCount,
  });

  final List<SheetReviewItem> items;
  final int commentCount;
  final int hyperlinkCount;

  int get totalCount => items.length;
  bool get isEmpty => totalCount == 0;
}
