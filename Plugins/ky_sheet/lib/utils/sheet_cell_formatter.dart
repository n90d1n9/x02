import 'package:intl/intl.dart' as intl;

import '../model/cell/cell_data.dart';
import '../model/number_format.dart';

class SheetCellFormatter {
  SheetCellFormatter._();

  static final intl.NumberFormat _numberFormatter = intl.NumberFormat(
    '#,##0.##',
    'en_US',
  );
  static final intl.NumberFormat _currencyFormatter =
      intl.NumberFormat.currency(locale: 'en_US', symbol: r'$');
  static final intl.NumberFormat _percentFormatter = intl.NumberFormat(
    '#,##0.##%',
    'en_US',
  );
  static final intl.DateFormat _dateFormatter = intl.DateFormat.yMMMd('en_US');

  static String displayValue(CellData cellData) {
    final rawValue = cellData.value;
    final format = cellData.style.numberFormat;

    switch (format) {
      case SheetNumberFormatId.number:
        return _formatNumber(rawValue, _numberFormatter);
      case SheetNumberFormatId.currency:
        return _formatNumber(rawValue, _currencyFormatter);
      case SheetNumberFormatId.percent:
        return _formatNumber(rawValue, _percentFormatter);
      case SheetNumberFormatId.date:
        return _formatDate(rawValue);
      case SheetNumberFormatId.general:
      case null:
      default:
        return rawValue;
    }
  }

  static String _formatNumber(String rawValue, intl.NumberFormat formatter) {
    final value = double.tryParse(rawValue.trim());
    if (value == null || !value.isFinite) return rawValue;

    return formatter.format(value == -0 ? 0 : value);
  }

  static String _formatDate(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return rawValue;

    final date = DateTime.tryParse(value);
    if (date == null) return rawValue;

    return _dateFormatter.format(date);
  }
}
