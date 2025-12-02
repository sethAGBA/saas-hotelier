import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class NewReservationScreen extends StatefulWidget {
  const NewReservationScreen({Key? key, this.initialReservation})
    : super(key: key);

  final Map<String, dynamic>? initialReservation;

  @override
  State<NewReservationScreen> createState() => _NewReservationScreenState();
}

class _NewReservationScreenState extends State<NewReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Informations réservation
  final _guestNameController = TextEditingController();
  final _guestEmailController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _professionController = TextEditingController();
  final _domicileController = TextEditingController();
  final _travelReasonController = TextEditingController();
  final _comingFromController = TextEditingController();
  final _goingToController = TextEditingController();
  final _idIssuedAtController = TextEditingController();
  final _visaNumberController = TextEditingController();
  final _visaIssuedAtController = TextEditingController();
  final _emergencyAddressController = TextEditingController();

  // Nouveaux champs
  final _adultsController = TextEditingController(text: '1');
  final _childrenController = TextEditingController(text: '0');
  final _nationalityController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _companyController = TextEditingController();
  final _newRoomTypeController = TextEditingController();
  final _newBedTypeController = TextEditingController();
  final _newServiceController = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;
  DateTime? _dateOfBirth;
  DateTime? _idIssuedOn;
  DateTime? _visaIssuedOn;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 12, minute: 0);

  bool _isSubmitting = false;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  int? _reservationId;

  // Nouveaux états
  String _roomType = 'Standard';
  String _bedType = 'Double';
  String _reservationSource = 'Direct';
  String _status = 'Confirmée';
  String _paymentStatus = 'En attente';
  String _lodgingType = 'Chambre';
  String? _selectedRoomNumber;
  bool _breakfastIncluded = false;
  bool _parkingIncluded = false;
  bool _wifiIncluded = true;
  Set<String> _preselectedServices = {};
  List<_ServiceOption> _customServices = [];
  List<Map<String, dynamic>> _rooms = [];
  List<String> _roomTypes = [
    'Standard',
    'Supérieure',
    'Deluxe',
    'Suite Junior',
    'Suite Exécutive',
    'Suite Présidentielle',
  ];
  List<String> _bedTypes = [
    'Simple',
    'Double',
    'Twin',
    'Queen',
    'King',
    'Triple',
  ];

  final List<String> _lodgingTypes = ['Chambre', 'Appartement'];

  final List<String> _sources = [
    'Direct',
    'Téléphone',
    'Walk-in',
    'Site web',
    'Booking.com',
    'Airbnb',
    'Expedia',
    'Agence voyage',
    'Corporate',
  ];

  final List<String> _statusOptions = [
    'Confirmée',
    'Provisoire',
    'Annulée',
    'No-show',
    'En attente',
  ];
  List<Map<String, dynamic>> _clients = [];
  late Future<void> _clientsFuture;

  String _toDbStatus(String value) {
    switch (value.toLowerCase()) {
      case 'confirmée':
        return 'confirmed';
      case 'provisoire':
        return 'provisional';
      case 'annulée':
        return 'cancelled';
      case 'no-show':
        return 'no-show';
      case 'en attente':
        return 'pending';
      default:
        return value.toLowerCase();
    }
  }

  String _toUiStatus(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return 'Confirmée';
      case 'provisional':
        return 'Provisoire';
      case 'cancelled':
        return 'Annulée';
      case 'no-show':
      case 'no_show':
        return 'No-show';
      case 'pending':
        return 'En attente';
      default:
        return value;
    }
  }

  final List<String> _paymentStatusOptions = [
    'Payé',
    'Acompte versé',
    'En attente',
    'Facturé',
  ];

  bool get _isEdit => _reservationId != null;

  @override
  void initState() {
    super.initState();
    _applyInitialData();
    _loadMetadata();
    _loadRooms();
    _clientsFuture = _loadClients();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _roomNumberController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
    _nationalityController.dispose();
    _idNumberController.dispose();
    _companyController.dispose();
    _newRoomTypeController.dispose();
    _newBedTypeController.dispose();
    _newServiceController.dispose();
    _placeOfBirthController.dispose();
    _professionController.dispose();
    _domicileController.dispose();
    _travelReasonController.dispose();
    _comingFromController.dispose();
    _goingToController.dispose();
    _idIssuedAtController.dispose();
    _visaNumberController.dispose();
    _visaIssuedAtController.dispose();
    _emergencyAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final rows = await LocalDatabase.instance.fetchClients();
    if (!mounted) return;
    setState(() {
      _clients = rows;
    });
  }

  void _applyInitialData() {
    final data = widget.initialReservation;
    if (data == null) return;
    _reservationId = data['id'] as int?;
    _guestNameController.text = data['guestName'] as String? ?? '';
    _guestEmailController.text = data['guestEmail'] as String? ?? '';
    _guestPhoneController.text = data['guestPhone'] as String? ?? '';
    _roomNumberController.text = data['roomNumber'] as String? ?? '';
    _selectedRoomNumber = data['roomNumber'] as String?;
    _amountController.text = (data['amount'] as num?)?.toString() ?? '';
    _notesController.text = data['notes'] as String? ?? '';
    _placeOfBirthController.text = data['placeOfBirth'] as String? ?? '';
    _professionController.text = data['profession'] as String? ?? '';
    _domicileController.text = data['domicile'] as String? ?? '';
    _travelReasonController.text = data['travelReason'] as String? ?? '';
    _comingFromController.text = data['comingFrom'] as String? ?? '';
    _goingToController.text = data['goingTo'] as String? ?? '';
    _idIssuedAtController.text = data['idIssuedAt'] as String? ?? '';
    _visaNumberController.text = data['visaNumber'] as String? ?? '';
    _visaIssuedAtController.text = data['visaIssuedAt'] as String? ?? '';
    _emergencyAddressController.text =
        data['emergencyAddress'] as String? ?? '';
    _nationalityController.text = data['nationality'] as String? ?? '';
    _idNumberController.text = data['idNumber'] as String? ?? '';
    _companyController.text = data['company'] as String? ?? '';

    _roomType = data['roomType'] as String? ?? _roomType;
    _bedType = data['bedType'] as String? ?? _bedType;
    _lodgingType = data['lodgingType'] as String? ?? _lodgingType;
    _reservationSource =
        data['reservationSource'] as String? ?? _reservationSource;
    final status = data['status'] as String?;
    if (status != null && status.isNotEmpty) {
      _status = _toUiStatus(status);
    }
    _paymentStatus = data['paymentStatus'] as String? ?? _paymentStatus;
    _breakfastIncluded = (data['breakfastIncluded'] as int? ?? 0) == 1;
    _parkingIncluded = (data['parkingIncluded'] as int? ?? 0) == 1;
    _wifiIncluded = (data['wifiIncluded'] as int? ?? 1) == 1;
    _adultsController.text = (data['adults'] as int? ?? 1).toString();
    _childrenController.text = (data['children'] as int? ?? 0).toString();

    _checkIn = DateTime.tryParse(data['checkIn'] as String? ?? '');
    _checkOut = DateTime.tryParse(data['checkOut'] as String? ?? '');
    _dateOfBirth = DateTime.tryParse(data['dateOfBirth'] as String? ?? '');
    _idIssuedOn = DateTime.tryParse(data['idIssuedOn'] as String? ?? '');
    _visaIssuedOn = DateTime.tryParse(data['visaIssuedOn'] as String? ?? '');
    final checkInTime = data['checkInTime'] as String?;
    final checkOutTime = data['checkOutTime'] as String?;
    if (checkInTime != null && checkInTime.contains(':')) {
      final parts = checkInTime.split(':');
      _checkInTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 14,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    if (checkOutTime != null && checkOutTime.contains(':')) {
      final parts = checkOutTime.split(':');
      _checkOutTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 12,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    final services = (data['services'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    _preselectedServices = services;
    _customServices.addAll(
      services.map((s) => _ServiceOption(s, selected: true)),
    );
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn
        ? (_checkIn ?? now)
        : (_checkOut ?? now.add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(_checkIn!)) {
            _checkOut = _checkIn!.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
        final rate = _currentRoomRate();
        if (rate > 0) {
          _prefillAmountFromRate(rate);
        }
      });
    }
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _checkOutTime,
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  Future<void> _loadMetadata() async {
    try {
      final results = await Future.wait([
        LocalDatabase.instance.fetchRoomTypes(),
        LocalDatabase.instance.fetchServices(),
      ]);
      final types = results[0];
      final services = results[1];
      if (!mounted) return;
      setState(() {
        _roomTypes = types.isNotEmpty ? types : _roomTypes;
        if (!_roomTypes.contains(_roomType) && _roomTypes.isNotEmpty) {
          _roomType = _roomTypes.first;
        }
        final existing = _customServices.map((e) => e.name).toSet();
        for (final s in services) {
          if (!existing.contains(s)) {
            _customServices.add(
              _ServiceOption(s, selected: _preselectedServices.contains(s)),
            );
          }
        }
        for (final s in _customServices) {
          if (_preselectedServices.contains(s.name)) {
            s.selected = true;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await LocalDatabase.instance.fetchRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        final firstNumber = rooms.isNotEmpty
            ? rooms.first['number']?.toString()
            : null;
        _selectedRoomNumber ??= firstNumber;
        if (_selectedRoomNumber != null) {
          _applyRoomSelection(_selectedRoomNumber);
        }
      });
    } catch (_) {}
  }

  void _applyClientToForm(Map<String, dynamic> client) {
    String combineName() {
      final first = (client['firstName'] as String? ?? '').trim();
      final last = (client['lastName'] as String? ?? '').trim();
      final fallback = (client['name'] as String? ?? '').trim();
      final parts = [first, last].where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(' ');
      return fallback;
    }

    setState(() {
      _guestNameController.text = combineName();
      _guestEmailController.text = (client['email'] as String? ?? '').trim();
      _guestPhoneController.text = (client['phone'] as String? ?? '').trim();
      _nationalityController.text = (client['nationality'] as String? ?? '').trim();
      _idNumberController.text = (client['idNumber'] as String? ?? '').trim();
      _placeOfBirthController.text = (client['placeOfBirth'] as String? ?? '').trim();
      _professionController.text = (client['profession'] as String? ?? '').trim();
      _domicileController.text = (client['domicile'] as String? ?? '').trim();
      _travelReasonController.text = (client['travelReason'] as String? ?? '').trim();
      _comingFromController.text = (client['provenance'] as String? ?? '').trim();
      _goingToController.text = (client['destination'] as String? ?? '').trim();
      _emergencyAddressController.text =
          (client['emergencyAddress'] as String? ?? '').trim();
      _idIssuedAtController.text = (client['idPlace'] as String? ?? '').trim();
      _companyController.text = (client['company'] as String? ?? '').trim();
      _dateOfBirth = DateTime.tryParse(client['dateOfBirth'] as String? ?? '');
      _idIssuedOn = DateTime.tryParse(client['idIssuedOn'] as String? ?? '');
      _visaIssuedOn = DateTime.tryParse(client['visaIssuedOn'] as String? ?? '');
      _visaIssuedAtController.text = (client['visaIssuedAt'] as String? ?? '').trim();
      _visaNumberController.text = (client['visaNumber'] as String? ?? '').trim();
      _idIssuedAtController.text = (client['idPlace'] as String? ?? '').trim();
      _emergencyAddressController.text =
          (client['emergencyAddress'] as String? ?? '').trim();
    });
  }

  void _openClientPicker(BuildContext context) {
    if (_clients.isEmpty) return;
    String query = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          final filtered = _clients.where((c) {
            if (query.isEmpty) return true;
            final name = (c['name'] as String? ?? '').toLowerCase();
            final email = (c['email'] as String? ?? '').toLowerCase();
            final phone = (c['phone'] as String? ?? '').toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || email.contains(q) || phone.contains(q);
          }).toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A2E).withOpacity(0.98),
                  const Color(0xFF16213E).withOpacity(0.98),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, email ou téléphone',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF6C63FF)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sélectionner un client',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('Aucun client', style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            final name = (c['name'] as String? ?? '').trim();
                            final email = (c['email'] as String? ?? '').trim();
                            final phone = (c['phone'] as String? ?? '').trim();
                            return ListTile(
                              tileColor: Colors.white.withOpacity(0.03),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: Text(
                                name.isEmpty ? 'Client' : name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (email.isNotEmpty)
                                    Text(email, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                  if (phone.isNotEmpty)
                                    Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                _applyClientToForm(c);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemCount: filtered.length,
                        ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _applyRoomSelection(String? number) {
    if (number == null) return;
    final room = _rooms.firstWhere(
      (r) => r['number']?.toString() == number,
      orElse: () => {},
    );
    if (room.isEmpty) return;
    final rate = (room['rate'] as num?)?.toDouble() ?? 0;
    final type = room['type'] as String?;
    final bed = room['bedType'] as String?;

    setState(() {
      _selectedRoomNumber = number;
      _roomNumberController.text = number;
      if (type != null && type.isNotEmpty) {
        if (!_roomTypes.contains(type)) _roomTypes.add(type);
        _roomType = type;
      }
      if (bed != null && bed.isNotEmpty) {
        if (!_bedTypes.contains(bed)) _bedTypes.add(bed);
        _bedType = bed;
      }
      _prefillAmountFromRate(rate);
    });
  }

  void _prefillAmountFromRate(double rate) {
    if (rate <= 0) return;
    final nights = _calculateNights();
    final nightsCount = nights > 0 ? nights : 1;
    final total = rate * nightsCount;
    _amountController.text = total.toStringAsFixed(0);
  }

  double _currentRoomRate() {
    final room = _rooms.firstWhere(
      (r) => r['number'] == _selectedRoomNumber,
      orElse: () => {},
    );
    return (room['rate'] as num?)?.toDouble() ?? 0;
  }

  void _addRoomType() async {
    final name = _newRoomTypeController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addRoomType(name);
    _newRoomTypeController.clear();
    await _loadMetadata();
    setState(() => _roomType = name);
  }

  void _addBedType() {
    final name = _newBedTypeController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_bedTypes.contains(name)) _bedTypes.add(name);
      _bedType = name;
      _newBedTypeController.clear();
    });
  }

  void _addService() {
    final name = _newServiceController.text.trim();
    if (name.isEmpty) return;
    LocalDatabase.instance.addService(name).then((_) => _loadMetadata());
    setState(() {
      _customServices.add(_ServiceOption(name, selected: true));
      _newServiceController.clear();
    });
  }

  void _toggleService(_ServiceOption option, bool value) {
    setState(() {
      option.selected = value;
    });
  }

  void _removeService(_ServiceOption option) {
    setState(() {
      _customServices.remove(option);
    });
  }

  Future<void> _pickSimpleDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  int _calculateNights() {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkIn == null || _checkOut == null) {
      _showSnack('Sélectionne une date d\'arrivée et de départ');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
      final selectedServices = _customServices
          .where((s) => s.selected)
          .map((s) => s.name)
          .toList();
      if (_reservationId != null) {
        await LocalDatabase.instance.updateReservation(
          id: _reservationId!,
          guestName: _guestNameController.text.trim(),
          roomNumber: _roomNumberController.text.trim(),
          checkIn: _checkIn!,
          checkOut: _checkOut!,
          status: _toDbStatus(_status),
          amount: amount,
          dateOfBirth: _dateOfBirth,
          placeOfBirth: _valueOrNull(_placeOfBirthController),
          nationality: _valueOrNull(_nationalityController),
          profession: _valueOrNull(_professionController),
          domicile: _valueOrNull(_domicileController),
          travelReason: _valueOrNull(_travelReasonController),
          comingFrom: _valueOrNull(_comingFromController),
          goingTo: _valueOrNull(_goingToController),
          lodgingType: _lodgingType,
          roomType: _roomType,
          bedType: _bedType,
          adults: int.tryParse(_adultsController.text) ?? 1,
          children: int.tryParse(_childrenController.text) ?? 0,
          reservationSource: _reservationSource,
          paymentStatus: _paymentStatus,
          breakfastIncluded: _breakfastIncluded,
          parkingIncluded: _parkingIncluded,
          wifiIncluded: _wifiIncluded,
          services: selectedServices.isEmpty ? null : selectedServices,
          idNumber: _valueOrNull(_idNumberController),
          idIssuedOn: _idIssuedOn,
          idIssuedAt: _valueOrNull(_idIssuedAtController),
          visaNumber: _valueOrNull(_visaNumberController),
          visaIssuedOn: _visaIssuedOn,
          visaIssuedAt: _valueOrNull(_visaIssuedAtController),
          emergencyAddress: _valueOrNull(_emergencyAddressController),
          checkInTime: _checkInTime,
          checkOutTime: _checkOutTime,
          guestEmail: _guestEmailController.text.trim().isEmpty
              ? null
              : _guestEmailController.text.trim(),
          guestPhone: _guestPhoneController.text.trim().isEmpty
              ? null
              : _guestPhoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        await LocalDatabase.instance.insertReservation(
          guestName: _guestNameController.text.trim(),
          roomNumber: _roomNumberController.text.trim(),
          checkIn: _checkIn!,
          checkOut: _checkOut!,
          status: _toDbStatus(_status),
          amount: amount,
          dateOfBirth: _dateOfBirth,
          placeOfBirth: _valueOrNull(_placeOfBirthController),
          nationality: _valueOrNull(_nationalityController),
          profession: _valueOrNull(_professionController),
          domicile: _valueOrNull(_domicileController),
          travelReason: _valueOrNull(_travelReasonController),
          comingFrom: _valueOrNull(_comingFromController),
          goingTo: _valueOrNull(_goingToController),
          lodgingType: _lodgingType,
          roomType: _roomType,
          bedType: _bedType,
          adults: int.tryParse(_adultsController.text) ?? 1,
          children: int.tryParse(_childrenController.text) ?? 0,
          reservationSource: _reservationSource,
          paymentStatus: _paymentStatus,
          breakfastIncluded: _breakfastIncluded,
          parkingIncluded: _parkingIncluded,
          wifiIncluded: _wifiIncluded,
          services: selectedServices.isEmpty ? null : selectedServices,
          idNumber: _valueOrNull(_idNumberController),
          idIssuedOn: _idIssuedOn,
          idIssuedAt: _valueOrNull(_idIssuedAtController),
          visaNumber: _valueOrNull(_visaNumberController),
          visaIssuedOn: _visaIssuedOn,
          visaIssuedAt: _valueOrNull(_visaIssuedAtController),
          emergencyAddress: _valueOrNull(_emergencyAddressController),
          checkInTime: _checkInTime,
          checkOutTime: _checkOutTime,
          guestEmail: _guestEmailController.text.trim().isEmpty
              ? null
              : _guestEmailController.text.trim(),
          guestPhone: _guestPhoneController.text.trim().isEmpty
              ? null
              : _guestPhoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }
      if (!mounted) return;
      _showSnack(
        _reservationId != null
            ? 'Réservation mise à jour'
            : 'Réservation enregistrée avec succès',
      );
      if (_isEdit) {
        Navigator.pop(context, true);
      } else {
        _formKey.currentState!.reset();
        setState(() {
          _checkIn = null;
          _checkOut = null;
          _dateOfBirth = null;
          _idIssuedOn = null;
          _visaIssuedOn = null;
          _lodgingType = 'Chambre';
          _roomType = 'Standard';
          _bedType = 'Double';
          _reservationSource = 'Direct';
          _status = 'Confirmée';
          _paymentStatus = 'En attente';
          _breakfastIncluded = false;
          _parkingIncluded = false;
          _wifiIncluded = true;
          _adultsController.text = '1';
          _childrenController.text = '0';
          _checkInTime = const TimeOfDay(hour: 14, minute: 0);
          _checkOutTime = const TimeOfDay(hour: 12, minute: 0);
          for (final s in _customServices) {
            s.selected = false;
          }
        });
        _guestNameController.clear();
        _guestEmailController.clear();
        _guestPhoneController.clear();
        _roomNumberController.clear();
        _amountController.clear();
        _notesController.clear();
        _placeOfBirthController.clear();
        _professionController.clear();
        _domicileController.clear();
        _travelReasonController.clear();
        _comingFromController.clear();
        _goingToController.clear();
        _idIssuedAtController.clear();
        _visaNumberController.clear();
        _visaIssuedAtController.clear();
        _emergencyAddressController.clear();
        _nationalityController.clear();
        _idNumberController.clear();
        _companyController.clear();
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _valueOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.95),
            const Color(0xFF16213E).withOpacity(0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4facfe).withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.add_circle_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Text(
            'Nouvelle Réservation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final nights = _calculateNights();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Informations réservation
          FutureBuilder<void>(
            future: _clientsFuture,
            builder: (context, snapshot) {
              return Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _clients.isEmpty ? null : () => _openClientPicker(context),
                  icon: const Icon(Icons.person_search, color: Colors.white),
                  label: Text(
                    _clients.isEmpty ? 'Chargement des clients...' : 'Pré-remplir avec un client',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSectionHeader('Informations réservation', Icons.event_note),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDateTimeField(
                  label: 'Arrivée',
                  date: _checkIn,
                  time: _checkInTime,
                  onDateTap: () => _pickDate(isCheckIn: true),
                  onTimeTap: () => _pickTime(isCheckIn: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeField(
                  label: 'Départ',
                  date: _checkOut,
                  time: _checkOutTime,
                  onDateTap: () => _pickDate(isCheckIn: false),
                  onTimeTap: () => _pickTime(isCheckIn: false),
                ),
              ),
            ],
          ),

          if (nights > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  '$nights nuit${nights > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Type de chambre',
                  value: _roomType,
                  items: _roomTypes,
                  icon: Icons.hotel,
                  onChanged: (v) => setState(() => _roomType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Logement',
                  value: _lodgingType,
                  items: _lodgingTypes,
                  icon: Icons.apartment_rounded,
                  onChanged: (v) => setState(() => _lodgingType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildRoomDropdown()),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInlineAddField(
                  controller: _newRoomTypeController,
                  hint: 'Ajouter un type de chambre',
                  onAdd: _addRoomType,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInlineAddField(
                  controller: _newBedTypeController,
                  hint: 'Ajouter un type de lit',
                  onAdd: _addBedType,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Type de lit',
                  value: _bedType,
                  items: _bedTypes,
                  icon: Icons.bed,
                  onChanged: (v) => setState(() => _bedType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _adultsController,
                  label: 'Adultes',
                  icon: Icons.person,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _childrenController,
                  label: 'Enfants',
                  icon: Icons.child_care,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Informations client
          _buildSectionHeader('Informations client', Icons.person),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _guestNameController,
            label: 'Nom complet du client',
            icon: Icons.person_rounded,
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _guestEmailController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _guestPhoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Date de naissance',
                  value: _dateOfBirth,
                  onTap: () => _pickSimpleDate(
                    current: _dateOfBirth,
                    onPicked: (d) => _dateOfBirth = d,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _placeOfBirthController,
                  label: 'Lieu de naissance',
                  icon: Icons.place_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _nationalityController,
                  label: 'Nationalité',
                  icon: Icons.flag,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _professionController,
                  label: 'Profession',
                  icon: Icons.work_outline_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _domicileController,
                  label: 'Domicile',
                  icon: Icons.home_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _travelReasonController,
                  label: 'Motif du voyage',
                  icon: Icons.airplanemode_active_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _comingFromController,
                  label: 'Venant de',
                  icon: Icons.location_searching_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _goingToController,
                  label: 'Allant à',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _idNumberController,
                  label: 'N° Pièce d\'identité',
                  icon: Icons.badge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Délivré le',
                  value: _idIssuedOn,
                  onTap: () => _pickSimpleDate(
                    current: _idIssuedOn,
                    onPicked: (d) => _idIssuedOn = d,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _idIssuedAtController,
                  label: 'Délivré à',
                  icon: Icons.location_city_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _visaNumberController,
                  label: 'Visa N°',
                  icon: Icons.verified_user_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Visa délivré le',
                  value: _visaIssuedOn,
                  onTap: () => _pickSimpleDate(
                    current: _visaIssuedOn,
                    onPicked: (d) => _visaIssuedOn = d,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _visaIssuedAtController,
                  label: 'Visa délivré à',
                  icon: Icons.map_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _buildTextField(
            controller: _emergencyAddressController,
            label: 'Adresse personne à prévenir',
            icon: Icons.emergency_outlined,
            maxLines: 2,
          ),

          const SizedBox(height: 12),
          _buildTextField(
            controller: _companyController,
            label: 'Entreprise (optionnel)',
            icon: Icons.business,
          ),

          const SizedBox(height: 24),

          // Section: Détails tarifaires
          _buildSectionHeader('Détails tarifaires', Icons.payments),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _amountController,
                  label: 'Montant total (FCFA)',
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Statut paiement',
                  value: _paymentStatus,
                  items: _paymentStatusOptions,
                  icon: Icons.account_balance_wallet,
                  onChanged: (v) => setState(() => _paymentStatus = v!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Services inclus
          _buildServicesSection(),

          const SizedBox(height: 24),

          // Section: Statut et source
          _buildSectionHeader('Statut et source', Icons.info_outline),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Statut réservation',
                  value: _status,
                  items: _statusOptions,
                  icon: Icons.check_circle_outline,
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Source réservation',
                  value: _reservationSource,
                  items: _sources,
                  icon: Icons.source,
                  onChanged: (v) => setState(() => _reservationSource = v!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Notes
          _buildSectionHeader('Notes & Demandes spéciales', Icons.notes),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _notesController,
            label: 'Notes, préférences, demandes spéciales...',
            icon: Icons.notes_rounded,
            maxLines: 4,
          ),

          const SizedBox(height: 28),

          // Bouton d'enregistrement
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF4facfe),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Enregistrer la réservation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services inclus',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckbox(
            label: 'Petit-déjeuner inclus',
            value: _breakfastIncluded,
            icon: Icons.restaurant,
            onChanged: (v) => setState(() => _breakfastIncluded = v!),
          ),
          _buildCheckbox(
            label: 'Parking inclus',
            value: _parkingIncluded,
            icon: Icons.local_parking,
            onChanged: (v) => setState(() => _parkingIncluded = v!),
          ),
          _buildCheckbox(
            label: 'WiFi gratuit',
            value: _wifiIncluded,
            icon: Icons.wifi,
            onChanged: (v) => setState(() => _wifiIncluded = v!),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customServices
                .map(
                  (s) => ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.name),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeService(s),
                          child: const Icon(Icons.close, size: 14),
                        ),
                      ],
                    ),
                    selected: s.selected,
                    onSelected: (val) => _toggleService(s, val),
                    selectedColor: const Color(0xFF6C63FF).withOpacity(0.25),
                    labelStyle: TextStyle(
                      color: s.selected ? Colors.white : Colors.white70,
                    ),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    side: BorderSide(
                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          _buildInlineAddField(
            controller: _newServiceController,
            hint: 'Ajouter un service',
            onAdd: _addService,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineAddField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6C63FF)),
              ),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF6C63FF)),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required IconData icon,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF6C63FF);
                }
                return Colors.transparent;
              }),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            Icon(icon, color: const Color(0xFF6C63FF), size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure the value exists in items, otherwise use the first item
    final validValue = items.contains(value) && value.isNotEmpty ? value : (items.isNotEmpty ? items.first : '');
    
    return DropdownButtonFormField<String>(
      value: validValue.isNotEmpty ? validValue : null,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF1A1A2E),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    IconData icon = Icons.calendar_today,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6C63FF), size: 18),
                const SizedBox(width: 8),
                Text(
                  value == null ? 'Sélectionner' : _dateFormat.format(value),
                  style: TextStyle(
                    color: value == null ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomDropdown() {
    if (_rooms.isEmpty) {
      return _buildTextField(
        controller: _roomNumberController,
        label: 'N° Chambre',
        icon: Icons.meeting_room_rounded,
        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
      );
    }
    final items = _rooms
        .map((r) => r['number']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final value = items.contains(_selectedRoomNumber)
        ? _selectedRoomNumber
        : null;
    if (value == null && _selectedRoomNumber != null) {
      // Si la chambre sélectionnée n'existe plus, repasse en saisie libre.
      _roomNumberController.text = _selectedRoomNumber!;
      return _buildTextField(
        controller: _roomNumberController,
        label: 'N° Chambre',
        icon: Icons.meeting_room_rounded,
        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
      );
    }
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (num) => DropdownMenuItem<String>(
              value: num,
              child: Text('Chambre $num'),
            ),
          )
          .toList(),
      onChanged: (v) {
        _applyRoomSelection(v);
      },
      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF1A1A2E),
      decoration: InputDecoration(
        labelText: 'N° Chambre',
        prefixIcon: const Icon(
          Icons.meeting_room_rounded,
          color: Color(0xFF6C63FF),
        ),
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
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF6C63FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date == null ? 'Date' : _dateFormat.format(date),
                        style: TextStyle(
                          color: date == null ? Colors.white54 : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: onTimeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF6C63FF),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time.format(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceOption {
  _ServiceOption(this.name, {this.selected = false});

  final String name;
  bool selected;
}
