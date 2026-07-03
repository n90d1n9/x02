/// Conditional Formatting Manager
/// 
/// Manages conditional formatting rules for ranges in a spreadsheet.
/// Handles rule evaluation, application, and persistence.

import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/conditional_formatting_rule.dart';

/// Manager for conditional formatting rules
class ConditionalFormattingManager {
  final Map<String, List<ConditionalFormattingRule>> _rulesByRange = {};
  final Map<String, List<ConditionalFormattingRule>> _rulesBySheet = {};

  /// Add a rule to a range
  void addRule(String rangeAddress, ConditionalFormattingRule rule) {
    if (!_rulesByRange.containsKey(rangeAddress)) {
      _rulesByRange[rangeAddress] = [];
    }
    _rulesByRange[rangeAddress]!.add(rule);
    
    // Also index by sheet for faster lookup
    final sheetName = _extractSheetName(rangeAddress);
    if (!_rulesBySheet.containsKey(sheetName)) {
      _rulesBySheet[sheetName] = [];
    }
    _rulesBySheet[sheetName]!.add(rule);
  }

  /// Remove a rule by ID from a range
  void removeRule(String rangeAddress, String ruleId) {
    if (_rulesByRange.containsKey(rangeAddress)) {
      _rulesByRange[rangeAddress]!.removeWhere((rule) => rule.id == ruleId);
      if (_rulesByRange[rangeAddress]!.isEmpty) {
        _rulesByRange.remove(rangeAddress);
      }
    }
    
    // Remove from sheet index
    _rulesBySheet.forEach((sheet, rules) {
      rules.removeWhere((rule) => rule.id == ruleId);
      if (rules.isEmpty) {
        _rulesBySheet.remove(sheet);
      }
    });
  }

  /// Get all rules for a range
  List<ConditionalFormattingRule> getRules(String rangeAddress) {
    return _rulesByRange[rangeAddress] ?? [];
  }

  /// Get all rules for a sheet
  List<ConditionalFormattingRule> getRulesForSheet(String sheetName) {
    return _rulesBySheet[sheetName] ?? [];
  }

  /// Clear all rules for a range
  void clearRules(String rangeAddress) {
    final rules = _rulesByRange[rangeAddress];
    if (rules != null) {
      // Remove from sheet index
      rules.forEach((rule) {
        _rulesBySheet.forEach((sheet, sheetRules) {
          sheetRules.removeWhere((r) => r.id == rule.id);
        });
      });
      _rulesByRange.remove(rangeAddress);
    }
  }

  /// Clear all rules for a sheet
  void clearRulesForSheet(String sheetName) {
    final rules = _rulesBySheet[sheetName];
    if (rules != null) {
      rules.forEach((rule) {
        _rulesByRange.forEach((range, rangeRules) {
          rangeRules.removeWhere((r) => r.id == rule.id);
        });
      });
      _rulesBySheet.remove(sheetName);
    }
  }

  /// Evaluate and apply conditional formatting to a cell
  CellStyle? evaluateCell(
    String cellAddress,
    dynamic cellValue,
    String sheetName,
    Function(String address)? getCellValue,
  ) {
    final rules = getRulesForSheet(sheetName);
    if (rules.isEmpty) return null;

    // Sort rules by priority (higher priority first)
    final sortedRules = List<ConditionalFormattingRule>.from(rules)
      ..sort((a, b) {
        final priorityA = int.tryParse(a.priority ?? '0') ?? 0;
        final priorityB = int.tryParse(b.priority ?? '0') ?? 0;
        return priorityB.compareTo(priorityA);
      });

    CellStyle? appliedStyle;
    bool stopProcessing = false;

    for (final rule in sortedRules) {
      // Check if this rule applies to the cell's range
      if (!_cellInRange(cellAddress, _getRangeForRule(rule))) continue;

      final context = EvaluationContext(
        cellValue: cellValue,
        cellAddress: cellAddress,
        sheetName: sheetName,
        getCellValue: getCellValue,
      );

      if (rule.evaluate(cellValue, context)) {
        if (appliedStyle == null) {
          appliedStyle = CellStyle();
        }
        appliedStyle = rule.applyFormat(appliedStyle!);
        
        if (rule.stopIfTrue == true) {
          stopProcessing = true;
          break;
        }
      }
    }

    return stopProcessing || appliedStyle != null ? appliedStyle : null;
  }

