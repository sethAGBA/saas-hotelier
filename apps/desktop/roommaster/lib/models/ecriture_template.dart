import 'dart:convert';

class EcritureTemplate {
  final String id;
  final String label;
  final String? defaultJournalId;
  final List<TemplateLine> lines;

  const EcritureTemplate({
    required this.id,
    required this.label,
    required this.lines,
    this.defaultJournalId,
  });

  factory EcritureTemplate.fromMap(Map<String, dynamic> map) {
    final content = map['content'] as String? ?? '';
    List<TemplateLine> parsed = [];
    try {
      parsed = TemplateLine.listFromJson(content);
    } catch (_) {}
    // Compat: fallback to single line using legacy columns
    if (parsed.isEmpty) {
      final debit = (map['defaultAmount'] as num?)?.toDouble() ?? 0.0;
      final debitAcc = map['debitAccount'] as String? ?? '';
      final creditAcc = map['creditAccount'] as String? ?? '';
      parsed = [
        TemplateLine(
          account: debitAcc,
          label: map['description'] as String? ?? map['label'] as String? ?? '',
          debit: debit,
          credit: 0.0,
        ),
        TemplateLine(
          account: creditAcc,
          label: map['description'] as String? ?? map['label'] as String? ?? '',
          debit: 0.0,
          credit: debit,
        ),
      ];
    }
    return EcritureTemplate(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      defaultJournalId: map['journalId'] as String?,
      lines: parsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'journalId': defaultJournalId,
      'content': TemplateLine.listToJson(lines),
    };
  }
}

class TemplateLine {
  final String account;
  final String label;
  final double debit;
  final double credit;

  TemplateLine({
    required this.account,
    required this.label,
    required this.debit,
    required this.credit,
  });

  Map<String, dynamic> toJson() => {
    'account': account,
    'label': label,
    'debit': debit,
    'credit': credit,
  };

  static TemplateLine fromJson(Map<String, dynamic> map) {
    return TemplateLine(
      account: map['account'] as String? ?? '',
      label: map['label'] as String? ?? '',
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static List<TemplateLine> listFromJson(String json) {
    final decoded = json.isEmpty ? [] : (jsonDecode(json) as List<dynamic>);
    return decoded
        .map((e) => TemplateLine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String listToJson(List<TemplateLine> lines) {
    return jsonEncode(lines.map((e) => e.toJson()).toList());
  }
}
