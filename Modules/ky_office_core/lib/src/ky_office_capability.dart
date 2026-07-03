enum KyOfficeCapabilityType {
  create,
  edit,
  view,
  import,
  export,
  collaborate,
  analyze,
  present,
  automate,
}

class KyOfficeCapability {
  const KyOfficeCapability({
    required this.id,
    required this.label,
    required this.type,
  });

  final String id;
  final String label;
  final KyOfficeCapabilityType type;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KyOfficeCapability &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            label == other.label &&
            type == other.type;
  }

  @override
  int get hashCode => Object.hash(id, label, type);
}

abstract final class KyOfficeCapabilities {
  static const create = KyOfficeCapability(
    id: 'create',
    label: 'Create',
    type: KyOfficeCapabilityType.create,
  );

  static const edit = KyOfficeCapability(
    id: 'edit',
    label: 'Edit',
    type: KyOfficeCapabilityType.edit,
  );

  static const view = KyOfficeCapability(
    id: 'view',
    label: 'View',
    type: KyOfficeCapabilityType.view,
  );

  static const import = KyOfficeCapability(
    id: 'import',
    label: 'Import',
    type: KyOfficeCapabilityType.import,
  );

  static const export = KyOfficeCapability(
    id: 'export',
    label: 'Export',
    type: KyOfficeCapabilityType.export,
  );

  static const collaborate = KyOfficeCapability(
    id: 'collaborate',
    label: 'Collaborate',
    type: KyOfficeCapabilityType.collaborate,
  );

  static const analyze = KyOfficeCapability(
    id: 'analyze',
    label: 'Analyze',
    type: KyOfficeCapabilityType.analyze,
  );

  static const present = KyOfficeCapability(
    id: 'present',
    label: 'Present',
    type: KyOfficeCapabilityType.present,
  );

  static const automate = KyOfficeCapability(
    id: 'automate',
    label: 'Automate',
    type: KyOfficeCapabilityType.automate,
  );
}
