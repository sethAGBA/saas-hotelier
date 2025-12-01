import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class NouveauClientScreen extends StatefulWidget {
  const NouveauClientScreen({
    super.key,
    this.clientId,
    this.initialName,
    this.initialLastName,
    this.initialFirstName,
    this.initialEmail,
    this.initialPhone,
    this.initialPhone2,
    this.initialSegment,
    this.initialFidelity,
    this.initialVip,
    this.initialData,
    this.showHeader = true,
    this.onSaved,
  });

  final int? clientId;
  final String? initialName;
  final String? initialLastName;
  final String? initialFirstName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialPhone2;
  final String? initialSegment;
  final String? initialFidelity;
  final bool? initialVip;
  final Map<String, dynamic>? initialData;
  final bool showHeader;
  final VoidCallback? onSaved;

  @override
  State<NouveauClientScreen> createState() => _NouveauClientScreenState();
}

class _NouveauClientScreenState extends State<NouveauClientScreen> {
  // Identité
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _professionController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _domicileController = TextEditingController();
  String _situationFamiliale = 'Célibataire';
  String _nationalite = 'Togo';
  final _nationaliteAutreController = TextEditingController();

  // Adresse
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _paysResidenceController = TextEditingController();

  // Documents
  final _cniController = TextEditingController();
  final _passportController = TextEditingController();
  final _visaController = TextEditingController();
  final _cniLieuController = TextEditingController();
  final _passportLieuController = TextEditingController();
  final _visaLieuController = TextEditingController();
  final _cniDelivranceController = TextEditingController();
  final _passportDelivranceController = TextEditingController();
  final _visaDelivranceController = TextEditingController();
  final _expCniController = TextEditingController();
  final _expPassportController = TextEditingController();
  final _expVisaController = TextEditingController();

  // Urgence
  final _urgenceNomController = TextEditingController();
  final _urgencePhoneController = TextEditingController();
  final _urgenceLienController = TextEditingController();
  final _urgenceAdresseController = TextEditingController();

  // Segmentation
  late String _typeClient;
  late String _sourceReservation;
  late bool _vip;
  late String _statutFidelite;
  final _pointsFideliteController = TextEditingController(text: '0');
  final _inscriptionFideliteController = TextEditingController();

  // Préférences
  final _preferencesChambresController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _regimeAlimentaireController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _fumeur = false;
  bool _animaux = false;
  String _typeLit = 'Sans préférence';
  String _etagePreference = 'Sans préférence';
  final _provenanceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _motifVoyageController = TextEditingController();

  // Commercial
  final _entrepriseController = TextEditingController();
  final _posteController = TextEditingController();
  final _tvaController = TextEditingController();
  bool _facturationEntreprise = false;

  final _dateFormat = DateFormat('dd/MM/yyyy');
  bool _saving = false;

