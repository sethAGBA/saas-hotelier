class EcritureComptable {
  final String id;
  final DateTime date;
  final String label;
  final String journalId;
  final String accountCode;
  final double debit;
  final double credit;
  final String? piece;

  const EcritureComptable({
    required this.id,
    required this.date,
    required this.label,
    required this.journalId,
    required this.accountCode,
    required this.debit,
    required this.credit,
    this.piece,
  });

  EcritureComptable copyWith({
    String? id,
    DateTime? date,
    String? label,
    String? journalId,
    String? accountCode,
    double? debit,
    double? credit,
    String? piece,
  }) {
    return EcritureComptable(
      id: id ?? this.id,
      date: date ?? this.date,
      label: label ?? this.label,
      journalId: journalId ?? this.journalId,
      accountCode: accountCode ?? this.accountCode,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      piece: piece ?? this.piece,
    );
  }

  factory EcritureComptable.fromMap(Map<String, dynamic> map) {
    return EcritureComptable(
      id: map['id'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      label: map['label'] as String? ?? '',
      journalId: map['journalId'] as String? ?? '',
      accountCode: map['accountCode'] as String? ?? '',
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      piece: map['piece'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'label': label,
      'journalId': journalId,
      'accountCode': accountCode,
      'debit': debit,
      'credit': credit,
      'piece': piece,
    };
  }
}
