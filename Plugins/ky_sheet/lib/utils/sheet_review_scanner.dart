import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_review_item.dart';

class SheetReviewScanner {
  const SheetReviewScanner._();

  static SheetReviewSummary scan(Map<CellAddress, CellData> cells) {
    final items = <SheetReviewItem>[];
    var commentCount = 0;
    var hyperlinkCount = 0;

    final entries = cells.entries.toList()
      ..sort((left, right) {
        final rowCompare = left.key.row.compareTo(right.key.row);
        return rowCompare == 0
            ? left.key.col.compareTo(right.key.col)
            : rowCompare;
      });

    for (final entry in entries) {
      final cell = entry.value;
      final comment = cell.comment?.trim();
      if (comment != null && comment.isNotEmpty) {
        commentCount++;
        items.add(
          SheetReviewItem(
            kind: SheetReviewItemKind.comment,
            address: entry.key,
            text: comment,
            cellValue: cell.value,
          ),
        );
      }

      final hyperlink = cell.hyperlink?.trim();
      if (hyperlink != null && hyperlink.isNotEmpty) {
        hyperlinkCount++;
        items.add(
          SheetReviewItem(
            kind: SheetReviewItemKind.hyperlink,
            address: entry.key,
            text: hyperlink,
            cellValue: cell.value,
          ),
        );
      }
    }

    return SheetReviewSummary(
      items: items,
      commentCount: commentCount,
      hyperlinkCount: hyperlinkCount,
    );
  }
}