  void _prefillFromInitialData() {
    final d = widget.initialData;
    if (d == null) return;
    String? asString(String key) => (d[key] as String?)?.trim();
    int? asInt(String key) => d[key] as int?;
    bool boolFromInt(String key) => (d[key] as int?) == 1;

    _nomController.text = asString('lastName') ?? _nomController.text;
    _prenomController.text = asString('firstName') ?? _prenomController.text;
    _emailController.text = asString('email') ?? _emailController.text;
    _phoneController.text = asString('phone') ?? _phoneController.text;
    _phone2Controller.text = asString('phone2') ?? _phone2Controller.text;
    _dateNaissanceController.text = asString('dateOfBirth') ?? _dateNaissanceController.text;
    _professionController.text = asString('profession') ?? _professionController.text;
    _lieuNaissanceController.text = asString('placeOfBirth') ?? _lieuNaissanceController.text;
    _domicileController.text = asString('domicile') ?? _domicileController.text;
    _situationFamiliale = asString('maritalStatus') ?? _situationFamiliale;
    _nationalite = _validValue(asString('nationality'), _pays, fallback: _nationalite);
    _nationaliteAutreController.text = asString('nationalityOther') ?? _nationaliteAutreController.text;
    _adresseController.text = asString('address') ?? _adresseController.text;
    _villeController.text = asString('city') ?? _villeController.text;
    _codePostalController.text = asString('postalCode') ?? _codePostalController.text;
    _paysResidenceController.text = asString('country') ?? _paysResidenceController.text;
    _cniController.text = asString('idNumber') ?? _cniController.text;
    _cniLieuController.text = asString('idPlace') ?? _cniLieuController.text;
    _cniDelivranceController.text = asString('idIssuedOn') ?? _cniDelivranceController.text;
    _expCniController.text = asString('idExpiresOn') ?? _expCniController.text;
    _passportController.text = asString('passportNumber') ?? _passportController.text;
    _passportLieuController.text = asString('passportPlace') ?? _passportLieuController.text;
    _passportDelivranceController.text = asString('passportIssuedOn') ?? _passportDelivranceController.text;
    _expPassportController.text = asString('passportExpiresOn') ?? _expPassportController.text;
    _visaController.text = asString('visaNumber') ?? _visaController.text;
    _visaLieuController.text = asString('visaPlace') ?? _visaLieuController.text;
    _visaDelivranceController.text = asString('visaIssuedOn') ?? _visaDelivranceController.text;
    _expVisaController.text = asString('visaExpiresOn') ?? _expVisaController.text;
    _urgenceNomController.text = asString('emergencyName') ?? _urgenceNomController.text;
    _urgencePhoneController.text = asString('emergencyPhone') ?? _urgencePhoneController.text;
    _urgenceLienController.text = asString('emergencyRelation') ?? _urgenceLienController.text;
    _urgenceAdresseController.text = asString('emergencyAddress') ?? _urgenceAdresseController.text;
    _typeClient = _validValue(asString('clientType'), _typesClient, fallback: _typeClient);
    _sourceReservation = _validValue(asString('reservationSource'), _sources, fallback: _sourceReservation);
    _vip = d['vip'] is int ? boolFromInt('vip') : _vip;
    _statutFidelite = _validValue(asString('fidelityStatus'), _statutsFidelite, fallback: _statutFidelite);
    _pointsFideliteController.text = (asInt('fidelityPoints') ?? int.tryParse(_pointsFideliteController.text) ?? 0).toString();
    _inscriptionFideliteController.text = asString('fidelitySince') ?? _inscriptionFideliteController.text;
    _preferencesChambresController.text = asString('roomPreferences') ?? _preferencesChambresController.text;
    _allergiesController.text = asString('allergies') ?? _allergiesController.text;
    _regimeAlimentaireController.text = asString('diet') ?? _regimeAlimentaireController.text;
    _preferencesController.text = asString('otherPreferences') ?? _preferencesController.text;
    _typeLit = _validValue(asString('bedType'), _typesLit, fallback: _typeLit);
    _etagePreference = _validValue(asString('floorPreference'), _etages, fallback: _etagePreference);
    _fumeur = d['smoker'] is int ? boolFromInt('smoker') : _fumeur;
    _animaux = d['pets'] is int ? boolFromInt('pets') : _animaux;
    _feedbackController.text = asString('feedback') ?? _feedbackController.text;
    _provenanceController.text = asString('provenance') ?? _provenanceController.text;
    _destinationController.text = asString('destination') ?? _destinationController.text;
    _motifVoyageController.text = asString('travelReason') ?? _motifVoyageController.text;
    _entrepriseController.text = asString('company') ?? _entrepriseController.text;
    _posteController.text = asString('jobTitle') ?? _posteController.text;
    _tvaController.text = asString('vatNumber') ?? _tvaController.text;
    _facturationEntreprise = d['companyBilling'] is int ? boolFromInt('companyBilling') : _facturationEntreprise;
  }

