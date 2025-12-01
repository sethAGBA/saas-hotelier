import 'dart:convert';
import 'package:afroforma/models/certification.dart';

// Un modèle de données structuré pour représenter un employé.
class Employee {
  final String id;

  // === Onglet: Infos Personnelles ===
  final String? photoPath;
  final String? nom;
  final String? prenom;
  final String? cni;
  final String? passeport;
  final String? permisConduire;
  final DateTime? dateNaissance;
  final String? lieuNaissance;
  final String? nationalite;
  final String? sexe;
  final String? religion;
  final String? emailPersonnel;
  final String? bp;
  final String? ville;
  final String? quartier;
  final String? appartementRue;
  final String? maison;
  final String? telephonePersonnel;
  final String? telephoneProfessionnel;
  final String? nomContactUrgence;
  final String? telephoneContactUrgence;
  final String? emailContactUrgence;
  final String? references;
  final String? situationFamiliale;
  final int? nombreEnfants;
  final String? nomConjoint;
  final String? autresInformations;

  // === Onglet: Infos Professionnelles ===
  final String? poste;
  final String? departement;
  final String? managerId;
  final String? typeContrat;
  final DateTime? dateEmbauche;
  final DateTime? finContrat;
  final double? salaireBrutMensuel;

  final List<String> avantages;

  // === Onglet: Temps de travail ===
  final double? heuresHebdomadaires;
  final double? soldeConges;
  final double? soldeRtt;

  // === Onglet: Données de paie ===
  final String? numeroSecu;
  final String? situationSociale;
  final double? salaireBase;
  final double? primes;
  final String? nomBanque;
  final String? iban;
  final String? bicSwift;

  // === Onglet: Formation & Carrière ===
  final String? competences;
  final List<String> objectifs;
  final List<Certification> certifications;
  final DateTime? dateExpirationCertificat;

  // === Onglet: Administration ===
  final List<String>? equipements;
  final Map<String, bool> acces;
  final String? observations;

  Employee({
    required this.id,
    this.photoPath,
    this.nom,
    this.prenom,
    this.cni,
    this.passeport,
    this.permisConduire,
    this.dateNaissance,
    this.lieuNaissance,
    this.nationalite,
    this.sexe,
    this.religion,
    this.emailPersonnel,
    this.bp,
    this.ville,
    this.quartier,
    this.appartementRue,
    this.maison,
    this.telephonePersonnel,
    this.telephoneProfessionnel,
    this.nomContactUrgence,
    this.telephoneContactUrgence,
    this.emailContactUrgence,
    this.references,
    this.situationFamiliale,
    this.nombreEnfants,
    this.nomConjoint,
    this.autresInformations,
    this.poste,
    this.departement,
    this.managerId,
    this.typeContrat,
    this.dateEmbauche,
    this.finContrat,
    this.salaireBrutMensuel,
    this.heuresHebdomadaires,
    this.soldeConges,
    this.soldeRtt,
    this.numeroSecu,
    this.situationSociale,
    this.salaireBase,
    this.primes,
    this.nomBanque,
    this.iban,
    this.bicSwift,
    this.competences,
    this.objectifs = const [],
  this.dateExpirationCertificat,
    this.equipements,
    this.acces = const {},
    this.observations,
    this.avantages = const [],
    this.certifications = const [],
  });

