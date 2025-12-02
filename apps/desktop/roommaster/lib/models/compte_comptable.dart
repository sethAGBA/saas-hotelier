class CompteComptable {
  final String id;
  final String code;
  final String title;
  final String? parentId;
  final bool isArchived;

  const CompteComptable({
    required this.id,
    required this.code,
    required this.title,
    this.parentId,
    this.isArchived = false,
  });

  CompteComptable copyWith({
    String? id,
    String? code,
    String? title,
    String? parentId,
    bool? isArchived,
  }) {
    return CompteComptable(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      parentId: parentId ?? this.parentId,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory CompteComptable.fromMap(Map<String, dynamic> map) {
    return CompteComptable(
      id: map['id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? '',
      parentId: map['parentId'] as String?,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'parentId': parentId,
      'isArchived': isArchived ? 1 : 0,
    };
  }
}
