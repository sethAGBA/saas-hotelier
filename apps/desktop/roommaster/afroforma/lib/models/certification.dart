import 'dart:convert';

class Certification {
  final String name;
  final DateTime? expiryDate;

  Certification({
    required this.name,
    this.expiryDate,
  });

  Certification copyWith({
    String? name,
    DateTime? expiryDate,
  }) {
    return Certification(
      name: name ?? this.name,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      name: map['name'] ?? '',
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Certification.fromJson(String source) => Certification.fromMap(json.decode(source));

  @override
  String toString() => 'Certification(name: $name, expiryDate: $expiryDate)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Certification &&
        other.name == name &&
        other.expiryDate == expiryDate;
  }

  @override
  int get hashCode => name.hashCode ^ expiryDate.hashCode;
}