  @override
  void initState() {
    super.initState();
    _typeClient = _validValue(widget.initialSegment, _typesClient, fallback: 'Loisirs');
    _sourceReservation = _validValue('Direct', _sources, fallback: 'Direct');
    _vip = widget.initialVip ?? false;
    _statutFidelite = _validValue(widget.initialFidelity, _statutsFidelite, fallback: 'Bronze');
    _nomController.text = widget.initialLastName ?? widget.initialName ?? '';
    _prenomController.text = widget.initialFirstName ?? '';
    _emailController.text = widget.initialEmail ?? '';
    _phoneController.text = widget.initialPhone ?? '';
    _phone2Controller.text = widget.initialPhone2 ?? '';
    _prefillFromInitialData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _dateNaissanceController.dispose();
    _professionController.dispose();
    _lieuNaissanceController.dispose();
    _domicileController.dispose();
    _nationaliteAutreController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _paysResidenceController.dispose();
    _cniController.dispose();
    _passportController.dispose();
    _visaController.dispose();
    _cniLieuController.dispose();
    _passportLieuController.dispose();
    _visaLieuController.dispose();
    _cniDelivranceController.dispose();
    _passportDelivranceController.dispose();
    _visaDelivranceController.dispose();
    _expCniController.dispose();
    _expPassportController.dispose();
    _expVisaController.dispose();
    _urgenceNomController.dispose();
    _urgencePhoneController.dispose();
    _urgenceLienController.dispose();
    _urgenceAdresseController.dispose();
    _preferencesChambresController.dispose();
    _allergiesController.dispose();
    _regimeAlimentaireController.dispose();
    _preferencesController.dispose();
    _feedbackController.dispose();
    _provenanceController.dispose();
    _destinationController.dispose();
    _motifVoyageController.dispose();
    _pointsFideliteController.dispose();
    _inscriptionFideliteController.dispose();
    _entrepriseController.dispose();
    _posteController.dispose();
    _tvaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      controller.text = _dateFormat.format(picked);
    }
  }

  Future<void> _submit() async {
    final isUpdate = widget.clientId != null;
    if (_nomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est obligatoire')),
      );
      return;
    }
    final fullName = [
      _prenomController.text.trim(),
      _nomController.text.trim(),
    ].where((p) => p.isNotEmpty).join(' ').trim();
    final name = fullName.isNotEmpty ? fullName : _nomController.text.trim();
    final lastName = _nomController.text.trim();
    final firstName = _prenomController.text.trim();
    final phone = _phoneController.text.trim();
    final phone2 = _phone2Controller.text.trim();
    final toNull = (String value) => value.trim().isEmpty ? null : value.trim();

    setState(() => _saving = true);
    try {
      if (isUpdate) {
        await LocalDatabase.instance.updateClient(
          widget.clientId!,
          name: name,
          lastName: toNull(lastName),
          firstName: toNull(firstName),
          email: toNull(_emailController.text),
          phone: toNull(phone),
          phone2: toNull(phone2),
          dateOfBirth: toNull(_dateNaissanceController.text),
          profession: toNull(_professionController.text),
          placeOfBirth: toNull(_lieuNaissanceController.text),
          domicile: toNull(_domicileController.text),
          maritalStatus: _situationFamiliale,
          nationality: _nationalite,
          nationalityOther: toNull(_nationaliteAutreController.text),
          address: toNull(_adresseController.text),
          city: toNull(_villeController.text),
          postalCode: toNull(_codePostalController.text),
          country: toNull(_paysResidenceController.text),
          idNumber: toNull(_cniController.text),
          idPlace: toNull(_cniLieuController.text),
          idIssuedOn: toNull(_cniDelivranceController.text),
          idExpiresOn: toNull(_expCniController.text),
          passportNumber: toNull(_passportController.text),
          passportPlace: toNull(_passportLieuController.text),
          passportIssuedOn: toNull(_passportDelivranceController.text),
          passportExpiresOn: toNull(_expPassportController.text),
          visaNumber: toNull(_visaController.text),
          visaPlace: toNull(_visaLieuController.text),
          visaIssuedOn: toNull(_visaDelivranceController.text),
          visaExpiresOn: toNull(_expVisaController.text),
          emergencyName: toNull(_urgenceNomController.text),
          emergencyPhone: toNull(_urgencePhoneController.text),
          emergencyRelation: toNull(_urgenceLienController.text),
          emergencyAddress: toNull(_urgenceAdresseController.text),
          clientType: _typeClient,
          reservationSource: _sourceReservation,
          vip: _vip,
          fidelityStatus: _statutFidelite,
          fidelityPoints: int.tryParse(_pointsFideliteController.text),
          fidelitySince: toNull(_inscriptionFideliteController.text),
          roomPreferences: toNull(_preferencesChambresController.text),
          allergies: toNull(_allergiesController.text),
          diet: toNull(_regimeAlimentaireController.text),
          otherPreferences: toNull(_preferencesController.text),
          bedType: _typeLit,
          floorPreference: _etagePreference,
          smoker: _fumeur,
          pets: _animaux,
          feedback: toNull(_feedbackController.text),
          provenance: toNull(_provenanceController.text),
          destination: toNull(_destinationController.text),
          travelReason: toNull(_motifVoyageController.text),
          company: toNull(_entrepriseController.text),
          jobTitle: toNull(_posteController.text),
          vatNumber: toNull(_tvaController.text),
          companyBilling: _facturationEntreprise,
        );
      } else {
        await LocalDatabase.instance.insertClient(
          name: name,
          lastName: toNull(lastName),
          firstName: toNull(firstName),
          email: toNull(_emailController.text),
          phone: toNull(phone),
          phone2: toNull(phone2),
          dateOfBirth: toNull(_dateNaissanceController.text),
          profession: toNull(_professionController.text),
          placeOfBirth: toNull(_lieuNaissanceController.text),
          domicile: toNull(_domicileController.text),
          maritalStatus: _situationFamiliale,
          nationality: _nationalite,
          nationalityOther: toNull(_nationaliteAutreController.text),
          address: toNull(_adresseController.text),
          city: toNull(_villeController.text),
          postalCode: toNull(_codePostalController.text),
          country: toNull(_paysResidenceController.text),
          idNumber: toNull(_cniController.text),
          idPlace: toNull(_cniLieuController.text),
          idIssuedOn: toNull(_cniDelivranceController.text),
          idExpiresOn: toNull(_expCniController.text),
          passportNumber: toNull(_passportController.text),
          passportPlace: toNull(_passportLieuController.text),
          passportIssuedOn: toNull(_passportDelivranceController.text),
          passportExpiresOn: toNull(_expPassportController.text),
          visaNumber: toNull(_visaController.text),
          visaPlace: toNull(_visaLieuController.text),
          visaIssuedOn: toNull(_visaDelivranceController.text),
          visaExpiresOn: toNull(_expVisaController.text),
          emergencyName: toNull(_urgenceNomController.text),
          emergencyPhone: toNull(_urgencePhoneController.text),
          emergencyRelation: toNull(_urgenceLienController.text),
          emergencyAddress: toNull(_urgenceAdresseController.text),
          clientType: _typeClient,
          reservationSource: _sourceReservation,
          vip: _vip,
          fidelityStatus: _statutFidelite,
          fidelityPoints: int.tryParse(_pointsFideliteController.text),
          fidelitySince: toNull(_inscriptionFideliteController.text),
          roomPreferences: toNull(_preferencesChambresController.text),
          allergies: toNull(_allergiesController.text),
          diet: toNull(_regimeAlimentaireController.text),
          otherPreferences: toNull(_preferencesController.text),
          bedType: _typeLit,
          floorPreference: _etagePreference,
          smoker: _fumeur,
          pets: _animaux,
          feedback: toNull(_feedbackController.text),
          provenance: toNull(_provenanceController.text),
          destination: toNull(_destinationController.text),
          travelReason: toNull(_motifVoyageController.text),
          company: toNull(_entrepriseController.text),
          jobTitle: toNull(_posteController.text),
          vatNumber: toNull(_tvaController.text),
          companyBilling: _facturationEntreprise,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isUpdate ? 'Client mis à jour' : 'Client enregistré dans la base locale')),
      );
      widget.onSaved?.call();
      if (!isUpdate) {
        _clearForm();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _nomController.clear();
    _prenomController.clear();
    _emailController.clear();
    _phoneController.clear();
    _phone2Controller.clear();
    _dateNaissanceController.clear();
    _professionController.clear();
    _lieuNaissanceController.clear();
    _domicileController.clear();
    _nationaliteAutreController.clear();
    _adresseController.clear();
    _villeController.clear();
    _codePostalController.clear();
    _paysResidenceController.clear();
    _cniController.clear();
    _passportController.clear();
    _visaController.clear();
    _cniLieuController.clear();
    _passportLieuController.clear();
    _visaLieuController.clear();
    _cniDelivranceController.clear();
    _passportDelivranceController.clear();
    _visaDelivranceController.clear();
    _expCniController.clear();
    _expPassportController.clear();
    _expVisaController.clear();
    _urgenceNomController.clear();
    _urgencePhoneController.clear();
    _urgenceLienController.clear();
    _urgenceAdresseController.clear();
    _preferencesChambresController.clear();
    _allergiesController.clear();
    _regimeAlimentaireController.clear();
    _preferencesController.clear();
    _feedbackController.clear();
    _provenanceController.clear();
    _destinationController.clear();
    _motifVoyageController.clear();
    _pointsFideliteController.text = '0';
    _inscriptionFideliteController.clear();
    _entrepriseController.clear();
    _posteController.clear();
    _tvaController.clear();
    setState(() {
      _typeClient = 'Loisirs';
      _sourceReservation = 'Direct';
      _vip = false;
      _statutFidelite = 'Bronze';
      _fumeur = false;
      _animaux = false;
      _typeLit = 'Sans préférence';
      _etagePreference = 'Sans préférence';
      _situationFamiliale = 'Célibataire';
      _nationalite = 'Togo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.showHeader) ...[
              const _HeaderCard(),
              const SizedBox(height: 12),
            ],
            _SectionCard(
              title: 'Identité',
              icon: Icons.person_outline,
              children: [
                Row(
                  children: [
                    Expanded(child: _field(_nomController, 'Nom *', Icons.badge)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_prenomController, 'Prénom', Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_emailController, 'Email', Icons.email_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_phoneController, 'Téléphone', Icons.phone)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_phone2Controller, 'Téléphone 2', Icons.phone_iphone)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateField(
                        controller: _dateNaissanceController,
                        label: 'Date de naissance',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_lieuNaissanceController, 'Lieu de naissance', Icons.place_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_domicileController, 'Domicile', Icons.home_work_outlined)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_professionController, 'Profession', Icons.work_outline)),
                    const SizedBox(width: 10),
                    Expanded(child: _dropdown('Situation familiale', _situationFamiliale, ['Célibataire', 'Marié(e)', 'Divorcé(e)', 'Veuf(ve)', 'Autre'], (v) => setState(() => _situationFamiliale = v ?? _situationFamiliale))),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _dropdown('Nationalité', _nationalite, _pays, (v) => setState(() => _nationalite = v ?? _nationalite)),
                    if (_nationalite == 'Autre') ...[
                      const SizedBox(height: 10),
                      _field(_nationaliteAutreController, 'Précisez la nationalité', Icons.flag_outlined),
                    ],
                  ],
                ),
              ],
            ),
            _SectionCard(
              title: 'Adresse',
              icon: Icons.location_on_outlined,
              children: [
                _field(_adresseController, 'Adresse', Icons.home_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _field(_villeController, 'Ville', Icons.location_city)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_codePostalController, 'Code postal', Icons.local_post_office)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(_paysResidenceController, 'Pays de résidence', Icons.flag_outlined),
                ],
              ),
            _SectionCard(
              title: 'Documents',
              icon: Icons.credit_card,
              children: [
                Row(
                  children: [
                    Expanded(child: _field(_cniController, 'CNI', Icons.badge_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField(controller: _expCniController, label: 'Expiration CNI')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_cniLieuController, 'Lieu délivrance CNI', Icons.location_on_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField(controller: _cniDelivranceController, label: 'Date délivrance CNI')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_passportController, 'Passeport', Icons.travel_explore)),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField(controller: _expPassportController, label: 'Expiration Passeport')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_passportLieuController, 'Lieu délivrance Passeport', Icons.location_on_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField(controller: _passportDelivranceController, label: 'Date délivrance Passeport')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_visaController, 'Visa', Icons.airplane_ticket_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField(controller: _expVisaController, label: 'Expiration Visa')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_visaLieuController, 'Lieu délivrance Visa', Icons.location_on_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField(controller: _visaDelivranceController, label: 'Date délivrance Visa')),
                  ],
                ),
              ],
            ),
              _SectionCard(
                title: 'Contact d’urgence',
                icon: Icons.shield_outlined,
                children: [
                  _field(_urgenceNomController, 'Nom complet', Icons.person_outline),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _field(_urgencePhoneController, 'Téléphone', Icons.phone_in_talk)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_urgenceLienController, 'Lien', Icons.link)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(_urgenceAdresseController, 'Adresse', Icons.home_work_outlined),
                ],
              ),
              _SectionCard(
                title: 'Segmentation & fidélité',
                icon: Icons.star_outline,
                children: [
                  Row(
                    children: [
                      Expanded(child: _dropdown('Type client', _typeClient, _typesClient, (v) => setState(() => _typeClient = v ?? _typeClient))),
                      const SizedBox(width: 10),
                      Expanded(child: _dropdown('Source réservation', _sourceReservation, _sources, (v) => setState(() => _sourceReservation = v ?? _sourceReservation))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: _vip,
                    onChanged: (v) => setState(() => _vip = v),
                    activeColor: const Color(0xFF6C63FF),
                    title: const Text('VIP', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _dropdown('Statut fidélité', _statutFidelite, _statutsFidelite, (v) => setState(() => _statutFidelite = v ?? _statutFidelite))),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_pointsFideliteController, 'Points', Icons.loyalty)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _dateField(controller: _inscriptionFideliteController, label: 'Date inscription'),
                ],
              ),
              _SectionCard(
                title: 'Préférences',
                icon: Icons.bed_outlined,
                children: [
                  _field(_preferencesChambresController, 'Préférences chambre', Icons.room_preferences_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _field(_allergiesController, 'Allergies', Icons.sick_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_regimeAlimentaireController, 'Régime alimentaire', Icons.restaurant_outlined)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(_preferencesController, 'Autres préférences', Icons.notes),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _dropdown('Type de lit', _typeLit, _typesLit, (v) => setState(() => _typeLit = v ?? _typeLit))),
                      const SizedBox(width: 10),
                      Expanded(child: _dropdown('Étage', _etagePreference, _etages, (v) => setState(() => _etagePreference = v ?? _etagePreference))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          value: _fumeur,
                          onChanged: (v) => setState(() => _fumeur = v ?? false),
                          title: const Text('Fumeur', style: TextStyle(color: Colors.white)),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF6C63FF),
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          value: _animaux,
                          onChanged: (v) => setState(() => _animaux = v ?? false),
                          title: const Text('Animaux', style: TextStyle(color: Colors.white)),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                  _field(_feedbackController, 'Feedback / notes internes', Icons.feedback_outlined, maxLines: 3),
                ],
              ),
              _SectionCard(
                title: 'Voyage',
                icon: Icons.flight_takeoff_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(child: _field(_provenanceController, 'Provenance', Icons.flight_land)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_destinationController, 'Destination', Icons.flight_takeoff)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(_motifVoyageController, 'Motif du voyage', Icons.airplanemode_active),
                ],
              ),
              _SectionCard(
                title: 'Entreprise',
                icon: Icons.business_center_outlined,
                children: [
                  _field(_entrepriseController, 'Entreprise', Icons.apartment),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _field(_posteController, 'Poste', Icons.work)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_tvaController, 'N° TVA', Icons.confirmation_number_outlined)),
                    ],
                  ),
                  SwitchListTile(
                    value: _facturationEntreprise,
                    onChanged: (v) => setState(() => _facturationEntreprise = v),
                    activeColor: const Color(0xFF6C63FF),
                    title: const Text('Facturation entreprise', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Les données sont enregistrées dans la base locale (SQLite).',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
       )    ),    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF6C63FF)),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: _fieldDecoration(label, icon),
    );
  }

  Widget _dateField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration(label, Icons.calendar_today),
      onTap: () => _pickDate(controller),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final safeValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : value);
    return DropdownButtonFormField<String>(
      value: safeValue,
      dropdownColor: const Color(0xFF1A1A2E),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF6C63FF)),
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  String _validValue(String? value, List<String> items, {required String fallback}) {
    if (value != null && items.contains(value)) return value;
    return items.contains(fallback) ? fallback : (items.isNotEmpty ? items.first : fallback);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

const List<String> _pays = [
  'Togo',
  'France',
  'Bénin',
  'Ghana',
  'Côte d\'Ivoire',
  'Nigeria',
  'Burkina Faso',
  'Mali',
  'Sénégal',
  'Cameroun',
  'Autre',
];

const List<String> _typesClient = ['Loisirs', 'Corporate', 'Client fréquent'];
const List<String> _sources = [
  'Direct',
  'Booking.com',
  'Expedia',
  'Agence',
  'Téléphone',
  'Site web',
  'Réseaux sociaux',
  'Recommandation'
];
const List<String> _statutsFidelite = ['Bronze', 'Silver', 'Gold'];
const List<String> _typesLit = [
  'Lit simple',
  'Lit double',
  'Lits jumeaux',
  'Lit king size',
  'Sans préférence'
];

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF38f9d7)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_add_alt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouveau Client',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Fiche complète pour préremplir les réservations',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Formulaire détaillé',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );     
  }
}
const List<String> _etages = [
  'Rez-de-chaussée',
  'Étage bas',
  'Étage moyen',
  'Étage élevé',
  'Sans préférence'
];
