class EntityInfo {
  final int id;
  final String name;
  final String type;
  final String address;
  final String contacts;
  final String website;
  final String rccm;
  final String nif;
  final String currency;
  final String exercice;
  final String plan;
  final String legalResponsible;
  final String targetRevenue;
  final String capacity;
  final String timezone;
  final String logoPath;

  const EntityInfo({
    this.id = 1,
    required this.name,
    required this.type,
    required this.address,
    required this.contacts,
    required this.website,
    required this.rccm,
    required this.nif,
    required this.currency,
    required this.exercice,
    required this.plan,
    required this.legalResponsible,
    required this.targetRevenue,
    required this.capacity,
    required this.timezone,
    required this.logoPath,
  });

  EntityInfo copyWith({
    int? id,
    String? name,
    String? type,
    String? address,
    String? contacts,
    String? website,
    String? rccm,
    String? nif,
    String? currency,
    String? exercice,
    String? plan,
    String? legalResponsible,
    String? targetRevenue,
    String? capacity,
    String? timezone,
    String? logoPath,
  }) {
    return EntityInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      contacts: contacts ?? this.contacts,
      website: website ?? this.website,
      rccm: rccm ?? this.rccm,
      nif: nif ?? this.nif,
      currency: currency ?? this.currency,
      exercice: exercice ?? this.exercice,
      plan: plan ?? this.plan,
      legalResponsible: legalResponsible ?? this.legalResponsible,
      targetRevenue: targetRevenue ?? this.targetRevenue,
      capacity: capacity ?? this.capacity,
      timezone: timezone ?? this.timezone,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  factory EntityInfo.fromMap(Map<String, dynamic> map) {
    return EntityInfo(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      address: map['address'] as String? ?? '',
      contacts: map['contacts'] as String? ?? '',
      website: map['website'] as String? ?? '',
      rccm: map['rccm'] as String? ?? '',
      nif: map['nif'] as String? ?? '',
      currency: map['currency'] as String? ?? '',
      exercice: map['exercice'] as String? ?? '',
      plan: map['plan'] as String? ?? '',
      legalResponsible: map['legalResponsible'] as String? ?? '',
      targetRevenue: map['targetRevenue'] as String? ?? '',
      capacity: map['capacity'] as String? ?? '',
      timezone: map['timezone'] as String? ?? '',
      logoPath: map['logoPath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'contacts': contacts,
      'website': website,
      'rccm': rccm,
      'nif': nif,
      'currency': currency,
      'exercice': exercice,
      'plan': plan,
      'legalResponsible': legalResponsible,
      'targetRevenue': targetRevenue,
      'capacity': capacity,
      'timezone': timezone,
      'logoPath': logoPath,
    };
  }
}