  Employee copyWith({
    String? id,
    String? photoPath,
    String? nom,
    String? prenom,
    String? cni,
    String? passeport,
    String? permisConduire,
    DateTime? dateNaissance,
    String? lieuNaissance,
    String? nationalite,
    String? sexe,
    String? religion,
    String? emailPersonnel,
    String? bp,
    String? ville,
    String? quartier,
    String? appartementRue,
    String? maison,
    String? telephonePersonnel,
    String? telephoneProfessionnel,
    String? nomContactUrgence,
    String? telephoneContactUrgence,
    String? emailContactUrgence,
    String? references,
    String? situationFamiliale,
    int? nombreEnfants,
    String? nomConjoint,
    String? autresInformations,
    String? poste,
    String? departement,
    String? managerId,
    String? typeContrat,
    DateTime? dateEmbauche,
    DateTime? finContrat,
    double? salaireBrutMensuel,
    double? heuresHebdomadaires,
    double? soldeConges,
    double? soldeRtt,
    String? numeroSecu,
    String? situationSociale,
    double? salaireBase,
    double? primes,
    String? nomBanque,
    String? iban,
    String? bicSwift,
    String? competences,
    List<String>? objectifs,
    DateTime? dateExpirationCertificat,
    List<String>? equipements,
    Map<String, bool>? acces,
    String? observations,
    List<String>? avantages,
    List<Certification>? certifications,
  }) {
    return Employee(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      cni: cni ?? this.cni,
      passeport: passeport ?? this.passeport,
      permisConduire: permisConduire ?? this.permisConduire,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      nationalite: nationalite ?? this.nationalite,
      sexe: sexe ?? this.sexe,
      religion: religion ?? this.religion,
      emailPersonnel: emailPersonnel ?? this.emailPersonnel,
      bp: bp ?? this.bp,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      appartementRue: appartementRue ?? this.appartementRue,
      maison: maison ?? this.maison,
      telephonePersonnel: telephonePersonnel ?? this.telephonePersonnel,
      telephoneProfessionnel: telephoneProfessionnel ?? this.telephoneProfessionnel,
      nomContactUrgence: nomContactUrgence ?? this.nomContactUrgence,
      telephoneContactUrgence: telephoneContactUrgence ?? this.telephoneContactUrgence,
      emailContactUrgence: emailContactUrgence ?? this.emailContactUrgence,
      references: references ?? this.references,
      situationFamiliale: situationFamiliale ?? this.situationFamiliale,
      nombreEnfants: nombreEnfants ?? this.nombreEnfants,
      nomConjoint: nomConjoint ?? this.nomConjoint,
      autresInformations: autresInformations ?? this.autresInformations,
      poste: poste ?? this.poste,
      departement: departement ?? this.departement,
      managerId: managerId ?? this.managerId,
      typeContrat: typeContrat ?? this.typeContrat,
      dateEmbauche: dateEmbauche ?? this.dateEmbauche,
      finContrat: finContrat ?? this.finContrat,
      salaireBrutMensuel: salaireBrutMensuel ?? this.salaireBrutMensuel,
      heuresHebdomadaires: heuresHebdomadaires ?? this.heuresHebdomadaires,
      soldeConges: soldeConges ?? this.soldeConges,
      soldeRtt: soldeRtt ?? this.soldeRtt,
      numeroSecu: numeroSecu ?? this.numeroSecu,
      situationSociale: situationSociale ?? this.situationSociale,
      salaireBase: salaireBase ?? this.salaireBase,
      primes: primes ?? this.primes,
      nomBanque: nomBanque ?? this.nomBanque,
      iban: iban ?? this.iban,
      bicSwift: bicSwift ?? this.bicSwift,
      competences: competences ?? this.competences,
      objectifs: objectifs ?? this.objectifs,
  dateExpirationCertificat: dateExpirationCertificat ?? this.dateExpirationCertificat,
      equipements: equipements ?? this.equipements,
      acces: acces ?? this.acces,
      observations: observations ?? this.observations,
      avantages: avantages ?? this.avantages,
      certifications: certifications ?? this.certifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPath': photoPath,
      'nom': nom,
      'prenom': prenom,
      'cni': cni,
      'passeport': passeport,
      'permisConduire': permisConduire,
      'dateNaissance': dateNaissance?.toIso8601String(),
      'lieuNaissance': lieuNaissance,
      'nationalite': nationalite,
      'sexe': sexe,
      'religion': religion,
      'emailPersonnel': emailPersonnel,
      'bp': bp,
      'ville': ville,
      'quartier': quartier,
      'appartementRue': appartementRue,
      'maison': maison,
      'telephonePersonnel': telephonePersonnel,
      'telephoneProfessionnel': telephoneProfessionnel,
      'nomContactUrgence': nomContactUrgence,
      'telephoneContactUrgence': telephoneContactUrgence,
      'emailContactUrgence': emailContactUrgence,
      'references': references,
      'situationFamiliale': situationFamiliale,
      'nombreEnfants': nombreEnfants,
      'nomConjoint': nomConjoint,
      'autresInformations': autresInformations,
      'poste': poste,
      'departement': departement,
      'managerId': managerId,
      'typeContrat': typeContrat,
      'dateEmbauche': dateEmbauche?.toIso8601String(),
      'finContrat': finContrat?.toIso8601String(),
      'salaireBrutMensuel': salaireBrutMensuel,
      'heuresHebdomadaires': heuresHebdomadaires,
      'soldeConges': soldeConges,
      'soldeRtt': soldeRtt,
      'numeroSecu': numeroSecu,
      'situationSociale': situationSociale,
      'salaireBase': salaireBase,
      'primes': primes,
      'nomBanque': nomBanque,
      'iban': iban,
      'bicSwift': bicSwift,
      'competences': competences,
      'objectifs': objectifs,
    'dateExpirationCertificat': dateExpirationCertificat?.toIso8601String(),
      'equipements': equipements,
      'acces': acces,
      'observations': observations,
      'avantages': avantages,
      'certifications': certifications.map((c) => c.toMap()).toList(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      photoPath: map['photoPath'],
      nom: map['nom'],
      prenom: map['prenom'],
      cni: map['cni'],
      passeport: map['passeport'],
      permisConduire: map['permisConduire'],
      dateNaissance: map['dateNaissance'] != null ? DateTime.parse(map['dateNaissance']) : null,
      lieuNaissance: map['lieuNaissance'],
      nationalite: map['nationalite'],
      sexe: map['sexe'],
      religion: map['religion'],
      emailPersonnel: map['emailPersonnel'],
      bp: map['bp'],
      ville: map['ville'],
      quartier: map['quartier'],
      appartementRue: map['appartementRue'],
      maison: map['maison'],
      telephonePersonnel: map['telephonePersonnel'],
      telephoneProfessionnel: map['telephoneProfessionnel'],
      nomContactUrgence: map['nomContactUrgence'],
      telephoneContactUrgence: map['telephoneContactUrgence'],
      emailContactUrgence: map['emailContactUrgence'],
      references: map['references'],
      situationFamiliale: map['situationFamiliale'],
      nombreEnfants: map['nombreEnfants']?.toInt(),
      nomConjoint: map['nomConjoint'],
      autresInformations: map['autresInformations'],
      poste: map['poste'],
      departement: map['departement'],
      managerId: map['managerId'],
      typeContrat: map['typeContrat'],
      dateEmbauche: map['dateEmbauche'] != null ? DateTime.parse(map['dateEmbauche']) : null,
      finContrat: map['finContrat'] != null ? DateTime.parse(map['finContrat']) : null,
      salaireBrutMensuel: map['salaireBrutMensuel']?.toDouble(),
      heuresHebdomadaires: map['heuresHebdomadaires']?.toDouble(),
      soldeConges: map['soldeConges']?.toDouble(),
      soldeRtt: map['soldeRtt']?.toDouble(),
      numeroSecu: map['numeroSecu'],
      situationSociale: map['situationSociale'],
      salaireBase: map['salaireBase']?.toDouble(),
      primes: map['primes']?.toDouble(),
      nomBanque: map['nomBanque'],
      iban: map['iban'],
      bicSwift: map['bicSwift'],
      competences: map['competences'],
      objectifs: List<String>.from(map['objectifs'] ?? []),
      equipements: List<String>.from(map['equipements'] ?? []),
      acces: Map<String, bool>.from(map['acces'] ?? {}),
      observations: map['observations'],
      avantages: List<String>.from(map['avantages'] ?? []),
  dateExpirationCertificat: map['dateExpirationCertificat'] != null ? DateTime.parse(map['dateExpirationCertificat']) : null,
  certifications: (map['certifications'] as List<dynamic>?)?.map((x) => Certification.fromMap(Map<String, dynamic>.from(x))).toList() ?? [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Employee.fromJson(String source) => Employee.fromMap(json.decode(source));

  @override
  String toString() => 'Employee(id: $id, nom: $nom, prenom: $prenom)';
}