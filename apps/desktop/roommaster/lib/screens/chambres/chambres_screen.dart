import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/local_database.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/futuristic_app_bar.dart';
import '../../widgets/futuristic_room_status_chip.dart';

class ChambresScreen extends StatefulWidget {
  const ChambresScreen({super.key});

  @override
  State<ChambresScreen> createState() => _ChambresScreenState();
}

class _ChambresScreenState extends State<ChambresScreen> {
  static const List<String> _statusOptions = [
    'available',
    'occupied',
    'reserved',
    'dirty',
    'cleaning',
    'maintenance',
  ];

  static const List<String> _viewOptions = [
    'Ville',
    'Mer',
    'Jardin',
    'Piscine',
    'Cour',
    'Montagne',
  ];

  final _numberController = TextEditingController();
  final _typeController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  final _capacityController = TextEditingController();
  final _equipmentsController = TextEditingController();
  final _bedTypeController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _newTypeController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final _newEquipmentController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
  );

  List<Map<String, dynamic>> _rooms = [];
  List<String> _roomTypes = [];
  List<String> _categoryOptions = [];
  List<String> _equipmentOptions = [];
  final Set<String> _selectedEquipments = {};
  String _selectedType = '';
  String _selectedStatus = 'available';
  String _selectedCategory = '';
  String _selectedView = 'Ville';
  String _viewMode = 'grid'; // 'grid', 'list', 'floor'
  int? _editingId;
  bool _isSmokingAllowed = false;
  bool _isAccessible = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final ApiClient _api = ApiClient(baseUrl: 'http://localhost:4000');

  @override
  void initState() {
    super.initState();
    _photoUrlController.addListener(() => setState(() {}));
    _initData();
  }

  Future<void> _initData() async {
    await _loadMetadata();
    await _loadRooms();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _typeController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    _capacityController.dispose();
    _equipmentsController.dispose();
    _bedTypeController.dispose();
    _photoUrlController.dispose();
    _newTypeController.dispose();
    _newCategoryController.dispose();
    _newEquipmentController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final auth = AuthService.instance;
      List<Map<String, dynamic>> rooms;
      if (auth.authToken != null && auth.tenantId != null) {
        try {
          rooms = await _api.fetchRooms();
        } catch (_) {
          rooms = await LocalDatabase.instance.fetchRooms();
        }
      } else {
        rooms = await LocalDatabase.instance.fetchRooms();
      }
      if (!mounted) return;
      setState(() {
        _rooms = rooms
            .map(
              (room) => {
                ...room,
                'status': _normalizeStatus(room['status'] as String? ?? ''),
              },
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur lors du chargement des chambres');
      debugPrint('$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openRoomDialog({Map<String, dynamic>? room}) async {
    if (room != null) {
      _startEdit(room);
    } else {
      _resetForm();
    }

    await showDialog(
      context: context,
      barrierDismissible: !(_isSubmitting),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F0F1E),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                        tooltip: 'Fermer',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFormCard(closeDialogOnSave: true),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadMetadata() async {
    try {
      final results = await Future.wait<List<String>>([
        LocalDatabase.instance.fetchRoomTypes(),
        LocalDatabase.instance.fetchRoomCategories(),
        LocalDatabase.instance.fetchRoomEquipments(),
      ]);

      final types = results[0];
      final categories = results[1];
      final equipments = results[2];

      if (!mounted) return;
      setState(() {
        _roomTypes = types;
        _categoryOptions = categories;
        _equipmentOptions = equipments;
        _selectedType =
            _selectedType.isNotEmpty && types.contains(_selectedType)
            ? _selectedType
            : (types.isNotEmpty ? types.first : '');
        _selectedCategory =
            _selectedCategory.isNotEmpty &&
                categories.contains(_selectedCategory)
            ? _selectedCategory
            : (categories.isNotEmpty ? categories.first : '');
        _selectedView = _viewOptions.contains(_selectedView)
            ? _selectedView
            : _viewOptions.first;
        _selectedEquipments.removeWhere((e) => !equipments.contains(e));
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('$e');
    }
  }

  Future<void> _addType() async {
    final name = _newTypeController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addRoomType(name);
    _newTypeController.clear();
    await _loadMetadata();
    setState(() {
      _selectedType = name;
      _typeController.text = name;
    });
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addRoomCategory(name);
    _newCategoryController.clear();
    await _loadMetadata();
    setState(() {
      _selectedCategory = name;
    });
  }

  Future<void> _addEquipment() async {
    final name = _newEquipmentController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addRoomEquipment(name);
    _newEquipmentController.clear();
    await _loadMetadata();
    _selectedEquipments.add(name);
    _syncEquipmentField();
    setState(() {});
  }

  Future<void> _deleteType(String name) async {
    await LocalDatabase.instance.deleteRoomType(name);
    await _loadMetadata();
    setState(() {
      if (_typeController.text == name) _typeController.clear();
    });
  }

  Future<void> _deleteCategory(String name) async {
    await LocalDatabase.instance.deleteRoomCategory(name);
    await _loadMetadata();
    setState(() {
      if (_selectedCategory == name) {
        _selectedCategory = _categoryOptions.isNotEmpty
            ? _categoryOptions.first
            : '';
      }
    });
  }

  Future<void> _deleteEquipment(String name) async {
    await LocalDatabase.instance.deleteRoomEquipment(name);
    _selectedEquipments.remove(name);
    _syncEquipmentField();
    await _loadMetadata();
    setState(() {});
  }

  void _toggleEquipment(String name) {
    if (_selectedEquipments.contains(name)) {
      _selectedEquipments.remove(name);
    } else {
      _selectedEquipments.add(name);
    }
    _syncEquipmentField();
    setState(() {});
  }

  void _syncEquipmentField() {
    _equipmentsController.text = _selectedEquipments.isEmpty
        ? ''
        : _selectedEquipments.join(', ');
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return;
    try {
      final savedPath = await _savePhoto(File(pickedPath));
      if (savedPath == null) return;
      debugPrint('Image sauvegardée: $savedPath');
      setState(() {
        _photoUrlController.text = savedPath;
      });
    } catch (e) {
      debugPrint('Erreur sauvegarde image: $e');
      _showSnack('Impossible de sauvegarder la photo');
    }
  }

  Future<String?> _savePhoto(File photo) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(directory.path, 'room_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = p.extension(photo.path).toLowerCase();
    final roomRef = _numberController.text.trim().isNotEmpty
        ? _numberController.text.trim()
        : 'room';
    final fileName =
        'room_${roomRef}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final targetPath = p.join(photosDir.path, fileName);
    final targetFile = File(targetPath);
    await targetFile.create(recursive: true);
    await photo.copy(targetPath);
    return targetPath;
  }

  Map<String, int> get _statusCounts {
    final counts = {for (final status in _statusOptions) status: 0};
    for (final room in _rooms) {
      final status = room['status'] as String? ?? 'available';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  String _normalizeStatus(String status) {
    if (_statusOptions.contains(status)) return status;
    return _statusOptions.first;
  }

  Future<void> _saveRoom({bool closeDialogOnSave = false}) async {
    final number = _numberController.text.trim();
    final type =
        (_selectedType.isNotEmpty ? _selectedType : _typeController.text)
            .trim();
    final notes = _notesController.text.trim();
    final rateInput = _rateController.text.replaceAll(',', '.').trim();
    final parsedRate =
        double.tryParse(rateInput.isEmpty ? '0' : rateInput) ?? 0;
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 1;
    final equipmentsText = _selectedEquipments.isNotEmpty
        ? _selectedEquipments.join(', ')
        : _equipmentsController.text.trim();
    final bedType = _bedTypeController.text.trim();
    final photoUrl = _photoUrlController.text.trim();

    if (number.isEmpty || type.isEmpty) {
      _showSnack('Numéro et type sont requis');
      return;
    }

    final editing = _editingId != null;
    setState(() => _isSubmitting = true);
    try {
      await LocalDatabase.instance.upsertRoom(
        id: _editingId,
        number: number,
        type: type,
        status: _selectedStatus,
        rate: parsedRate,
        notes: notes.isEmpty ? null : notes,
        category: _selectedCategory,
        capacity: capacity,
        bedType: bedType.isEmpty ? null : bedType,
        equipments: equipmentsText.isEmpty ? null : equipmentsText,
        view: _selectedView,
        photoUrl: photoUrl.isEmpty ? null : photoUrl,
        smoking: _isSmokingAllowed,
        accessible: _isAccessible,
      );

      if (!mounted) return;
      _resetForm();
      await _loadRooms();
      _showSnack(editing ? 'Chambre mise à jour' : 'Chambre ajoutée');
      if (closeDialogOnSave && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Impossible d\'enregistrer la chambre');
        debugPrint('$e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    await LocalDatabase.instance.updateRoomStatus(id, status);
    if (!mounted) return;
    await _loadRooms();
    _showSnack('Statut mis à jour');
  }

  Future<void> _deleteRoom(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette chambre ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await LocalDatabase.instance.deleteRoom(id);
    if (!mounted) return;
    await _loadRooms();
    _showSnack('Chambre supprimée');
  }

  void _startEdit(Map<String, dynamic> room) {
    setState(() {
      _editingId = room['id'] as int?;
      _numberController.text = room['number'] as String? ?? '';
      _typeController.text = room['type'] as String? ?? '';
      _selectedType = _typeController.text;
      _selectedStatus = _normalizeStatus(room['status'] as String? ?? '');
      final rate = room['rate'];
      _rateController.text = rate == null
          ? ''
          : (rate is int ? rate.toDouble() : rate).toString();
      _notesController.text = room['notes'] as String? ?? '';
      _capacityController.text = (room['capacity'] as int?)?.toString() ?? '';
      _equipmentsController.text = room['equipments'] as String? ?? '';
      _bedTypeController.text = room['bedType'] as String? ?? '';
      _photoUrlController.text = room['photoUrl'] as String? ?? '';
      _selectedCategory =
          room['category'] as String? ??
          (_categoryOptions.isNotEmpty ? _categoryOptions.first : '');
      _selectedView = room['view'] as String? ?? _selectedView;
      _isSmokingAllowed = (room['smoking'] as int?) == 1;
      _isAccessible = (room['accessible'] as int?) == 1;
      final equipments = (room['equipments'] as String? ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      _selectedEquipments
        ..clear()
        ..addAll(equipments);
    });
  }

  void _resetForm() {
    _editingId = null;
    _numberController.clear();
    _typeController.clear();
    _rateController.clear();
    _notesController.clear();
    _capacityController.clear();
    _equipmentsController.clear();
    _bedTypeController.clear();
    _photoUrlController.clear();
    _selectedStatus = 'available';
    _selectedType = _roomTypes.isNotEmpty ? _roomTypes.first : '';
    _selectedCategory = _categoryOptions.isNotEmpty
        ? _categoryOptions.first
        : '';
    _selectedView = 'Ville';
    _isSmokingAllowed = false;
    _isAccessible = false;
    _selectedEquipments.clear();
    setState(() {});
  }

  Widget _buildPhotoPreview() {
    final photoUrl = _photoUrlController.text.trim();
    final hasImage = photoUrl.isNotEmpty;
    ImageProvider? imageProvider;

    if (hasImage) {
      if (photoUrl.startsWith('http')) {
        imageProvider = NetworkImage(photoUrl);
      } else if (File(photoUrl).existsSync()) {
        imageProvider = FileImage(File(photoUrl));
      }
    }

    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.25)),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.12),
            const Color(0xFF4CAF50).withOpacity(0.08),
          ],
        ),
        image: imageProvider != null
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2),
                  BlendMode.darken,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: double.infinity,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Icon(
                  hasImage
                      ? Icons.photo_library_rounded
                      : Icons.add_a_photo_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visuel de la chambre',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasImage
                      ? 'Prévisualisation générée depuis l’URL'
                      : 'Ajoute une URL d’image pour enrichir la fiche',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text('Ouvrir Finder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: hasImage
                          ? () {
                              debugPrint('Photo tap - URL actuelle: $photoUrl');
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Logger l’URL'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceManager() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
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
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'Référentiels (types, catégories, équipements)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetaInput(
            controller: _newTypeController,
            label: 'Types de chambre',
            hint: 'Ajouter un type (ex: Suite)',
            icon: Icons.hotel_rounded,
            onAdd: _addType,
          ),
          const SizedBox(height: 8),
          _buildEditableChips(
            items: _roomTypes,
            selectedValue: _typeController.text,
            onTap: (value) => setState(() => _typeController.text = value),
            onDelete: _deleteType,
          ),
          const SizedBox(height: 12),
          _buildMetaInput(
            controller: _newCategoryController,
            label: 'Catégories',
            hint: 'Ajouter une catégorie (ex: Suite Exécutive)',
            icon: Icons.category_rounded,
            onAdd: _addCategory,
          ),
          const SizedBox(height: 8),
          _buildEditableChips(
            items: _categoryOptions,
            selectedValue: _selectedCategory,
            onTap: (value) => setState(() => _selectedCategory = value),
            onDelete: _deleteCategory,
          ),
          const SizedBox(height: 12),
          _buildMetaInput(
            controller: _newEquipmentController,
            label: 'Équipements',
            hint: 'Ajouter un équipement (ex: TV 55")',
            icon: Icons.devices_other_rounded,
            onAdd: _addEquipment,
          ),
          const SizedBox(height: 8),
          _buildEditableChips(
            items: _equipmentOptions,
            selectedSet: _selectedEquipments,
            onTap: _toggleEquipment,
            onDelete: _deleteEquipment,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C63FF)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildEditableChips({
    required List<String> items,
    Set<String>? selectedSet,
    String? selectedValue,
    required ValueChanged<String> onTap,
    required ValueChanged<String> onDelete,
  }) {
    if (items.isEmpty) {
      return Text(
        'Aucun élément pour le moment',
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected =
            selectedSet?.contains(item) ??
            (selectedValue != null && selectedValue == item);
        return InputChip(
          label: Text(item, style: const TextStyle(color: Colors.white)),
          avatar: isSelected
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                )
              : null,
          backgroundColor: Colors.white.withOpacity(0.04),
          selectedColor: const Color(0xFF6C63FF).withOpacity(0.4),
          selected: isSelected,
          onPressed: () => onTap(item),
          onDeleted: () => onDelete(item),
          deleteIconColor: Colors.white70,
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentSelector() {
    if (_equipmentOptions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _equipmentOptions.map((equip) {
        final selected = _selectedEquipments.contains(equip);
        return FilterChip(
          label: Text(
            equip,
            style: TextStyle(color: selected ? Colors.white : Colors.white70),
          ),
          selected: selected,
          onSelected: (_) => _toggleEquipment(equip),
          selectedColor: const Color(0xFF6C63FF).withOpacity(0.35),
          backgroundColor: Colors.white.withOpacity(0.06),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'reserved':
        return Colors.purple;
      case 'dirty':
        return Colors.orange;
      case 'cleaning':
        return Colors.blue;
      case 'maintenance':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'occupied':
        return 'Occupée';
      case 'reserved':
        return 'Réservée';
      case 'dirty':
        return 'Sale';
      case 'cleaning':
        return 'Nettoyage';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
        ),
      ),
      child: Column(
        children: [
          buildFuturisticAppBar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1100;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildStatusChips(),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => _openRoomDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nouvelle chambre'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRoomsCard(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.15),
            const Color(0xFF4CAF50).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5A52E0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestion des Chambres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${_rooms.length} chambres • ${_statusCounts['available'] ?? 0} disponibles',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                _buildViewModeButton(Icons.grid_view_rounded, 'grid', 'Grille'),
                const SizedBox(width: 6),
                _buildViewModeButton(Icons.view_list_rounded, 'list', 'Liste'),
                const SizedBox(width: 6),
                _buildViewModeButton(Icons.layers_rounded, 'floor', 'Étage'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(IconData icon, String mode, String label) {
    final isSelected = _viewMode == mode;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5A52E0)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 20,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    final statusCounts = _statusCounts;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vue d\'ensemble',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _statusOptions
                .map(
                  (status) => _buildEnhancedStatusChip(
                    _statusLabel(status),
                    statusCounts[status] ?? 0,
                    _statusColor(status),
                    status,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatusChip(
    String label,
    int count,
    Color color,
    String status,
  ) {
    final percentage = _rooms.isEmpty ? 0.0 : (count / _rooms.length * 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({bool closeDialogOnSave = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E3F).withOpacity(0.9),
            const Color(0xFF2D2D5F).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5A52E0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _editingId == null ? Icons.add_rounded : Icons.edit_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _editingId == null
                      ? 'Ajouter une chambre'
                      : 'Modifier la chambre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (_editingId != null)
                IconButton(
                  onPressed: _isSubmitting ? null : _resetForm,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white70,
                  tooltip: 'Annuler',
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPhotoPreview(),
          const SizedBox(height: 20),
          _buildReferenceManager(),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _numberController,
            label: 'Numéro de chambre',
            icon: Icons.meeting_room_rounded,
            required: true,
          ),
          const SizedBox(height: 16),
          _roomTypes.isEmpty
              ? _buildFormField(
                  controller: _typeController,
                  label: 'Type de chambre',
                  icon: Icons.bedroom_parent_rounded,
                  required: true,
                )
              : _buildDropdownField(
                  value:
                      _selectedType.isNotEmpty &&
                          _roomTypes.contains(_selectedType)
                      ? _selectedType
                      : _roomTypes.first,
                  label: 'Type de chambre',
                  icon: Icons.bedroom_parent_rounded,
                  items: _roomTypes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                        _typeController.text = value;
                      });
                    }
                  },
                ),
          const SizedBox(height: 16),
          _buildDropdownField(
            value:
                _selectedCategory.isNotEmpty &&
                    _categoryOptions.contains(_selectedCategory)
                ? _selectedCategory
                : (_categoryOptions.isNotEmpty ? _categoryOptions.first : ''),
            label: 'Catégorie',
            icon: Icons.star_rounded,
            items: _categoryOptions,
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  value: _statusOptions.contains(_selectedStatus)
                      ? _selectedStatus
                      : _statusOptions.first,
                  label: 'Statut',
                  icon: Icons.info_rounded,
                  items: _statusOptions,
                  labelBuilder: _statusLabel,
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedStatus = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  controller: _capacityController,
                  label: 'Capacité',
                  icon: Icons.people_rounded,
                  keyboardType: TextInputType.number,
                  suffix: 'pers.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _rateController,
                  label: 'Tarif de base',
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  prefix: 'FCFA ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  controller: _bedTypeController,
                  label: 'Type de lit',
                  icon: Icons.bed_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  value: _selectedView,
                  label: 'Vue',
                  icon: Icons.panorama_rounded,
                  items: _viewOptions,
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedView = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  controller: _photoUrlController,
                  label: 'Photo (URL)',
                  icon: Icons.image_rounded,
                  hint: 'https://...',
                  keyboardType: TextInputType.url,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _equipmentsController,
            label: 'Équipements',
            icon: Icons.devices_rounded,
            hint: 'Climatisation, TV, WiFi...',
          ),
          const SizedBox(height: 12),
          _buildEquipmentSelector(),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _notesController,
            label: 'Notes / Description',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6C63FF),
                title: const Text(
                  'Espace fumeur',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _isSmokingAllowed ? 'Autorisé' : 'Non autorisé',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                value: _isSmokingAllowed,
                onChanged: (value) => setState(() => _isSmokingAllowed = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6C63FF),
                title: const Text(
                  'Accessible PMR',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _isAccessible ? 'Accessible' : 'Non accessible',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                value: _isAccessible,
                onChanged: (value) => setState(() => _isAccessible = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _saveRoom(closeDialogOnSave: closeDialogOnSave),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF6C63FF).withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _editingId == null
                              ? Icons.save_rounded
                              : Icons.check_rounded,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editingId == null ? 'Enregistrer' : 'Mettre à jour',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    String? hint,
    String? prefix,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixText: prefix,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? labelBuilder,
  }) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(
              'Ajoute une entrée pour $label',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }
    final display = labelBuilder ?? (String item) => item;
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E3F),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(display(item)),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required IconData icon,
    required String label,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? color.withOpacity(0.7)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: value ? color : Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: value ? color : Colors.white24),
              ),
              child: value
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.7),
            const Color(0xFF16213E).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chambres enregistrées (${_rooms.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadRooms,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucune chambre enregistrée pour le moment.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            _viewMode == 'grid' ? _buildGridView() : _buildListView(),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final room = _rooms[index];
        return _buildRoomTile(room);
      },
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemCount: _rooms.length,
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final status = room['status'] as String? ?? 'available';
    final number = room['number'] as String? ?? '';
    final type = room['type'] as String? ?? '';
    final rate = room['rate'];
    final formattedRate = rate == null
        ? 'N/A'
        : _currencyFormat.format(
            rate is int ? rate.toDouble() : rate as double,
          );

    return InkWell(
      onTap: () => _startEdit(room),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _statusColor(status).withOpacity(0.15),
              _statusColor(status).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _statusColor(status).withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor(status).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _statusColor(status),
                        _statusColor(status).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor(status).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 18,
                    ),
                    color: const Color(0xFF1E1E3F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _startEdit(room);
                      } else if (value == 'delete') {
                        _deleteRoom(room['id'] as int);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: Color(0xFF6C63FF),
                            ),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusColor(status).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Divider(color: Colors.white24, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tarif',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  formattedRate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTile(Map<String, dynamic> room) {
    final status = room['status'] as String? ?? 'available';
    final number = room['number'] as String? ?? '';
    final type = room['type'] as String? ?? '';
    final notes = room['notes'] as String?;
    final category = room['category'] as String? ?? '';
    final capacity = room['capacity'] as int? ?? 1;
    final bedType = room['bedType'] as String? ?? '';
    final equipments = room['equipments'] as String? ?? '';
    final view = room['view'] as String? ?? '';
    final photoUrl = room['photoUrl'] as String? ?? '';
    final isSmoking = (room['smoking'] as int?) == 1;
    final isAccessible = (room['accessible'] as int?) == 1;
    final rate = room['rate'];
    final formattedRate = rate == null
        ? ''
        : _currencyFormat.format(
            rate is int ? rate.toDouble() : rate as double,
          );

    return GestureDetector(
      onTap: () => _openRoomDialog(room: room),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _statusColor(status).withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                image: photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.2),
                          BlendMode.darken,
                        ),
                      )
                    : null,
                gradient: LinearGradient(
                  colors: [
                    _statusColor(status).withOpacity(0.25),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      _StatusDropdown(
                        value: status,
                        options: _statusOptions,
                        onChanged: (value) {
                          if (value == null) return;
                          _updateStatus(room['id'] as int, value);
                        },
                        labelBuilder: _statusLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _infoPill(Icons.people_alt_rounded, '$capacity pers.'),
                      if (bedType.isNotEmpty)
                        _infoPill(Icons.king_bed_rounded, bedType),
                      if (view.isNotEmpty)
                        _infoPill(Icons.panorama_rounded, view),
                      if (formattedRate.isNotEmpty)
                        _infoPill(Icons.payments_rounded, formattedRate),
                      if (isSmoking)
                        _infoPill(Icons.smoking_rooms_rounded, 'Fumeur'),
                      if (isAccessible)
                        _infoPill(Icons.accessible_rounded, 'Accessible'),
                    ],
                  ),
                  if (equipments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: equipments
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .map((e) => _infoChip(e))
                          .toList(),
                    ),
                  ],
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _openRoomDialog(room: room),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Modifier'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteRoom(room['id'] as int),
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          size: 18,
                        ),
                        label: const Text('Supprimer'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.labelBuilder,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String Function(String) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final selectedValue = options.contains(value) ? value : options.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          dropdownColor: const Color(0xFF1A1A2E),
          items: options
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(labelBuilder(status)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
