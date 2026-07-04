# Testing Strategy for ky_sheet

## Overview
This document outlines the comprehensive testing strategy to ensure ky_sheet achieves Excel/Google Sheets parity with robust, maintainable code.

## Test Pyramid Structure

### 1. Unit Tests (70% - Foundation)
**Location:** `test/core/`, `test/services/`, `test/commands/`

**Purpose:** Test individual components in isolation
- **Commands:** Verify execute/undo/redo logic
- **Services:** Validate business logic without UI
- **Models:** Ensure data integrity and serialization
- **Utilities:** Test helper functions and parsers

**Example Coverage:**
```dart
// test/core/commands/command_test.dart
- SetCellValueCommand execution
- Undo/redo stack management
- Batch command transactions
- Command history limits

// test/core/services/file_service_test.dart
- Workbook create/open/save flows
- CSV import/export
- Error handling (file not found, corrupt files)
- State machine transitions
```

### 2. Widget Tests (20% - Integration)
**Location:** `test/features/*/widgets/`

**Purpose:** Test UI components in isolation with mocked dependencies
- **Cell Rendering:** Verify cell display, formatting, selection states
- **Grid Navigation:** Test keyboard navigation, scrolling behavior
- **Formula Bar:** Validate input handling, autocomplete display
- **Menu Interactions:** Test dropdown behaviors, command triggering
- **Dialog Components:** Verify form validation, submit/cancel flows

**Best Practices:**
- Mock all services and state managers
- Use `pumpWidget` with ProviderScope for Riverpod tests
- Test user interactions (tap, drag, type)
- Verify visual states (enabled, disabled, error)

### 3. Integration Tests (10% - End-to-End)
**Location:** `test/integration/`

**Purpose:** Test complete user workflows across multiple layers
- **File Operations:** Create → Edit → Save → Reopen → Verify
- **Formula Calculation:** Enter formula → Verify result → Undo → Verify revert
- **Formatting Pipeline:** Select range → Apply format → Verify rendering
- **Multi-sheet Operations:** Add sheet → Move sheet → Delete sheet
- **Collaboration Sync:** User A edits → User B sees update (future)

## Running Tests

### Full Test Suite
```bash
flutter test
```

### Specific Directory
```bash
flutter test test/core/commands/
flutter test test/core/services/
flutter test test/features/grid/
```

### Single File with Coverage
```bash
flutter test --coverage test/core/commands/command_test.dart
genhtml coverage/lcov.info -o coverage/html
```

### Watch Mode (Development)
```bash
flutter test --watch
```

## Test Quality Standards

### Naming Conventions
```dart
test('executes and sets cell value', () { ... });
test('undo reverts cell value', () { ... });
test('handles file not found error', () { ... });
```

**Format:** `[action] [expected outcome]` or `[scenario] [behavior]`

### Arrange-Act-Assert Pattern
```dart
test('example', () {
  // Arrange
  final service = MockService();
  final command = TestCommand(service);
  
  // Act
  command.execute();
  
  // Assert
  expect(service.wasCalled, isTrue);
});
```

### Mock Guidelines
- Use manual mocks for simple interfaces (see `MockSpreadsheetService`)
- Use `mockito` package for complex dependencies
- Never mock value objects or models
- Always verify mock interactions when order matters

### Coverage Goals
| Component Type | Minimum Coverage | Target Coverage |
|---------------|------------------|-----------------|
| Commands      | 95%              | 100%            |
| Services      | 90%              | 95%             |
| Models        | 85%              | 90%             |
| Widgets       | 70%              | 80%             |
| **Overall**   | **80%**          | **90%**         |

## Continuous Integration

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: flutter-test
        name: Run Flutter Tests
        entry: flutter test
        language: system
        pass_filenames: false
```

### GitHub Actions Workflow
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

## Future Testing Enhancements

### Golden Tests (Visual Regression)
- Capture widget screenshots as baselines
- Detect unintended visual changes
- Test grid rendering, chart appearance, theme consistency

### Performance Tests
- Benchmark large dataset operations (10k+ rows)
- Measure undo/redo stack performance
- Profile memory usage during extended sessions

### Property-Based Testing
- Use `package:property_testing` for formula evaluation
- Generate random spreadsheets to find edge cases
- Fuzz test file import/export with malformed data

### Accessibility Tests
- Verify screen reader compatibility
- Test keyboard-only navigation flows
- Validate color contrast ratios

## Current Test Files

| File | Coverage Area | Status |
|------|---------------|--------|
| `test/core/commands/command_test.dart` | Command pattern, undo/redo | ✅ Created |
| `test/core/services/file_service_test.dart` | File I/O, state machine | ✅ Created |
| `test/ky_sheet_test.dart` | Legacy integration tests | ⚠️ Needs refactoring |

## Next Steps

1. **Immediate:** Run new tests to verify they pass
   ```bash
   flutter test test/core/commands/command_test.dart
   flutter test test/core/services/file_service_test.dart
   ```

2. **Short-term:** Add widget tests for critical UI components
   - Cell editor overlay
   - Grid viewport
   - Formula bar
   - File menu dialog

3. **Medium-term:** Build integration test suite
   - Complete user workflows
   - Cross-feature interactions
   - Error recovery scenarios

4. **Long-term:** Implement CI/CD pipeline with coverage reporting
