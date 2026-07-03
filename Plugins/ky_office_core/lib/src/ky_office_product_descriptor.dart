import 'ky_office_capability.dart';

enum KyOfficeProductKind { document, spreadsheet, presentation, pdf }

class KyOfficeProductDescriptor {
  const KyOfficeProductDescriptor({
    required this.id,
    required this.packageName,
    required this.displayName,
    required this.shortName,
    required this.familyName,
    required this.kind,
    required this.routeSegment,
    required this.summary,
    required this.capabilities,
  });

  final String id;
  final String packageName;
  final String displayName;
  final String shortName;
  final String familyName;
  final KyOfficeProductKind kind;
  final String routeSegment;
  final String summary;
  final List<KyOfficeCapability> capabilities;

  String get qualifiedName => '$familyName $displayName';

  bool supports(String capabilityId) {
    return capabilities.any((capability) => capability.id == capabilityId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KyOfficeProductDescriptor &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            packageName == other.packageName &&
            displayName == other.displayName &&
            shortName == other.shortName &&
            familyName == other.familyName &&
            kind == other.kind &&
            routeSegment == other.routeSegment &&
            summary == other.summary &&
            _capabilitiesEqual(capabilities, other.capabilities);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      packageName,
      displayName,
      shortName,
      familyName,
      kind,
      routeSegment,
      summary,
      Object.hashAll(capabilities),
    );
  }

  static bool _capabilitiesEqual(
    List<KyOfficeCapability> first,
    List<KyOfficeCapability> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index += 1) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}
