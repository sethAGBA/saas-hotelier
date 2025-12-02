import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/local_database.dart';
import '../../../models/entity_info.dart';
import '../widgets/action_button.dart';
import '../widgets/setting_card.dart';

class EntiteTab extends StatefulWidget {
  const EntiteTab({super.key});

  @override
  State<EntiteTab> createState() => _EntiteTabState();
}

class _EntiteTabState extends State<EntiteTab> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _websiteController = TextEditingController();
  final _rccmController = TextEditingController();
  final _nifController = TextEditingController();
  final _currencyController = TextEditingController();
  final _legalController = TextEditingController();
  final _targetRevenueController = TextEditingController();
  final _capacityController = TextEditingController();
  final _timezoneController = TextEditingController();
  String? _logoPath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seedDefaults();
    _loadEntityFromDb();
  }

  void _seedDefaults() {
    _nameController.text = 'Roommaster Resort';
    _typeController.text = 'Hôtellerie • 4 étoiles';
    _addressController.text = '123 Avenue de la Plage, Douala';
    _contactController.text = 'Tel: +237 699 00 00 00 • contact@roommaster.app';
    _websiteController.text = 'www.roommaster.app';
    _rccmController.text = 'RC/DLA/2024/B12345';
    _nifController.text = '0000000000123';
    _currencyController.text = 'FCFA';
    _legalController.text = 'Mme. Aissatou Ngassa';
    _targetRevenueController.text = '1 200 000 000';
    _capacityController.text = '120 chambres (dont 8 suites)';
    _timezoneController.text = 'GMT+1 (Afrique centrale)';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _websiteController.dispose();
    _rccmController.dispose();
    _nifController.dispose();
    _currencyController.dispose();
    _legalController.dispose();
    _targetRevenueController.dispose();
    _capacityController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEntityFromDb() async {
    final info = await LocalDatabase.instance.getEntityInfo();
    setState(() {
      _nameController.text = info.name;
      _typeController.text = info.type;
      _addressController.text = info.address;
      _contactController.text = info.contacts;
      _websiteController.text = info.website;
      _rccmController.text = info.rccm;
      _nifController.text = info.nif;
      _currencyController.text = info.currency;
      _legalController.text = info.legalResponsible;
      _targetRevenueController.text = info.targetRevenue;
      _capacityController.text = info.capacity;
      _timezoneController.text = info.timezone;
      _logoPath = info.logoPath.isNotEmpty ? info.logoPath : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Branding en haut avec le logo
        SettingCard(
          title: 'Branding',
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: _logoPath != null && File(_logoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(_logoPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajouter',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    // Bouton d'édition en overlay
                    if (_logoPath != null && File(_logoPath!).existsSync())
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logo de l\'entité',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _logoPath?.isNotEmpty == true
                          ? 'Logo: ${_logoPath!.split('/').last}'
                          : 'Aucun logo sélectionné',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Format recommandé: PNG ou JPG, 512x512px minimum',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Grille responsive avec les cards d'information
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Card Identité
            SizedBox(
              width: 520,
              child: SettingCard(
                title: 'Identité de l\'entité',
                child: Column(
                  children: [
                    _buildTextField(
                      'Raison sociale',
                      _nameController,
                      icon: Icons.business_center_rounded,
                    ),
                    _buildTextField(
                      'Groupe / Type',
                      _typeController,
                      icon: Icons.category_rounded,
                    ),
                    _buildTextField(
                      'Adresse complète',
                      _addressController,
                      icon: Icons.location_on_rounded,
                      maxLines: 2,
                    ),
                    _buildTextField(
                      'Contacts',
                      _contactController,
                      icon: Icons.phone_rounded,
                      maxLines: 2,
                    ),
                    _buildTextField(
                      'Site web',
                      _websiteController,
                      icon: Icons.language_rounded,
                    ),
                    _buildTextField(
                      'RCCM',
                      _rccmController,
                      icon: Icons.badge_rounded,
                    ),
                    _buildTextField(
                      'NIF',
                      _nifController,
                      icon: Icons.numbers_rounded,
                    ),
                    _buildTextField(
                      'Responsable légal',
                      _legalController,
                      icon: Icons.person_rounded,
                    ),
                  ],
                ),
              ),
            ),

            // Card Opérations
            // Card Opérations
            SizedBox(
              width: 380,
              child: SettingCard(
                title: 'Paramètres opérationnels',
                child: Column(
                  children: [
                    _buildTextField(
                      'Capacité / Chambres',
                      _capacityController,
                      icon: Icons.hotel_rounded,
                    ),
                    _buildTextField(
                      'Objectif CA annuel',
                      _targetRevenueController,
                      suffix: 'FCFA',
                      icon: Icons.trending_up_rounded,
                    ),
                    _buildTextField(
                      'Devise principale',
                      _currencyController,
                      icon: Icons.attach_money_rounded,
                    ),
                    _buildTextField(
                      'Fuseau horaire',
                      _timezoneController,
                      icon: Icons.schedule_rounded,
                      isSelectable: true,
                      onTap: _pickTimezone,
                    ),
                  ],
                ),
              ),
            ),
      ]),

        const SizedBox(height: 24),

        // Boutons d'action avec meilleur design
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.save_rounded,
                label: _saving ? 'Enregistrement...' : 'Enregistrer',
                color: const Color(0xFF10B981),
                onTap: _saving ? null : _saveEntite,
                loading: _saving,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.refresh_rounded,
                label: 'Recharger',
                color: const Color(0xFF6366F1),
                onTap: _loading ? null : _loadEntityFromDb,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Info box en bas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[300], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ces informations sont utilisées pour les documents officiels et les rapports',
                  style: TextStyle(color: Colors.amber[200], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? suffix,
    IconData? icon,
    bool isSelectable = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: isSelectable,
        onTap: onTap,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.white60, size: 20)
              : null,
          suffixText: suffix,
          suffixStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onTap == null
              ? [Colors.grey[700]!, Colors.grey[800]!]
              : [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTimezone() async {
    const options = [
      'GMT',
      'GMT+1 (Afrique centrale)',
      'GMT+2',
      'GMT+3',
      'GMT+4',
    ];
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un fuseau horaire'),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (opt) => InkWell(
                  onTap: () => Navigator.pop(context, opt),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.white70, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          opt,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (choice != null) {
      setState(() {
        _timezoneController.text = choice;
      });
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      try {
        final saved = await _saveLogo(File(result.files.single.path!));
        setState(() {
          _logoPath = saved;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Logo enregistré avec succès'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Impossible de sauvegarder le logo'),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<String> _saveLogo(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final logosDir = Directory(p.join(dir.path, 'entity_logo'));
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    final ext = p.extension(file.path);
    final target = File(
      p.join(
        logosDir.path,
        'logo_${DateTime.now().millisecondsSinceEpoch}$ext',
      ),
    );
    await file.copy(target.path);
    return target.path;
  }

  void _saveEntite() {
    setState(() => _saving = true);
    final info = EntityInfo(
      name: _nameController.text.trim(),
      type: _typeController.text.trim(),
      address: _addressController.text.trim(),
      contacts: _contactController.text.trim(),
      website: _websiteController.text.trim(),
      rccm: _rccmController.text.trim(),
      nif: _nifController.text.trim(),
      currency: _currencyController.text.trim(),
      exercice: '',
      plan: '',
      legalResponsible: _legalController.text.trim(),
      targetRevenue: _targetRevenueController.text.trim(),
      capacity: _capacityController.text.trim(),
      timezone: _timezoneController.text.trim(),
      logoPath: _logoPath ?? '',
    );
    LocalDatabase.instance
        .saveEntityInfo(info)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Entité enregistrée avec succès'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        })
        .whenComplete(() {
          if (mounted) {
            setState(() => _saving = false);
          }
        });
  }
}