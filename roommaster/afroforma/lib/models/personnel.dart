class Personnel {
  final String id;
  final String nom;
  final String prenom;
  final String poste;
  final String statut;
  final String? photoUrl;

  Personnel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.poste,
    this.statut = 'Actif',
    this.photoUrl,
  });

  String get nomComplet => '$prenom $nom';
}
