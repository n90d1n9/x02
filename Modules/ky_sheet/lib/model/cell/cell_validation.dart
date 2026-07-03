import 'package:intl/intl.dart';

enum ValidationType {
  none,
  number,
  date,
  list,
  email,
  url,
  required,
  phone,
  regex,
  minLength,
  maxLength,
  min,
  max,
  custom,
}

class CellValidation {
  final ValidationType type;
  final String? min;
  final String? max;
  final List<String>? options;
  final String? errorMessage;
  final String? pattern; // For regex validation

  CellValidation({
    required this.type,
    this.min,
    this.max,
    this.options,
    this.errorMessage,
    this.pattern,
  });

  bool validate(String value) {
    // Handle empty values based on validation type
    if (value.isEmpty) {
      return type != ValidationType.required;
    }

    switch (type) {
      case ValidationType.number:
        return _validateNumber(value);
      case ValidationType.list:
        return options?.contains(value) ?? false;
      case ValidationType.date:
        return _validateDate(value);
      case ValidationType.email:
        return _validateEmail(value);
      case ValidationType.url:
        return _validateUrl(value);
      case ValidationType.required:
        return value.trim().isNotEmpty;
      case ValidationType.phone:
        return _validatePhone(value);
      case ValidationType.regex:
        return _validateRegex(value);
      case ValidationType.minLength:
        return _validateMinLength(value);
      case ValidationType.maxLength:
        return _validateMaxLength(value);
      case ValidationType.min:
        return _validateMin(value);
      case ValidationType.max:
        return _validateMax(value);
      case ValidationType.custom:
        return _validateCustom(value);
      case ValidationType.none:
        return true;
    }
  }

  bool _validateNumber(String value) {
    final num = double.tryParse(value);
    if (num == null) return false;
    if (min != null && num < double.parse(min!)) return false;
    if (max != null && num > double.parse(max!)) return false;
    return true;
  }

  bool _validateDate(String value) {
    // Try various date formats
    final dateFormats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'dd-MM-yyyy',
    ];

    for (final format in dateFormats) {
      try {
        final date = DateFormat(format).parseStrict(value);

        // Check min date if provided
        if (min != null) {
          final minDate = DateTime.tryParse(min!);
          if (minDate != null && date.isBefore(minDate)) return false;
        }
        // Check max date if provided
        if (max != null) {
          final maxDate = DateTime.tryParse(max!);
          if (maxDate != null && date.isAfter(maxDate)) return false;
        }
        return true;
      } catch (e) {
        // Try next format
      }
    }
    return false;
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    return emailRegex.hasMatch(value.trim());
  }

  bool _validateUrl(String value) {
    // Add protocol if missing for validation
    String urlToValidate = value;
    if (!urlToValidate.toLowerCase().startsWith('http://') &&
        !urlToValidate.toLowerCase().startsWith('https://')) {
      urlToValidate = 'https://$urlToValidate';
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?' // protocol
      r'([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}' // domain
      r'(:[0-9]{1,5})?' // port
      r'(\/[^\s]*)?$', // path
    );
    return urlRegex.hasMatch(urlToValidate);
  }

  bool _validatePhone(String value) {
    // Remove common separators
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // International phone regex (simplified)
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]{10,15}$');

    // Basic length check
    if (cleanPhone.length < 10 || cleanPhone.length > 15) return false;

    // Check if it's all numbers (after cleaning)
    return phoneRegex.hasMatch(value) &&
        RegExp(r'^[\d\+]').hasMatch(cleanPhone);
  }

  bool _validateRegex(String value) {
    if (pattern == null || pattern!.isEmpty) return true;
    try {
      final regex = RegExp(pattern!);
      return regex.hasMatch(value);
    } catch (e) {
      // Invalid regex pattern
      return false;
    }
  }

  bool _validateMinLength(String value) {
    if (min == null) return true;
    final minLength = int.tryParse(min!);
    return minLength != null && value.length >= minLength;
  }

  bool _validateMaxLength(String value) {
    if (max == null) return true;
    final maxLength = int.tryParse(max!);
    return maxLength != null && value.length <= maxLength;
  }

  bool _validateMin(String value) {
    if (min == null) return true;

    // Try parsing as number first
    final numValue = double.tryParse(value);
    if (numValue != null) {
      final minNum = double.tryParse(min!);
      return minNum != null && numValue >= minNum;
    }

    // Try as date
    final dateValue = DateTime.tryParse(value);
    if (dateValue != null) {
      final minDate = DateTime.tryParse(min!);
      return minDate != null && !dateValue.isBefore(minDate);
    }

    // As string length
    return value.length >= (int.tryParse(min!) ?? 0);
  }

  bool _validateMax(String value) {
    if (max == null) return true;

    // Try parsing as number first
    final numValue = double.tryParse(value);
    if (numValue != null) {
      final maxNum = double.tryParse(max!);
      return maxNum != null && numValue <= maxNum;
    }

    // Try as date
    final dateValue = DateTime.tryParse(value);
    if (dateValue != null) {
      final maxDate = DateTime.tryParse(max!);
      return maxDate != null && !dateValue.isAfter(maxDate);
    }

    // As string length
    return value.length <= (int.tryParse(max!) ?? 0);
  }

  bool _validateCustom(String value) {
    // For custom validation, you could implement custom logic here
    // This could be extended to support custom validation functions
    // For now, we'll return true and assume custom validation is handled elsewhere
    return true;
  }

  Map<String, dynamic> toJson() => {
    'type': type.index,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (options != null) 'options': options,
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (pattern != null) 'pattern': pattern,
  };

  factory CellValidation.fromJson(Map<String, dynamic> json) => CellValidation(
    type: ValidationType.values[json['type'] ?? 0],
    min: json['min'],
    max: json['max'],
    options: json['options']?.cast<String>(),
    errorMessage: json['errorMessage'],
    pattern: json['pattern'],
  );

  @override
  String toString() {
    switch (type) {
      case ValidationType.number:
        final minStr = min ?? '∞';
        final maxStr = max ?? '∞';
        return 'Number between $minStr and $maxStr';
      case ValidationType.list:
        return 'One of: ${options?.join(', ') ?? ''}';
      case ValidationType.date:
        String range = '';
        if (min != null || max != null) {
          range = ' (${min ?? 'any'} to ${max ?? 'any'})';
        }
        return 'Date$range';
      case ValidationType.email:
        return 'Email address';
      case ValidationType.url:
        return 'URL';
      case ValidationType.required:
        return 'Required field';
      case ValidationType.phone:
        return 'Phone number';
      case ValidationType.regex:
        return 'Matches pattern: ${pattern ?? ''}';
      case ValidationType.minLength:
        return 'Minimum length: ${min ?? ''}';
      case ValidationType.maxLength:
        return 'Maximum length: ${max ?? ''}';
      case ValidationType.min:
        return 'Minimum value: ${min ?? ''}';
      case ValidationType.max:
        return 'Maximum value: ${max ?? ''}';
      case ValidationType.custom:
        return 'Custom validation';
      case ValidationType.none:
        return 'No validation';
    }
  }

  CellValidation copyWith({
    ValidationType? type,
    String? min,
    String? max,
    List<String>? options,
    String? errorMessage,
    String? pattern,
  }) {
    return CellValidation(
      type: type ?? this.type,
      min: min ?? this.min,
      max: max ?? this.max,
      options: options ?? this.options,
      errorMessage: errorMessage ?? this.errorMessage,
      pattern: pattern ?? this.pattern,
    );
  }
}
