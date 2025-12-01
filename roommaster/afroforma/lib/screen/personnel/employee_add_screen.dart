import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../models/employee_model.dart';
import '../../models/certification.dart';
import 'package:afroforma/models/document.dart';
import 'package:afroforma/services/database_service.dart';

class EmployeeAddScreen extends StatefulWidget {
  final String employeeId;
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const EmployeeAddScreen({
    super.key,
    required this.employeeId,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  _EmployeeAddScreenState createState() => _EmployeeAddScreenState();
}

class _EmployeeAddScreenState extends State<EmployeeAddScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  String _appBarTitle = 'Infos Personnelles';

  late Employee _employee;

  // Controllers pour "Informations personnelles"
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cniController = TextEditingController();
  final _passeportController = TextEditingController();
  final _permisController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _nomContactUrgenceController = TextEditingController();
  final _telephoneContactUrgenceController = TextEditingController();
  String? _situationFamiliale;
  final _enfantsController = TextEditingController();
  final _referencesController = TextEditingController();
  final _conjointController = TextEditingController();
  File? _photo;
  String? _sexe;
  final _religionController = TextEditingController();
  DateTime? _dateNaissance;
  final _autresInfosController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController();
  final _emailPersonnelController = TextEditingController();
  final _bpController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _appartementRueController = TextEditingController();
  final _maisonController = TextEditingController();
  final _emailContactUrgenceController = TextEditingController();
  final _numeroPersonnelController = TextEditingController();
  final _numeroProfessionnelController = TextEditingController();
  final _posteController = TextEditingController();
  final _departementController = TextEditingController();
  final _salaireController = TextEditingController();
  final _managerController = TextEditingController();
  String? _typeContrat;
  DateTime? _dateEmbauche;
  DateTime? _finContrat;

  // Variables pour "Temps de travail"
  final _heuresHebdoController = TextEditingController();
  final _soldeCongesController = TextEditingController();
  final _soldeRttController = TextEditingController();

  // Variables pour "Données de paie"
  final _numeroSecu = TextEditingController();
  final _salaireBaseController = TextEditingController();
  final _primesController = TextEditingController();
  final _nomBanqueController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bicSwiftController = TextEditingController();

  // Variables pour "Formation & Carrière"
  final _competencesController = TextEditingController();
  List<String> _objectifs = [];
  List<Certification> _certifications = [];
  List<Document> _documents = [];
  bool _showCertDetails = false;

  // Variables pour "Administration"
  List<String> _equipements = [];
  Map<String, bool> _acces = {};
  List<String> _avantages = [];
  final _observationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_updateAppBarTitle);
    _employee = _loadInitialData();
    _initFieldsFromModel();
    _loadEmployeeDocuments();
  }

  Future<void> _loadEmployeeDocuments() async {
    try {
      if (_employee.id.isNotEmpty) {
        final docs = await DatabaseService().getDocumentsByStudent(_employee.id);
        setState(() {
          _documents = docs;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _updateAppBarTitle() {
    final tabTitles = [
      'Infos Personnelles',
      'Infos Professionnelles',
      'Temps de Travail',
      'Données de Paie',
      'Formation & Carrière',
      'Administration',
    ];
    if (mounted) {
      setState(() {
        _appBarTitle = tabTitles[_tabController.index];
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateAppBarTitle);
    _tabController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _cniController.dispose();
    _passeportController.dispose();
    _permisController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _nomContactUrgenceController.dispose();
    _telephoneContactUrgenceController.dispose();
    _enfantsController.dispose();
    _referencesController.dispose();
    _conjointController.dispose();
    _religionController.dispose();
    _posteController.dispose();
    _departementController.dispose();
    _salaireController.dispose();
    _managerController.dispose();
    _heuresHebdoController.dispose();
    _soldeCongesController.dispose();
    _soldeRttController.dispose();
    _numeroSecu.dispose();
    _salaireBaseController.dispose();
    _primesController.dispose();
    _nomBanqueController.dispose();
    _ibanController.dispose();
    _bicSwiftController.dispose();
    _competencesController.dispose();
    _observationsController.dispose();
    _autresInfosController.dispose();
    super.dispose();
  }

  Employee _loadInitialData() {
    if (widget.employeeId == 'new') {
      return Employee(id: 'new_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      return Employee(
        id: widget.employeeId,
        nom: 'Dupont',
        prenom: 'Jean',
        telephonePersonnel: '+228 90 12 34 56',
        poste: 'Formateur Senior',
        departement: 'Pédagogie',
        salaireBrutMensuel: 350000,
        situationFamiliale: 'Marié(e)',
        typeContrat: 'CDI',
        dateEmbauche: DateTime(2020, 1, 15),
        sexe: 'Masculin',
        emailPersonnel: 'jean.dupont@example.com',
      );
    }
  }

  void _initFieldsFromModel() {
    _nomController.text = _employee.nom ?? '';
    _prenomController.text = _employee.prenom ?? '';
    _cniController.text = _employee.cni ?? '';
    _passeportController.text = _employee.passeport ?? '';
    _permisController.text = _employee.permisConduire ?? '';
    _telephoneController.text = _employee.telephonePersonnel ?? '';
    _nomContactUrgenceController.text = _employee.nomContactUrgence ?? '';
    _telephoneContactUrgenceController.text = _employee.telephoneContactUrgence ?? '';
    _enfantsController.text = _employee.nombreEnfants?.toString() ?? '';
    _referencesController.text = _employee.references ?? '';
    _conjointController.text = _employee.nomConjoint ?? '';
    _religionController.text = _employee.religion ?? '';
    _autresInfosController.text = _employee.autresInformations ?? '';
    _lieuNaissanceController.text = _employee.lieuNaissance ?? '';
    _nationaliteController.text = _employee.nationalite ?? '';
    _emailPersonnelController.text = _employee.emailPersonnel ?? '';
    _bpController.text = _employee.bp ?? '';
    _villeController.text = _employee.ville ?? '';
    _quartierController.text = _employee.quartier ?? '';
    _appartementRueController.text = _employee.appartementRue ?? '';
    _maisonController.text = _employee.maison ?? '';
    _emailContactUrgenceController.text = _employee.emailContactUrgence ?? '';
    _numeroPersonnelController.text = _employee.telephonePersonnel ?? '';
    _numeroProfessionnelController.text = _employee.telephoneProfessionnel ?? '';
    _posteController.text = _employee.poste ?? '';
    _departementController.text = _employee.departement ?? '';
    _salaireController.text = _employee.salaireBrutMensuel?.toString() ?? '';
    _managerController.text = _employee.managerId ?? '';
    _heuresHebdoController.text = _employee.heuresHebdomadaires?.toString() ?? '';
    _soldeCongesController.text = _employee.soldeConges?.toString() ?? '';
    _soldeRttController.text = _employee.soldeRtt?.toString() ?? '';
    _numeroSecu.text = _employee.numeroSecu ?? '';
    _salaireBaseController.text = _employee.salaireBase?.toString() ?? '';
    _primesController.text = _employee.primes?.toString() ?? '';
    _nomBanqueController.text = _employee.nomBanque ?? '';
    _ibanController.text = _employee.iban ?? '';
    _bicSwiftController.text = _employee.bicSwift ?? '';
    _competencesController.text = _employee.competences ?? '';
    _objectifs = List<String>.from(_employee.objectifs);
  _certifications = List<Certification>.from(_employee.certifications);
    _observationsController.text = _employee.observations ?? '';
    _situationFamiliale = _employee.situationFamiliale;
    _sexe = _employee.sexe;
    _dateNaissance = _employee.dateNaissance;
    _typeContrat = _employee.typeContrat;
    _dateEmbauche = _employee.dateEmbauche;
    _finContrat = _employee.finContrat;
    _photo = _employee.photoPath != null ? File(_employee.photoPath!) : null;
    _equipements = _employee.equipements ?? [];
    _acces = Map<String, bool>.from(_employee.acces);
    _avantages = List<String>.from(_employee.avantages);
  }

  void _updateModelFromFields() {
    _employee = _employee.copyWith(
      nom: _nomController.text,
      prenom: _prenomController.text,
      cni: _cniController.text,
      passeport: _passeportController.text,
      permisConduire: _permisController.text,
      dateNaissance: _dateNaissance,
      lieuNaissance: _lieuNaissanceController.text,
      nationalite: _nationaliteController.text,
      sexe: _sexe,
      religion: _religionController.text,
      emailPersonnel: _emailPersonnelController.text,
      bp: _bpController.text,
      ville: _villeController.text,
      quartier: _quartierController.text,
      appartementRue: _appartementRueController.text,
      maison: _maisonController.text,
      telephonePersonnel: _telephoneController.text,
      telephoneProfessionnel: _numeroProfessionnelController.text,
      nomContactUrgence: _nomContactUrgenceController.text,
      telephoneContactUrgence: _telephoneContactUrgenceController.text,
      emailContactUrgence: _emailContactUrgenceController.text,
      references: _referencesController.text,
      situationFamiliale: _situationFamiliale,
      nombreEnfants: int.tryParse(_enfantsController.text),
      nomConjoint: _conjointController.text,
      autresInformations: _autresInfosController.text,
      poste: _posteController.text,
      departement: _departementController.text,
      managerId: _managerController.text,
      typeContrat: _typeContrat,
      dateEmbauche: _dateEmbauche,
      finContrat: _finContrat,
      salaireBrutMensuel: double.tryParse(_salaireController.text),
      heuresHebdomadaires: double.tryParse(_heuresHebdoController.text),
      soldeConges: double.tryParse(_soldeCongesController.text),
      soldeRtt: double.tryParse(_soldeRttController.text),
      numeroSecu: _numeroSecu.text,
      salaireBase: double.tryParse(_salaireBaseController.text),
      primes: double.tryParse(_primesController.text),
      nomBanque: _nomBanqueController.text,
      iban: _ibanController.text,
      bicSwift: _bicSwiftController.text,
      competences: _competencesController.text,
      objectifs: _objectifs,
      equipements: _equipements,
      acces: _acces,
      observations: _observationsController.text,
      photoPath: _photo?.path,
      avantages: _avantages,
  certifications: _certifications,
    );
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _photo = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectDateNaissance(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateNaissance) {
      setState(() {
        _dateNaissance = picked;
      });
    }
  }

  Future<void> _showAddAvantageDialog() async {
    final advantageController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un avantage'),
          content: TextField(
            controller: advantageController,
            decoration: const InputDecoration(hintText: "Ex: Logement de fonction"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                if (advantageController.text.isNotEmpty) {
                  setState(() {
                    _avantages.add(advantageController.text);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPermissionDialog() async {
    final permissionController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une permission'),
          content: TextField(
            controller: permissionController,
            decoration: const InputDecoration(hintText: "Ex: Accès au serveur"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                if (permissionController.text.isNotEmpty) {
                  setState(() {
                    _acces[permissionController.text] = false; // Add new permission, default to false
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddObjectifDialog() async {
    final objectifController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un objectif'),
          content: TextField(
            controller: objectifController,
            decoration: const InputDecoration(hintText: "Ex: Obtenir la certification X"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                if (objectifController.text.isNotEmpty) {
                  setState(() {
                    _objectifs.add(objectifController.text);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCertificationDialog() async {
    final certificationController = TextEditingController();
    DateTime? selectedExpiry;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une certification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: certificationController,
                decoration: const InputDecoration(hintText: "Ex: Certification PMP"),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(selectedExpiry != null ? 'Expiration: ${selectedExpiry!.toLocal().toIso8601String().split('T').first}' : 'Date d\'expiration (facultatif)'),
                  ),
                  TextButton(
                    child: const Text('Choisir'),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 20),
                      );
                      if (picked != null) {
                        selectedExpiry = picked;
                        // Force dialog to rebuild
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                if (certificationController.text.isNotEmpty) {
                  setState(() {
                    _certifications.add(Certification(name: certificationController.text, expiryDate: selectedExpiry));
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddEquipmentDialog() async {
    final equipmentController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un équipement'),
          content: TextField(
            controller: equipmentController,
            decoration: const InputDecoration(hintText: "Ex: Ordinateur portable"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                if (equipmentController.text.isNotEmpty) {
                  setState(() {
                    _equipements.add(equipmentController.text);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        // Use the app's AppBarTheme background (dark) to ensure contrast
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            // Match the AppBar background for the tab strip to keep text readable
            color: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Infos Personnelles'),
                Tab(text: 'Infos Professionnelles'),
                Tab(text: 'Temps de Travail'),
                Tab(text: 'Données de Paie'),
                Tab(text: 'Formation & Carrière'),
                Tab(text: 'Administration'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInformationsPersonnellesTab(),
              _buildInformationsProfessionnellesTab(),
              _buildTempsDeTravailTab(),
              _buildDonneesPaieTab(),
              _buildFormationCarriereTab(),
              _buildAdministrationTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveEmployee,
        backgroundColor: const Color(0xFF22C55E),
        icon: const Icon(Icons.save),
        label: const Text('Enregistrer'),
      ),
    );
  }

  Widget _buildInformationsPersonnellesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'État Civil',
            [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _photo != null ? FileImage(_photo!) : null,
                    child: _photo == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: _inputDecoration('Nom *'),
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: _inputDecoration('Prénom(s) *'),
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cniController,
                      decoration: _inputDecoration('N° CNI'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _passeportController,
                      decoration: _inputDecoration('N° Passeport'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _permisController,
                decoration: _inputDecoration('N° Permis de Conduire'),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDateNaissance(context),
                child: InputDecorator(
                  decoration: _inputDecoration('Date de naissance'),
                  child: Text(_dateNaissance?.toString().split(' ')[0] ?? 'Sélectionner'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sexe,
                decoration: _inputDecoration('Sexe'),
                items: ['Masculin', 'Féminin']
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _sexe = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _religionController,
                decoration: _inputDecoration('Religion'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lieuNaissanceController,
                decoration: _inputDecoration('Lieu de naissance'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationaliteController,
                decoration: _inputDecoration('Nationalité'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Contacts',
            [
              TextFormField(
                controller: _emailPersonnelController,
                decoration: _inputDecoration('Email personnel'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bpController,
                decoration: _inputDecoration('BP'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _villeController,
                decoration: _inputDecoration('Ville'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quartierController,
                decoration: _inputDecoration('Quartier de résidence'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _appartementRueController,
                decoration: _inputDecoration('Appartement/Rue'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maisonController,
                decoration: _inputDecoration('Maison'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telephoneController,
                      decoration: _inputDecoration('Téléphone'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _nomContactUrgenceController,
                      decoration: _inputDecoration('Nom du contact d\'urgence'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _telephoneContactUrgenceController,
                      decoration: _inputDecoration('Téléphone du contact d\'urgence'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailContactUrgenceController,
                decoration: _inputDecoration('Email du contact d\'urgence'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroPersonnelController,
                decoration: _inputDecoration('Numéro personnel'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroProfessionnelController,
                decoration: _inputDecoration('Numéro professionnel'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referencesController,
                decoration: _inputDecoration('Références'),
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Situation Familiale',
            [
              DropdownButtonFormField<String>(
                value: _situationFamiliale,
                decoration: _inputDecoration('Situation familiale'),
                items: ['Célibataire', 'Marié(e)', 'Divorcé(e)', 'Veuf(ve)']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _situationFamiliale = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enfantsController,
                decoration: _inputDecoration('Nombre d\'enfants à charge'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conjointController,
                decoration: _inputDecoration('Nom du conjoint'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Documents RH',
            [
              _buildDocumentUploadSection(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Autres Informations',
            [
              TextFormField(
                controller: _autresInfosController,
                decoration: _inputDecoration('Informations supplémentaires'),
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsProfessionnellesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionCard(
            'Poste Actuel',
            [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _posteController,
                      decoration: _inputDecoration('Intitulé du poste *'),
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _departementController,
                      decoration: _inputDecoration('Département'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _managerController,
                decoration: _inputDecoration('Responsable hiérarchique'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Contrat de Travail',
            [
              DropdownButtonFormField<String>(
                value: _typeContrat,
                decoration: _inputDecoration('Type de contrat *'),
                items: ['CDI', 'CDD', 'Stage', 'Consultant', 'Apprentissage']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _typeContrat = value),
                validator: (value) => value == null ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: _inputDecoration('Date d\'embauche *'),
                        child: Text(_dateEmbauche?.toString().split(' ')[0] ?? 'Sélectionner'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: _inputDecoration('Fin de contrat'),
                        child: Text(_finContrat?.toString().split(' ')[0] ?? 'Non définie'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Rémunération',
            [
              TextFormField(
                controller: _salaireController,
                decoration: _inputDecoration('Salaire brut mensuel (FCFA)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Avantages en nature:', style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: Colors.green),
                    label: const Text('Ajouter', style: TextStyle(color: Colors.green)),
                    onPressed: _showAddAvantageDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _avantages.map((avantage) => Chip(
                  label: Text(avantage),
                  onDeleted: () {
                    setState(() {
                      _avantages.remove(avantage);
                    });
                  },
                )).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempsDeTravailTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionCard(
            'Planning Hebdomadaire',
            [
              TextFormField(
                controller: _heuresHebdoController,
                decoration: _inputDecoration('Heures hebdomadaires'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Horaires type:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildScheduleWeek(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Soldes Congés',
            [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _soldeCongesController,
                      decoration: _inputDecoration('Congés payés (jours)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _soldeRttController,
                      decoration: _inputDecoration('RTT (jours)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.employeeId != 'new')
            _buildSectionCard(
              'Présences du Mois',
              [
                _buildPresenceCalendar(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDonneesPaieTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionCard(
            'Informations Sociales',
            [
              TextFormField(
                controller: _numeroSecu,
                decoration: _inputDecoration('N° Sécurité Sociale'),
              ),
              const SizedBox(height: 16),
              const Text('Situation sociale:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Cadre'),
                    selected: true,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Non-cadre'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Éléments de Paie',
            [
              TextFormField(
                controller: _salaireBaseController,
                decoration: _inputDecoration('Salaire de base (FCFA)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _primesController,
                decoration: _inputDecoration('Primes variables (FCFA)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (widget.employeeId != 'new')
                ElevatedButton.icon(
                  onPressed: () {
                    // Générer bulletin de paie
                  },
                  icon: const Icon(Icons.description),
                  label: const Text('Générer bulletin de paie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Coordonnées Bancaires',
            [
              TextFormField(
                controller: _nomBanqueController,
                decoration: _inputDecoration('Nom de la banque'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ibanController,
                decoration: _inputDecoration('IBAN'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bicSwiftController,
                decoration: _inputDecoration('BIC / SWIFT'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.employeeId != 'new')
            _buildSectionCard(
              'Historique des Bulletins',
              [
                _buildPayrollHistory(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFormationCarriereTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionCard(
            'Compétences',
            [
              TextFormField(
                controller: _competencesController,
                decoration: _inputDecoration('Compétences clés'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Certifications:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _showCertDetails ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                        ),
                        tooltip: _showCertDetails ? 'Masquer détails' : 'Afficher détails',
                        onPressed: () => setState(() => _showCertDetails = !_showCertDetails),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: Colors.green),
                    label: const Text('Ajouter', style: TextStyle(color: Colors.green)),
                    onPressed: _showAddCertificationDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _certifications.map((certification) {
                  final fullText = certification.expiryDate != null
                      ? '${certification.name} (Exp: ${certification.expiryDate!.toLocal().toIso8601String().split('T').first})'
                      : certification.name;
                  return Tooltip(
                    message: fullText,
                    child: Chip(
                      label: Text(_showCertDetails ? fullText : certification.name),
                      onDeleted: () {
                        setState(() {
                          _certifications.remove(certification);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.employeeId != 'new')
            _buildSectionCard(
              'Plan de Formation',
              [
                ElevatedButton.icon(
                  onPressed: () {
                    // Ajouter formation
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une formation'),
                ),
                const SizedBox(height: 16),
                _buildFormationPlan(),
              ],
            ),
          const SizedBox(height: 16),
          if (widget.employeeId != 'new')
            _buildSectionCard(
              'Évaluations',
              [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Objectifs annuels:', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, color: Colors.green),
                      label: const Text('Ajouter', style: TextStyle(color: Colors.green)),
                      onPressed: _showAddObjectifDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _objectifs.map((objectif) => Chip(
                    label: Text(objectif),
                    onDeleted: () {
                      setState(() {
                        _objectifs.remove(objectif);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Nouvel entretien
                  },
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Programmer entretien'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAdministrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionCard(
            'Équipements Assignés',
            [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Liste des équipements:', style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: Colors.green),
                    label: const Text('Ajouter', style: TextStyle(color: Colors.green)),
                    onPressed: _showAddEquipmentDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _equipements.map((equipment) => Chip(
                  label: Text(equipment),
                  onDeleted: () {
                    setState(() {
                      _equipements.remove(equipment);
                    });
                  },
                )).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Accès & Permissions',
            [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Liste des permissions:', style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: Colors.green),
                    label: const Text('Ajouter', style: TextStyle(color: Colors.green)),
                    onPressed: _showAddPermissionDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._acces.keys.map((String key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: _acces[key],
                  onChanged: (bool? value) {
                    setState(() {
                      _acces[key] = value!;
                    });
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _acces.remove(key);
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Notes Administratives',
            [
              TextFormField(
                controller: _observationsController,
                decoration: _inputDecoration('Observations'),
                maxLines: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).cardColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).cardColor),
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.upload_file),
          label: const Text('Ajouter documents'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // Liste des documents uploadés
        const SizedBox(height: 16),
        // Liste des documents uploadés (dynamiques)
        if (_documents.isEmpty)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Aucun document'),
          )
        else
          ..._documents.map((d) {
            final uploadedAt = DateTime.fromMillisecondsSinceEpoch(d.uploadedAtMs).toLocal();
            return ListTile(
              leading: Icon(Icons.description, color: Colors.blue),
              title: Text(d.fileName),
              subtitle: Text('Uploadé le ${uploadedAt.toIso8601String().split('T').first}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Ouvrir',
                    onPressed: () => _openDocument(d.path),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Supprimer',
                    onPressed: () => _deleteDocument(d),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildScheduleWeek() {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Column(
      children: days.map((day) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text(day)),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: _inputDecoration('Horaires (ex: 09:00-17:00)'),
                ),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildPresenceCalendar() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text('Calendrier des présences'),
      ),
    );
  }

  Widget _buildPayrollHistory() {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.description, color: Colors.blue),
          title: Text('Bulletin Janvier 2024'),
          subtitle: Text('Net: 2,850 FCFA'),
          trailing: Icon(Icons.download),
        ),
        const ListTile(
          leading: Icon(Icons.description, color: Colors.blue),
          title: Text('Bulletin Décembre 2023'),
          subtitle: Text('Net: 2,920 FCFA (13ème mois)'),
          trailing: Icon(Icons.download),
        ),
      ],
    );
  }

  // Certifications are rendered inline in the Formation & Carrière tab.

  Widget _buildFormationPlan() {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.schedule, color: Colors.blue),
          title: Text('Management d\'équipe'),
          subtitle: Text('Programmée: Mars 2024'),
          trailing: Text('3 jours'),
        ),
        const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Sécurité au travail'),
          subtitle: Text('Terminée: Janvier 2024'),
          trailing: Text('1 jour'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateEmbauche = picked;
        } else {
          _finContrat = picked;
        }
      });
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      // Traitement des fichiers sélectionnés: copier localement et enregistrer en base
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDocDir.path, 'employee_documents'));
      if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

      for (var file in result.files) {
        try {
          final srcPath = file.path;
          if (srcPath == null) continue;
          final ext = p.extension(file.name);
          final destName = 'emp_${_employee.id}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}${ext}';
          final destPath = p.join(targetDir.path, destName);
          await File(srcPath).copy(destPath);

          final doc = Document(
            id: 'doc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
            formationId: '',
            studentId: _employee.id,
            title: file.name,
            category: 'personnel',
            fileName: file.name,
            path: destPath,
            mimeType: (file.extension ?? '').toString(),
            size: file.size,
          );

          await DatabaseService().insertDocument(doc);
          setState(() {
            _documents.add(doc);
          });
        } catch (e) {
          // ignore single-file failures
          print('Erreur lors du traitement du fichier: $e');
        }
      }
    }
  }

  void _openDocument(String path) {
    try {
      if (!File(path).existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier introuvable.')));
        return;
      }
      if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [path]);
      } else if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', path]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ouverture non supportée.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _deleteDocument(Document d) async {
    try {
      await DatabaseService().deleteDocument(d.id);
      final f = File(d.path);
      if (f.existsSync()) f.deleteSync();
      setState(() {
        _documents.removeWhere((x) => x.id == d.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
    }
  }

  void _saveEmployee() {
    try {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez corriger les erreurs'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _updateModelFromFields();
      });
      print('Données de l\'employé à sauvegarder:');
      print(_employee.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employé enregistré avec succès ', style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.green,
          ),
      );

      if (Navigator.canPop(context)) Navigator.of(context).pop();
    } catch (e, st) {
      // Print full error and show SnackBar so user can paste it
      print('Erreur lors de la sauvegarde employé: $e');
      print(st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur sauvegarde: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}
