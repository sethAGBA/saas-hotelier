class DocumentTemplate {
  final String id;
  final String name;
  final String type; // facture, recu, attestation, canvas
  final String content; // JSON or plain text
  final DateTime lastModified;

  DocumentTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'content': content,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory DocumentTemplate.fromMap(Map<String, dynamic> map) {
    return DocumentTemplate(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      content: map['content'] as String? ?? '',
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        (map['lastModified'] as int?) ?? 0,
      ),
    );
  }
}
