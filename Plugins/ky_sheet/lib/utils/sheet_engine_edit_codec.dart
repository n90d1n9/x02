import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_style.dart';
import 'sheet_engine_codec.dart';

class SheetEngineEditCodec {
  const SheetEngineEditCodec._();

  static const schemaVersion = 1;
  static const engine = 'sheet';

  static Map<String, dynamic> setCell(CellAddress address, CellData cell) {
    return setCellRaw(address, rawContent(cell));
  }

  static Map<String, dynamic> setCellRaw(
    CellAddress address,
    String rawContent,
  ) {
    return {
      'SetCell': {
        'position': encodePosition(address),
        'raw_content': rawContent,
      },
    };
  }

  static Map<String, dynamic> clearCell(CellAddress address) {
    return {
      'ClearCell': {'position': encodePosition(address)},
    };
  }

  static Map<String, dynamic> setCellFormat(
    CellAddress address,
    CellStyle style,
  ) {
    return {
      'SetCellFormat': {
        'position': encodePosition(address),
        'format': SheetEngineCodec.encodeCellFormat(style),
      },
    };
  }

  static String recalculate() => 'Recalculate';

  static Map<String, dynamic> operation({
    required String operationId,
    required String documentId,
    required String actorId,
    required int sequence,
    required int timestampMs,
    required Object edit,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'schema_version': schemaVersion,
      'operation_id': operationId,
      'engine': engine,
      'document_id': documentId,
      'actor_id': actorId,
      'sequence': sequence,
      'timestamp_ms': timestampMs,
      'edit': edit,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  static Map<String, dynamic> operationLog(
    Iterable<Map<String, dynamic>> operations, {
    Map<String, dynamic>? metadata,
  }) {
    return {
      'schema_version': schemaVersion,
      'operations': operations.toList(growable: false),
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  static Map<String, dynamic> encodePosition(CellAddress address) {
    return {'col': address.col, 'row': address.row};
  }

  static String rawContent(CellData cell) {
    final formula = cell.formula;
    if (formula != null && formula.isNotEmpty) return formula;
    return cell.value;
  }
}