  /// Batch evaluate rules for a range of cells
  Map<String, CellStyle> evaluateRange(
    String rangeAddress,
    Map<String, dynamic> cellValues,
    String sheetName,
    Function(String address)? getCellValue,
  ) {
    final result = <String, CellStyle>{};
    final rules = getRulesForSheet(sheetName);
    
    if (rules.isEmpty) return result;

    // Sort rules by priority
    final sortedRules = List<ConditionalFormattingRule>.from(rules)
      ..sort((a, b) {
        final priorityA = int.tryParse(a.priority ?? '0') ?? 0;
        final priorityB = int.tryParse(b.priority ?? '0') ?? 0;
        return priorityB.compareTo(priorityA);
      });

    // Pre-calculate rank information for top/bottom rules
    final allValues = cellValues.values.whereType<num>().toList();
    allValues.sort();
    
    cellValues.forEach((address, value) {
      if (!_cellInRange(address, rangeAddress)) return;

      CellStyle? appliedStyle;
      bool stopProcessing = false;

      for (final rule in sortedRules) {
        final rank = allValues.indexOf(value as num);
        final context = EvaluationContext(
          cellValue: value,
          cellAddress: address,
          sheetName: sheetName,
          rangeValues: allValues,
          rank: rank + 1,
          totalCount: allValues.length,
          getCellValue: getCellValue,
        );

        if (rule.evaluate(value, context)) {
          if (appliedStyle == null) {
            appliedStyle = CellStyle();
          }
          appliedStyle = rule.applyFormat(appliedStyle!);
          
          if (rule.stopIfTrue == true) {
            stopProcessing = true;
            break;
          }
        }
      }

      if (appliedStyle != null) {
        result[address] = appliedStyle;
      }
    });

    return result;
  }

  /// Serialize all rules to JSON
  String toJson() {
    final data = <String, dynamic>{};
    _rulesByRange.forEach((range, rules) {
      data[range] = rules.map((r) => r.toJson()).toList();
    });
    return jsonEncode(data);
  }

  /// Load rules from JSON
  void fromJson(String jsonString) {
    _rulesByRange.clear();
    _rulesBySheet.clear();
    
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    data.forEach((range, rulesJson) {
      final rulesList = rulesJson as List;
      _rulesByRange[range] = rulesList
          .map((r) => ConditionalFormattingRule.fromJson(r))
          .toList();
      
      // Rebuild sheet index
      final sheetName = _extractSheetName(range);
      if (!_rulesBySheet.containsKey(sheetName)) {
        _rulesBySheet[sheetName] = [];
      }
      _rulesBySheet[sheetName]!.addAll(_rulesByRange[range]!);
    });
  }

  /// Clear all rules
  void clear() {
    _rulesByRange.clear();
    _rulesBySheet.clear();
  }

  /// Check if a cell address is within a range
  bool _cellInRange(String cellAddress, String rangeAddress) {
    // Simple implementation - assumes format like "A1:B10" or "Sheet1!A1:B10"
    final cleanRange = rangeAddress.contains('!') 
        ? rangeAddress.split('!').last 
        : rangeAddress;
    
    if (!cleanRange.contains(':')) {
      return cellAddress == cleanRange;
    }

    final parts = cleanRange.split(':');
    if (parts.length != 2) return false;

    final startCol = _columnToNumber(parts[0].replaceAll(RegExp(r'\d'), ''));
    final startRow = int.tryParse(parts[0].replaceAll(RegExp(r'[A-Z]'), '')) ?? 0;
    final endCol = _columnToNumber(parts[1].replaceAll(RegExp(r'\d'), ''));
    final endRow = int.tryParse(parts[1].replaceAll(RegExp(r'[A-Z]'), '')) ?? 0;

    final cellCol = _columnToNumber(cellAddress.replaceAll(RegExp(r'\d'), ''));
    final cellRow = int.tryParse(cellAddress.replaceAll(RegExp(r'[A-Z]'), '')) ?? 0;

    return cellCol >= startCol &&
        cellCol <= endCol &&
        cellRow >= startRow &&
        cellRow <= endRow;
  }

  /// Convert column letter to number (A=1, B=2, ..., Z=26, AA=27, etc.)
  int _columnToNumber(String col) {
    var result = 0;
    for (var i = 0; i < col.length; i++) {
      result = result * 26 + (col.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    return result;
  }

  /// Extract sheet name from range address
  String _extractSheetName(String rangeAddress) {
    if (rangeAddress.contains('!')) {
      return rangeAddress.split('!').first;
    }
    return 'Sheet1'; // Default sheet name
  }

  /// Get range address for a rule (simplified - in reality would need to track this)
  String _getRangeForRule(ConditionalFormattingRule rule) {
    // This is a simplification - in a full implementation, we'd store the range with each rule
    return ''; 
  }
}
