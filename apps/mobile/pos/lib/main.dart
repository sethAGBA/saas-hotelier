import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import 'data/models.dart';
import 'data/pos_repository.dart';
import 'services/printer_service.dart';
import 'services/auth_service.dart';
import 'widgets/lock_screen.dart';
import 'services/pdf_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RestaurantPOSApp());
}

class AppColors {
  static const Color backgroundStart = Color(0xFF0F2027);
  static const Color backgroundEnd = Color(0xFF2C5364);
  static const Color surfaceLight = Color(0xFFF6F7FB);
  static const Color primaryAccent = Color(0xFF00B3C7);
  static const Color secondaryAccent = Color(0xFF5368E0);
  static const Color highlight = Color(0xFFFFB703);
  static const Color availableStart = Color(0xFF06D6A0);
  static const Color availableEnd = Color(0xFF1B9AAA);
  static const Color occupiedStart = Color(0xFFEF476F);
  static const Color occupiedEnd = Color(0xFFF78CA0);
  static const Color selectedStart = Color(0xFFFF9A3C);
  static const Color selectedEnd = Color(0xFFFF5F6D);
  static const Color menuGradientStart = Color(0xFF4F46E5);
  static const Color menuGradientEnd = Color(0xFF5DE0E6);
  static const Color pillDefault = Color(0xFFE8ECF4);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color tabBackground = Color(0xFFF1F4F9);
}

ImageProvider? menuItemImageProvider(MenuItem item) {
  final path = item.imagePath;
  if (path == null || path.isEmpty) {
    return null;
  }
  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }
  return FileImage(file);
}

class CheckoutResult {
  CheckoutResult({
    required this.paymentMethod,
    required this.tipAmount,
    required this.subtotal,
    required this.discountAmount,
    required this.totalPaid,
    required this.paidAt,
    required this.saveReceipt,
    this.receiptDirectory,
    this.payments = const [],
  });

  final String paymentMethod;
  final double tipAmount;
  final double subtotal;
  final double discountAmount;
  final double totalPaid;
  final DateTime paidAt;
  final bool saveReceipt;
  final String? receiptDirectory;
  final List<PaymentFragment> payments;
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryAccent,
          brightness: Brightness.light,
        ).copyWith(secondary: AppColors.secondaryAccent),
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.surfaceLight,
      ),
      home: const POSHomePage(),
    );
  }
}

// Main POS Page
class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedTableNumber;
  String _selectedCategory = 'Tous';
  PosRepository? _repository;
  List<DiningTable> _tables = [];
  List<MenuItem> _menuItems = [];
  List<SalesRecord> _salesRecords = [];
  List<CatalogLogEntry> _catalogLogs = [];
  AppSettings? _settings;
  late final PrinterService _printerService;
  late final AuthService _authService;
  final PdfService _pdfService = PdfService();
  PosRole? _currentRole;
  bool _showLockScreen = true;
  late TextEditingController _restaurantNameController;
  late TextEditingController _staffPinController;
  late TextEditingController _managerPinController;
  late TextEditingController _userNameController;
  late TextEditingController _tableCountController;
  late TextEditingController _userPinController;
  late TextEditingController _categoryNameController;
  late TextEditingController _tableSearchController;
  late TextEditingController _menuSearchController;
  late TextEditingController _catalogSearchController;
  PosRole _newUserRole = PosRole.staff;
  List<UserProfile> _userProfiles = [];
  static const List<String> _defaultMenuCategories = [
    'Entrées',
    'Plats',
    'Desserts',
    'Boissons',
  ];
  List<String> _categories = ['Tous', ..._defaultMenuCategories];
  static const int _minTableCount = 1;
  static const int _maxTableCount = 50;
  static const List<String> _imageExtensions = [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
  ];

  String _tableSearchQuery = '';
  String _menuSearchQuery = '';
  String _catalogSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _printerService = ConsolePrinterService();
    _authService = AuthService();
    _restaurantNameController = TextEditingController();
    _staffPinController = TextEditingController();
    _managerPinController = TextEditingController();
    _userNameController = TextEditingController();
    _tableCountController = TextEditingController();
    _userPinController = TextEditingController();
    _categoryNameController = TextEditingController();
    _tableSearchController = TextEditingController();
    _menuSearchController = TextEditingController();
    _catalogSearchController = TextEditingController();
    _tabController = TabController(length: 5, vsync: this);
    _initializeRepository();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _restaurantNameController.dispose();
    _staffPinController.dispose();
    _managerPinController.dispose();
    _userNameController.dispose();
    _tableCountController.dispose();
    _userPinController.dispose();
    _categoryNameController.dispose();
    _tableSearchController.dispose();
    _menuSearchController.dispose();
    _catalogSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeRepository() async {
    final repository = await PosRepository.initialize();
    if (!mounted) return;
    setState(() {
      _repository = repository;
      _tables = repository.tables;
      _menuItems = repository.menuItems;
      _salesRecords = repository.salesRecords;
      _settings = repository.settings;
      _authService.updatePins(
        staffPin: repository.settings.staffPin,
        managerPin: repository.settings.managerPin,
      );
      _authService.updateUsers(repository.settings.users);
      _restaurantNameController.text = repository.settings.restaurantName;
      _staffPinController.text = repository.settings.staffPin;
      _managerPinController.text = repository.settings.managerPin;
      _userProfiles = List<UserProfile>.from(repository.settings.users);
      _tableCountController.text =
          repository.settings.tableCount.toString();
      final baseCategories = repository.settings.categories.isEmpty
          ? _defaultMenuCategories
          : repository.settings.categories;
      _categories = _buildCategoryList(baseCategories);
      _catalogLogs = List<CatalogLogEntry>.from(repository.catalogLogs);
    });
    _syncCategoriesFromMenu(repository.menuItems);
  }

  void _syncCategoriesFromMenu(List<MenuItem> items) {
    for (final item in items) {
      _registerCategory(item.category, persist: false);
    }
  }

  void _persistTables() {
    final repository = _repository;
    if (repository != null) {
      unawaited(repository.saveTables());
    }
  }

  void _updateMenuItemLocally(MenuItem updated) {
    final index = _menuItems.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      _menuItems.add(updated);
    } else {
      _menuItems[index] = updated;
    }
    _menuItems.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    _registerCategory(updated.category);
  }

  void _registerCategory(String category, {bool persist = true}) {
    final normalized = category.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'tous') {
      return;
    }
    final settings = _settings;
    if (settings == null) {
      if (!_categories.contains(normalized)) {
        setState(() {
          final current = List<String>.from(_categories)
            ..removeWhere((value) => value == 'Tous');
          current.add(normalized);
          _categories = _buildCategoryList(current);
        });
      }
      return;
    }
    if (settings.categories.contains(normalized)) {
      if (!_categories.contains(normalized)) {
        setState(() {
          _categories = _buildCategoryList(settings.categories);
        });
      }
      return;
    }
    final updated = List<String>.from(settings.categories)..add(normalized);
    _updateCategorySettings(updated, persist: persist);
  }

  void _addCustomCategory() {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty || name.toLowerCase() == 'tous') return;
    final settings = _settings;
    if (settings == null) return;
    final existing = settings.categories.map((c) => c.toLowerCase()).toSet();
    if (existing.contains(name.toLowerCase())) {
      _categoryNameController.clear();
      return;
    }
    final updated = List<String>.from(settings.categories)..add(name);
    _updateCategorySettings(updated, persist: true);
    unawaited(
      _logCatalogChange(
        action: 'Catégorie',
        details: 'Ajout de $name',
      ),
    );
    _categoryNameController.clear();
  }

  void _removeCustomCategory(String category) {
    final settings = _settings;
    if (settings == null) return;
    if (!settings.categories.contains(category)) return;
    final updated = List<String>.from(settings.categories)..remove(category);
    _updateCategorySettings(updated, persist: true);
    unawaited(
      _logCatalogChange(
        action: 'Catégorie',
        details: 'Suppression de $category',
      ),
    );
  }

  Future<void> _logCatalogChange({
    MenuItem? item,
    required String action,
    required String details,
  }) async {
    final repository = _repository;
    if (repository == null) return;
    final entry = CatalogLogEntry(
      id: 'clog-${DateTime.now().millisecondsSinceEpoch}',
      itemId: item?.id ?? 'catalogue',
      itemName: item?.name ?? 'Catalogue',
      action: action,
      details: details,
      user: _currentRole == PosRole.manager ? 'Manager' : 'Staff',
      timestamp: DateTime.now(),
    );
    await repository.appendCatalogLog(entry);
    if (!mounted) return;
    setState(() {
      _catalogLogs = List<CatalogLogEntry>.from(repository.catalogLogs);
    });
  }

  String _describeMenuItemChanges(MenuItem before, MenuItem after) {
    final diffs = <String>[];
    if (before.price != after.price) {
      diffs.add(
        'Prix: ${before.price.toStringAsFixed(2)} → ${after.price.toStringAsFixed(2)}',
      );
    }
    if (before.vatRate != after.vatRate) {
      diffs.add(
        'TVA: ${before.vatRate.toStringAsFixed(1)}% → ${after.vatRate.toStringAsFixed(1)}%',
      );
    }
    if (before.category != after.category) {
      diffs.add('Catégorie: ${before.category} → ${after.category}');
    }
    if (before.availability != after.availability) {
      diffs.add(
        'Disponibilité: ${_availabilityLabel(before.availability)} → ${_availabilityLabel(after.availability)}',
      );
    }
    if (before.description != after.description) {
      diffs.add('Description mise à jour');
    }
    return diffs.join(' • ');
  }

  void _persistMenuItem(MenuItem updated) {
    final repository = _repository;
    if (repository != null) {
      unawaited(repository.updateMenuItem(updated));
    }
  }

  void _updateMenuAvailability(
    MenuItem item,
    MenuAvailability availability,
  ) {
    final updated = item.copyWith(availability: availability);
    setState(() {
      _updateMenuItemLocally(updated);
    });
    _persistMenuItem(updated);
    final label = _availabilityLabel(availability);
    _showSnackBar(
      '${item.name}: $label',
      _availabilityColor(availability),
    );
    unawaited(
      _logCatalogChange(
        item: updated,
        action: 'Disponibilité',
        details: 'Définie sur $label',
      ),
    );
  }

  void _createTicketsForTable(DiningTable table) {
    final kitchenItems = table.orders
        .where((item) => item.menuItem.category != 'Boissons')
        .toList();
    final barItems = table.orders
        .where((item) => item.menuItem.category == 'Boissons')
        .toList();

    final newTickets = <ProductionTicket>[];
    if (kitchenItems.isNotEmpty) {
      newTickets.add(
        ProductionTicket(
          id: 'k-${DateTime.now().millisecondsSinceEpoch}',
          type: TicketType.kitchen,
          status: TicketStatus.pending,
          createdAt: DateTime.now(),
          items: kitchenItems
              .map(
                (order) => OrderItem(
                  menuItem: order.menuItem,
                  quantity: order.quantity,
                  notes: order.notes,
                ),
              )
              .toList(),
          tableNumber: table.number,
        ),
      );
    }

    if (barItems.isNotEmpty) {
      newTickets.add(
        ProductionTicket(
          id: 'b-${DateTime.now().millisecondsSinceEpoch}',
          type: TicketType.bar,
          status: TicketStatus.pending,
          createdAt: DateTime.now(),
          items: barItems
              .map(
                (order) => OrderItem(
                  menuItem: order.menuItem,
                  quantity: order.quantity,
                  notes: order.notes,
                ),
              )
              .toList(),
          tableNumber: table.number,
        ),
      );
    }

    table.tickets.addAll(newTickets);
    for (final ticket in newTickets) {
      unawaited(_printerService.printTicket(ticket));
    }
  }

  Future<void> _handlePinSubmit(String pin) async {
    final success = await _authService.authenticate(pin);
    if (!mounted) return;
    if (success) {
      setState(() {
        _currentRole = _authService.currentRole;
        _showLockScreen = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code invalide'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(0)} FCFA';
  }

  String _formatTime(DateTime timestamp) {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatLogTimestamp(DateTime timestamp) {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year.toString();
    return '$day/$month/$year · ${_formatTime(timestamp)}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _editMenuItem(MenuItem item) async {
    final result = await _showMenuItemEditor(item: item);

    if (result == null) return;

    setState(() {
      _updateMenuItemLocally(result);
    });
    _persistMenuItem(result);
    _showSnackBar('${result.name} mis à jour', AppColors.primaryAccent);
    final diff = _describeMenuItemChanges(item, result);
    if (diff.isNotEmpty) {
      unawaited(
        _logCatalogChange(
          item: result,
          action: 'Modification',
          details: diff,
        ),
      );
    }
  }

  Future<void> _completeCheckout(
    DiningTable table,
    CheckoutResult result, {
    bool dismissSheet = false,
  }) async {
    final saleLines = _logSale(table, result);
    File? receiptFile;
    if (result.saveReceipt) {
      receiptFile = await _printReceipt(table, result);
    }
    setState(() {
      table.lastReceiptLines = saleLines;
      table.lastSubtotal = result.subtotal;
      table.lastDiscountAmount = result.discountAmount;
      if (receiptFile != null) {
        table.lastReceiptPath = receiptFile.path;
      }
      table.orders.clear();
      table.isOccupied = false;
      table.occupiedSince = null;
      table.lastBillTotal = result.totalPaid;
      table.lastTipAmount = result.tipAmount;
      final summary = result.payments.isNotEmpty
          ? _describePayments(result.payments)
          : result.paymentMethod;
      table.lastPaymentMethod =
          summary.isEmpty ? result.paymentMethod : summary;
      table.lastPaidAt = result.paidAt;
      if (_selectedTableNumber == table.number) {
        _selectedTableNumber = null;
      }
    });
    _persistTables();
    if (dismissSheet && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _showSnackBar('Table ${table.number} libérée', AppColors.secondaryAccent);
  }

  List<SalesLine> _logSale(DiningTable table, CheckoutResult result) {
    if (table.orders.isEmpty) {
      return const <SalesLine>[];
    }

    final lines = table.orders
        .map(
          (order) => SalesLine(
            itemId: order.menuItem.id,
            name: order.menuItem.name,
            quantity: order.quantity,
            total: order.menuItem.price * order.quantity,
          ),
        )
        .toList();

    final baseAmount =
        (result.totalPaid - result.tipAmount).clamp(0, double.infinity)
            as double;

    final paymentFragments = result.payments.isNotEmpty
        ? result.payments
        : [
            PaymentFragment(
              method: result.paymentMethod,
              amount: result.totalPaid,
            ),
          ];
    final paymentSummary = _describePayments(paymentFragments).isEmpty
        ? result.paymentMethod
        : _describePayments(paymentFragments);

    final sale = SalesRecord(
      id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      amount: baseAmount,
      tip: result.tipAmount,
      paymentMethod: paymentSummary,
      tableNumber: table.number,
      lines: lines,
      payments: paymentFragments,
    );

    setState(() {
      _salesRecords = List<SalesRecord>.from(_salesRecords)..add(sale);
    });
    _repository?.appendSale(sale);
    return lines;
  }

  String _generateMenuItemId() {
    return 'item-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _describePayments(List<PaymentFragment> fragments) {
    if (fragments.isEmpty) {
      return '';
    }
    if (fragments.length == 1) {
      return fragments.first.method;
    }
    return fragments
        .map(
          (fragment) =>
              '${fragment.method} (${fragment.amount.toStringAsFixed(0)} FCFA)',
        )
        .join(' + ');
  }

  String _availabilityLabel(MenuAvailability status) {
    switch (status) {
      case MenuAvailability.available:
        return 'Disponible';
      case MenuAvailability.outOfStock:
        return 'Rupture';
      case MenuAvailability.seasonal:
        return 'Saisonnier';
    }
  }

  Color _availabilityColor(MenuAvailability status) {
    switch (status) {
      case MenuAvailability.available:
        return AppColors.availableStart;
      case MenuAvailability.outOfStock:
        return AppColors.occupiedStart;
      case MenuAvailability.seasonal:
        return AppColors.highlight;
    }
  }

  Widget _buildAvailabilityChip(MenuAvailability status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _availabilityColor(status)),
      ),
      child: Text(
        _availabilityLabel(status),
        style: TextStyle(
          color: _availabilityColor(status),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<String> _sanitizeCategories(List<String> raw) {
    final seen = <String>{};
    final sanitized = <String>[];
    for (final entry in raw) {
      final normalized = entry.trim();
      if (normalized.isEmpty) continue;
      final lower = normalized.toLowerCase();
      if (lower == 'tous') continue;
      if (seen.add(lower)) {
        sanitized.add(normalized);
      }
    }
    return sanitized;
  }

  List<String> _buildCategoryList(List<String> raw) {
    final sanitized = _sanitizeCategories(raw);
    if (sanitized.isEmpty) {
      sanitized.addAll(_defaultMenuCategories);
    }
    return ['Tous', ...sanitized];
  }

  void _updateCategorySettings(
    List<String> categories, {
    bool persist = false,
  }) {
    final settings = _settings;
    if (settings == null) return;
    final sanitized = _sanitizeCategories(categories);
    final updated = settings.copyWith(categories: sanitized);
    setState(() {
      _settings = updated;
      _categories = _buildCategoryList(sanitized);
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Tous';
      }
    });
    if (persist) {
      _repository?.updateSettings(updated);
    }
  }

  void _handleTableSearch(String value) {
    setState(() {
      _tableSearchQuery = value;
    });
  }

  void _handleMenuSearch(String value) {
    setState(() {
      _menuSearchQuery = value;
    });
  }

  void _handleCatalogSearch(String value) {
    setState(() {
      _catalogSearchQuery = value;
    });
  }

  List<DiningTable> _filteredTables() {
    final query = _tableSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _tables;
    return _tables.where((table) {
      final numberMatch = table.number.toString().contains(query);
      if (numberMatch) return true;
      final status = table.isOccupied ? 'occupée' : 'libre';
      if (status.contains(query)) return true;
      final label = 'table ${table.number}'.toLowerCase();
      if (label.contains(query)) return true;
      for (final order in table.orders) {
        if (order.menuItem.name.toLowerCase().contains(query)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  List<MenuItem> _filterMenuItems(List<MenuItem> items, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return items;
    return items.where((item) => _matchesMenuQuery(item, normalized)).toList();
  }

  bool _matchesMenuQuery(MenuItem item, String query) {
    return item.name.toLowerCase().contains(query) ||
        item.description.toLowerCase().contains(query) ||
        item.category.toLowerCase().contains(query);
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.clear),
              ),
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  Widget _buildEmptySearchMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _extensionOf(String value) {
    final lastDot = value.lastIndexOf('.');
    if (lastDot == -1 || lastDot == value.length - 1) {
      return '.png';
    }
    final ext = value.substring(lastDot);
    if (ext.length > 6) {
      return '.png';
    }
    return ext;
  }

  Future<String?> _pickMenuImage() async {
    final result = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Images',
          extensions: _imageExtensions,
        ),
      ],
    );
    if (result == null || result.path == null) {
      return null;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/menu_images');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final extension = _extensionOf(result.name ?? result.path!);
      final newPath =
          '${targetDir.path}/menu_${DateTime.now().millisecondsSinceEpoch}$extension';
      await File(result.path!).copy(newPath);
      return newPath;
    } catch (error) {
      if (mounted) {
        _showSnackBar('Erreur image: $error', Colors.redAccent);
      }
      return null;
    }
  }

  Future<MenuItem?> _showMenuItemEditor({MenuItem? item}) {
    return showDialog<MenuItem>(
      context: context,
      builder: (context) => MenuItemEditorDialog(
        existing: item,
        onPickImage: _pickMenuImage,
        idFactory: _generateMenuItemId,
      ),
    );
  }

  Future<void> _createMenuItem() async {
    final result = await _showMenuItemEditor();
    if (result == null) return;
    setState(() {
      _updateMenuItemLocally(result);
    });
    _persistMenuItem(result);
    _showSnackBar('${result.name} ajouté', AppColors.availableStart);
    unawaited(
      _logCatalogChange(
        item: result,
        action: 'Création',
        details: 'Ajout manuel dans le catalogue',
      ),
    );
  }

  Future<bool> _applyTableCountChange(int desiredCount) async {
    final repository = _repository;
    if (repository == null) {
      return false;
    }
    final sanitized = desiredCount
        .clamp(_minTableCount, _maxTableCount)
        .toInt();

    if (sanitized < _tables.length) {
      final blockingTables = _tables
          .where(
            (table) =>
                table.number > sanitized &&
                (table.isOccupied || table.orders.isNotEmpty),
          )
          .map((table) => table.number)
          .toList();
      if (blockingTables.isNotEmpty) {
        _showSnackBar(
          'Libérez les tables ${blockingTables.join(', ')} avant de réduire.',
          AppColors.occupiedStart,
        );
        return false;
      }
    }

    await repository.setTableCount(sanitized);
    setState(() {
      _tables = repository.tables;
      if (_selectedTableNumber != null &&
          _selectedTableNumber! > sanitized) {
        _selectedTableNumber = null;
      }
    });
    return true;
  }

  Future<void> _cancelTableOrder(DiningTable table) async {
    if (table.orders.isEmpty) {
      _showSnackBar('Aucune commande à annuler', AppColors.textMuted);
      return;
    }
    final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Annuler la commande de la table ${table.number}?'),
            content: const Text(
              'Cette action supprimera tous les articles en cours et remettra la table en statut libre.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Conserver'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.occupiedStart,
                ),
                child: const Text('Annuler la commande'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldCancel) return;

    setState(() {
      table.orders.clear();
      table.isOccupied = false;
      table.occupiedSince = null;
      table.tickets.clear();
      if (_selectedTableNumber == table.number) {
        _selectedTableNumber = null;
      }
    });
    _persistTables();
    _showSnackBar(
      'Commande annulée pour table ${table.number}',
      AppColors.occupiedStart,
    );
  }

  Future<File?> _printReceipt(
    DiningTable table,
    CheckoutResult result,
  ) async {
    final settings = _settings;
    if (settings == null || table.orders.isEmpty) {
      return null;
    }
    final snapshot = table.orders
        .map(
          (order) => OrderItem(
            menuItem: order.menuItem,
            quantity: order.quantity,
            notes: order.notes,
          ),
        )
        .toList();
    final directory = result.receiptDirectory ??
        (settings.pdfDirectory.isEmpty ? null : settings.pdfDirectory);
    File? generatedFile;
    try {
      final file = await _pdfService.generateTicket(
        table: table,
        items: snapshot,
        restaurantName: settings.restaurantName,
        subtotal: table.total,
        discount: result.discountAmount,
        tip: result.tipAmount,
        total: result.totalPaid,
        customDirectory: directory,
      );
      generatedFile = file;
      _showSnackBar(
        'Reçu généré: ${file.path.split('/').last}',
        AppColors.secondaryAccent,
      );
    } catch (error) {
      _showSnackBar('Erreur impression: $error', Colors.redAccent);
      return null;
    }
    return generatedFile;
  }

  List<OrderItem> _orderItemsFromSalesLines(List<SalesLine> lines) {
    final catalog = _repository?.menuCatalog ?? {};
    return lines.map((line) {
      final existing = catalog[line.itemId];
      final unitPrice =
          line.quantity == 0 ? 0.0 : (line.total / line.quantity);
      final synthetic = existing ??
          MenuItem(
            id: line.itemId,
            name: line.name,
            price: unitPrice.toDouble(),
            category: 'Reçus',
            emoji: '🧾',
            description: '',
            vatRate: 0,
            availability: MenuAvailability.available,
          );
      return OrderItem(
        menuItem: synthetic,
        quantity: line.quantity,
      );
    }).toList();
  }

  Future<void> _reprintLastReceipt(DiningTable table) async {
    final settings = _settings;
    final lines = table.lastReceiptLines;
    final subtotal = table.lastSubtotal;
    if (settings == null ||
        lines == null ||
        lines.isEmpty ||
        subtotal == null) {
      _showSnackBar('Aucun reçu à réimprimer', AppColors.textMuted);
      return;
    }

    final selectedPath = await getDirectoryPath(
      initialDirectory: table.lastReceiptPath,
      confirmButtonText: 'Réimprimer',
    );
    if (selectedPath == null) {
      return;
    }

    final items = _orderItemsFromSalesLines(lines);
    final discount = table.lastDiscountAmount ?? 0;
    final tip = table.lastTipAmount ?? 0;
    final total = table.lastBillTotal ??
        (subtotal - discount + tip);

    try {
      final file = await _pdfService.generateTicket(
        table: table,
        items: items,
        restaurantName: settings.restaurantName,
        subtotal: subtotal,
        discount: discount,
        tip: tip,
        total: total,
        customDirectory: selectedPath,
      );
      setState(() {
        table.lastReceiptPath = file.path;
      });
      _persistTables();
      _showSnackBar(
        'Reçu réimprimé: ${file.path.split('/').last}',
        AppColors.primaryAccent,
      );
    } catch (error) {
      _showSnackBar('Erreur réimpression: $error', Colors.redAccent);
    }
  }

  Future<void> _saveSettings() async {
    final repository = _repository;
    final settings = _settings;
    if (repository == null || settings == null) return;

    final restaurantName = _restaurantNameController.text.trim();
    final staffPin = _staffPinController.text.trim();
    final managerPin = _managerPinController.text.trim();
    final parsedCount = int.tryParse(_tableCountController.text.trim());
    var desiredTableCount = parsedCount ?? settings.tableCount;
    desiredTableCount = desiredTableCount
        .clamp(_minTableCount, _maxTableCount)
        .toInt();

    if (desiredTableCount != settings.tableCount) {
      final success = await _applyTableCountChange(desiredTableCount);
      if (!success) {
        _tableCountController.text = settings.tableCount.toString();
        return;
      }
    }

    final updated = settings.copyWith(
      restaurantName:
          restaurantName.isEmpty ? settings.restaurantName : restaurantName,
      staffPin: staffPin.isEmpty ? settings.staffPin : staffPin,
      managerPin: managerPin.isEmpty ? settings.managerPin : managerPin,
      users: _userProfiles,
      tableCount: desiredTableCount,
    );

    await repository.updateSettings(updated);
    _authService.updatePins(
      staffPin: updated.staffPin,
      managerPin: updated.managerPin,
    );
    _authService.updateUsers(_userProfiles);
    setState(() {
      _settings = updated;
      _tableCountController.text = updated.tableCount.toString();
      final baseCategories = updated.categories.isEmpty
          ? _defaultMenuCategories
          : updated.categories;
      _categories = _buildCategoryList(baseCategories);
    });
    _showSnackBar('Paramètres enregistrés', AppColors.primaryAccent);
  }

  String _defaultPinForRole(PosRole role) {
    if (role == PosRole.manager) {
      final candidate = _managerPinController.text.trim();
      return candidate.isEmpty ? '7777' : candidate;
    }
    final candidate = _staffPinController.text.trim();
    return candidate.isEmpty ? '1111' : candidate;
  }

  void _addUserProfile() {
    final name = _userNameController.text.trim();
    if (name.isEmpty) return;
    final pin =
        _userPinController.text.trim().isEmpty
            ? _defaultPinForRole(_newUserRole)
            : _userPinController.text.trim();
    setState(() {
      _userProfiles = List<UserProfile>.from(_userProfiles)
        ..add(UserProfile(name: name, role: _newUserRole, pin: pin));
      _userNameController.clear();
      _userPinController.clear();
      _newUserRole = PosRole.staff;
    });
    _authService.updateUsers(_userProfiles);
  }

  void _removeUserProfile(UserProfile profile) {
    setState(() {
      _userProfiles = List<UserProfile>.from(_userProfiles)
        ..removeWhere(
          (user) =>
              user.name == profile.name &&
              user.role == profile.role &&
              user.pin == profile.pin,
        );
    });
    _authService.updateUsers(_userProfiles);
  }

  Future<void> _editUserProfile(UserProfile profile) async {
    final nameController = TextEditingController(text: profile.name);
    final pinController = TextEditingController(text: profile.pin);
    final result = await showDialog<UserProfile>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier ${profile.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newPin = pinController.text.trim();
                if (newName.isEmpty || newPin.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(
                  context,
                  UserProfile(name: newName, role: profile.role, pin: newPin),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    setState(() {
      _userProfiles = _userProfiles
          .map(
            (user) =>
                user.name == profile.name &&
                    user.role == profile.role &&
                    user.pin == profile.pin
                ? result
                : user,
          )
          .toList();
    });
    _authService.updateUsers(_userProfiles);
  }

  void _updatePdfDirectory(String path) {
    final repository = _repository;
    final settings = _settings;
    if (repository == null || settings == null) return;
    final updated = settings.copyWith(pdfDirectory: path);
    setState(() {
      _settings = updated;
    });
    repository.updateSettings(updated);
  }

  String? _lastPaymentLabel(DiningTable table) {
    if (table.lastBillTotal == null ||
        table.lastPaymentMethod == null ||
        table.lastPaidAt == null) {
      return null;
    }
    final relative = _formatRelativeTime(table.lastPaidAt!);
    final total = table.lastBillTotal!.toStringAsFixed(2);
    return '${table.lastPaymentMethod} • $total FCFA • $relative';
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'à l’instant';
    }
    if (diff.inHours < 1) {
      return 'il y a ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'il y a ${diff.inHours} h';
    }
    return 'il y a ${diff.inDays} j';
  }

  void _addItemToOrder(MenuItem item) {
    if (item.availability == MenuAvailability.outOfStock) {
      _showSnackBar('${item.name} est en rupture', AppColors.textMuted);
      return;
    }
    if (_selectedTableNumber == null) {
      _showSnackBar('Veuillez sélectionner une table', AppColors.highlight);
      return;
    }

    setState(() {
      final table = _tables.firstWhere((t) => t.number == _selectedTableNumber);
      final existingItem = table.orders
          .where((o) => o.menuItem.id == item.id)
          .firstOrNull;

      if (existingItem != null) {
        existingItem.quantity++;
      } else {
        table.orders.add(OrderItem(menuItem: item));
      }

      if (!table.isOccupied) {
        table.isOccupied = true;
        table.occupiedSince = DateTime.now();
      }
    });
    _persistTables();

    _showSnackBar(
      '${item.name} ajouté à la table $_selectedTableNumber',
      AppColors.availableStart,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOrderDetails(DiningTable table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsSheet(
        table: table,
        onUpdate: () {
          setState(() {});
          _persistTables();
        },
        onCheckout: (result) {
          _completeCheckout(table, result, dismissSheet: true);
        },
        onSendToProduction: () {
          setState(() {
            _createTicketsForTable(table);
          });
          _persistTables();
          _showSnackBar(
            'Tickets envoyés pour table ${table.number}',
            AppColors.secondaryAccent,
          );
        },
        role: _currentRole,
        restaurantName: _settings?.restaurantName ?? 'Restaurant POS',
        pdfDirectory: _settings?.pdfDirectory ?? '',
        onPdfDirectoryChanged: _updatePdfDirectory,
        onCancelOrder: () => _cancelTableOrder(table),
        onReprintReceipt: _currentRole == PosRole.manager
            ? () => _reprintLastReceipt(table)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLockScreen || _currentRole == null) {
      return LockScreen(
        onSubmitPin: _handlePinSubmit,
        restaurantName: _settings?.restaurantName ?? 'Restaurant POS',
      );
    }

    if (_repository == null) {
      return const Scaffold(
        body: ColoredBox(
          color: AppColors.surfaceLight,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final isWideLayout = MediaQuery.of(context).size.width >= 1000;
    final primaryColumn = _buildPrimaryColumn(isWideLayout);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: isWideLayout
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: primaryColumn),
                    const SizedBox(width: 20),
                    SizedBox(width: 420, child: _buildSidePanel()),
                  ],
                )
              : primaryColumn,
        ),
      ),
    );
  }

  Widget _buildPrimaryColumn(bool isWideLayout) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTablesView(isWideLayout),
                      _buildMenuView(),
                      _currentRole == PosRole.manager
                          ? _buildCatalogView()
                          : _buildLockedCatalogView(),
                      _currentRole == PosRole.manager
                          ? _buildReportsView()
                          : _buildLockedReportsView(),
                      _currentRole == PosRole.manager
                          ? _buildSettingsView()
                          : _buildLockedSettingsView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settings?.restaurantName ?? 'Restaurant POS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedTableNumber != null
                      ? 'Table $_selectedTableNumber sélectionnée'
                      : 'Sélectionnez une table',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_restaurant,
                  color: AppColors.highlight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_tables.where((t) => t.isOccupied).length}/${_tables.length}',
                  style: const TextStyle(
                    color: AppColors.highlight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildProfileChip(),
        ],
      ),
    );
  }

  Widget _buildProfileChip() {
    final roleLabel = _currentRole == PosRole.manager ? 'Manager' : 'Staff';
    return GestureDetector(
      onTap: () {
        setState(() {
          _showLockScreen = true;
          _authService.signOut();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              roleLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    final DiningTable? selectedTable = _selectedTableNumber != null
        ? _tables.firstWhere(
            (table) => table.number == _selectedTableNumber,
            orElse: () => _tables.first,
          )
        : null;

    if (selectedTable == null || selectedTable.number != _selectedTableNumber) {
      return _buildPanelPlaceholder();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
      child: OrderDetailsSheet(
        table: selectedTable,
        onUpdate: () {
          setState(() {});
          _persistTables();
        },
        onCheckout: (result) => _completeCheckout(selectedTable, result),
        onSendToProduction: () {
          setState(() {
            _createTicketsForTable(selectedTable);
          });
          _persistTables();
          _showSnackBar(
            'Tickets envoyés pour table ${selectedTable.number}',
            AppColors.secondaryAccent,
          );
        },
        role: _currentRole,
        restaurantName: _settings?.restaurantName ?? 'Restaurant POS',
        pdfDirectory: _settings?.pdfDirectory ?? '',
        onPdfDirectoryChanged: _updatePdfDirectory,
        onCancelOrder: () => _cancelTableOrder(selectedTable),
        onReprintReceipt: _currentRole == PosRole.manager
            ? () => _reprintLastReceipt(selectedTable)
            : null,
        isModal: false,
      ),
    );
  }

  Widget _buildPanelPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.table_bar_outlined, size: 72, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'Sélectionnez une table',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Choisissez une table pour visualiser la commande, ajouter des notes ou encaisser.',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.table_chart), text: 'Tables'),
          Tab(icon: Icon(Icons.restaurant), text: 'Menu'),
          Tab(icon: Icon(Icons.inventory_2), text: 'Catalogue'),
          Tab(icon: Icon(Icons.bar_chart), text: 'Rapports'),
          Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildTablesView(bool isWideLayout) {
    final filteredTables = _filteredTables();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: _buildSearchField(
            controller: _tableSearchController,
            hintText: 'Rechercher une table ou un article',
            onChanged: _handleTableSearch,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filteredTables.isEmpty
              ? _buildEmptySearchMessage(
                  'Aucune table ne correspond à votre recherche.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1,
                  ),
                  itemCount: filteredTables.length,
                  itemBuilder: (context, index) {
                    final table = filteredTables[index];
                    final isSelected = _selectedTableNumber == table.number;
                    final lastPaymentLabel = _lastPaymentLabel(table);

                    return GestureDetector(
                      onTap: () {
                        if (isWideLayout) {
                          setState(() {
                            _selectedTableNumber =
                                isSelected ? null : table.number;
                          });
                          return;
                        }

                        final hasReprint =
                            table.lastReceiptLines?.isNotEmpty ?? false;
                        if (table.isOccupied || hasReprint) {
                          _showOrderDetails(table);
                        } else {
                          setState(() {
                            _selectedTableNumber =
                                isSelected ? null : table.number;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: table.isOccupied
                                ? const [
                                    AppColors.occupiedStart,
                                    AppColors.occupiedEnd,
                                  ]
                                : isSelected
                                ? const [
                                    AppColors.selectedStart,
                                    AppColors.selectedEnd,
                                  ]
                                : const [
                                    AppColors.availableStart,
                                    AppColors.availableEnd,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (table.isOccupied
                                          ? AppColors.occupiedStart
                                          : AppColors.availableStart)
                                      .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              table.isOccupied
                                  ? Icons.event_seat
                                  : Icons.table_restaurant,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Table ${table.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (table.isOccupied) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${table.orders.length} items',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${table.total.toStringAsFixed(2)} FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else if (lastPaymentLabel != null) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Dernier paiement',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                lastPaymentLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMenuView() {
    final availableItems = _menuItems
        .where(
          (item) => item.availability != MenuAvailability.outOfStock,
        )
        .toList();
    final categoryItems = _selectedCategory == 'Tous'
        ? availableItems
        : availableItems
            .where((item) => item.category == _selectedCategory)
            .toList();
    final displayedItems = _filterMenuItems(categoryItems, _menuSearchQuery);
    final searchActive = _menuSearchQuery.trim().isNotEmpty;

    return Column(
      children: [
        _buildCategoryFilter(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _buildSearchField(
            controller: _menuSearchController,
            hintText: 'Rechercher un article',
            onChanged: _handleMenuSearch,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: displayedItems.isEmpty
              ? (categoryItems.isEmpty && !searchActive
                  ? _buildEmptyMenuPlaceholder()
                  : _buildEmptySearchMessage(
                      'Aucun article ne correspond à votre recherche.',
                    ))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: displayedItems.length,
                  itemBuilder: (context, index) {
                    final item = displayedItems[index];
                    return _buildMenuItem(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyMenuPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'Aucun article disponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Activez des articles depuis l’onglet Catalogue.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          AppColors.primaryAccent,
                          AppColors.secondaryAccent,
                        ],
                      )
                    : null,
                color: isSelected ? null : AppColors.pillDefault,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final isOutOfStock = item.availability == MenuAvailability.outOfStock;
    return GestureDetector(
      onTap: () => _addItemToOrder(item),
      child: Stack(
        children: [
          Opacity(
            opacity: isOutOfStock ? 0.6 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 120,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Builder(
                        builder: (context) {
                          final heroImage = menuItemImageProvider(item);
                          if (heroImage != null) {
                            return Image(
                              image: heroImage,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.menuGradientStart,
                                  AppColors.menuGradientEnd,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(item.emoji, style: const TextStyle(fontSize: 60)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.price.toStringAsFixed(2)} FCFA',
                                    style: const TextStyle(
                                      color: AppColors.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'TVA ${item.vatRate.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryAccent,
                                      AppColors.secondaryAccent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white.withValues(
                                    alpha: isOutOfStock ? 0.4 : 1,
                                  ),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.availability != MenuAvailability.available)
            Positioned(
              top: 8,
              right: 8,
              child: _buildAvailabilityChip(item.availability),
            ),
        ],
      ),
    );
  }

  Widget _buildCatalogView() {
    final filteredItems = _filterMenuItems(_menuItems, _catalogSearchQuery);
    final children = <Widget>[
      _buildCatalogHeader(),
      const SizedBox(height: 12),
      _buildSearchField(
        controller: _catalogSearchController,
        hintText: 'Rechercher dans le catalogue',
        onChanged: _handleCatalogSearch,
      ),
      const SizedBox(height: 16),
    ];
    if (filteredItems.isEmpty) {
      children.add(
        _buildEmptySearchMessage('Aucun article trouvé dans le catalogue.'),
      );
    } else {
      children.addAll(
        filteredItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCatalogCard(item),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: children,
    );
  }

  Widget _buildCatalogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Catalogue',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: _createMenuItem,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un article'),
        ),
      ],
    );
  }

  Widget _buildLockedCatalogView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline, size: 72, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Accès manager requis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Connectez-vous avec un code manager pour modifier le catalogue.',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView() {
    if (_salesRecords.isEmpty) {
      return _buildEmptyReportsPlaceholder();
    }

    final now = DateTime.now();
    final todayRecords = _salesRecords
        .where((record) => _isSameDay(record.timestamp, now))
        .toList();
    final recordsForStats = todayRecords.isEmpty ? _salesRecords : todayRecords;
    final sectionLabel = todayRecords.isEmpty
        ? 'Historique complet'
        : 'Aujourd’hui';

    final totalAmount = recordsForStats.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );
    final totalTips = recordsForStats.fold<double>(
      0,
      (sum, record) => sum + record.tip,
    );
    final ticketCount = recordsForStats.length;
    final averageTicket = ticketCount == 0 ? 0.0 : totalAmount / ticketCount;

    final itemTotals = <String, int>{};
    for (final record in recordsForStats) {
      for (final line in record.lines) {
        itemTotals.update(
          line.name,
          (value) => value + line.quantity,
          ifAbsent: () => line.quantity,
        );
      }
    }

    final topItems = itemTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recentRecords = _salesRecords.reversed.take(6).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rapports · $sectionLabel',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(
                label: 'CA',
                value: _formatCurrency(totalAmount),
                icon: Icons.attach_money,
              ),
              _buildStatCard(
                label: 'Pourboires',
                value: _formatCurrency(totalTips),
                icon: Icons.card_giftcard,
              ),
              _buildStatCard(
                label: 'Tickets',
                value: '$ticketCount',
                icon: Icons.receipt_long,
              ),
              _buildStatCard(
                label: 'Panier moyen',
                value: _formatCurrency(averageTicket),
                icon: Icons.insights,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopItemsCard(topItems)),
                const SizedBox(width: 16),
                Expanded(child: _buildRecentSalesCard(recentRecords)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedReportsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline, size: 72, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Accès manager requis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Connectez-vous avec un code manager pour consulter les rapports.',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReportsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.analytics_outlined, size: 72, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Aucune vente enregistrée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Encaissez une commande pour alimenter ce tableau de bord.',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsCard(List<MapEntry<String, int>> topItems) {
    final displayItems = topItems.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top articles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (displayItems.isEmpty)
            const Text(
              'Aucune vente enregistrée.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: displayItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = displayItems[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${entry.value} vendus'),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesCard(List<SalesRecord> recentRecords) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventes récentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (recentRecords.isEmpty)
            const Text(
              'Aucune vente pour le moment.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: recentRecords.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final record = recentRecords[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Table ${record.tableNumber} · ${_formatCurrency(record.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${record.paymentMethod} · ${_formatTime(record.timestamp)}',
                    ),
                    trailing: record.tip > 0
                        ? Text('+${_formatCurrency(record.tip)}')
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    final settings = _settings;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paramètres généraux',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _restaurantNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du restaurant',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _staffPinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN Staff',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _managerPinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN Manager',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tableCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText:
                  'Nombre de tables ($_minTableCount-$_maxTableCount)',
              border: const OutlineInputBorder(),
              helperText: 'Les tables sont numérotées automatiquement.',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Utilisateurs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _userProfiles
                .map(
                  (profile) => InputChip(
                    label: Text(
                      '${profile.name} (${profile.role == PosRole.manager ? 'Manager' : 'Staff'})',
                    ),
                    avatar: const Icon(Icons.badge, size: 18),
                    onPressed: () => _editUserProfile(profile),
                    onDeleted: () => _removeUserProfile(profile),
                    deleteIcon: const Icon(Icons.close),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom utilisateur',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _userPinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<PosRole>(
                value: _newUserRole,
                items: PosRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          role == PosRole.manager ? 'Manager' : 'Staff',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (role) {
                  if (role == null) return;
                  setState(() => _newUserRole = role);
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addUserProfile,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Catégories du menu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (settings.categories.isEmpty
                    ? _defaultMenuCategories
                    : settings.categories)
                .map(
                  (category) => InputChip(
                    label: Text(category),
                    onDeleted: () => _removeCustomCategory(category),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nouvelle catégorie',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addCustomCategory,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Historique catalogue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _catalogLogs.isEmpty
              ? const Text(
                  'Aucune modification récente.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              : Builder(
                  builder: (context) {
                    final recentLogs =
                        _catalogLogs.reversed.take(10).toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentLogs.length,
                      itemBuilder: (context, index) {
                        final entry = recentLogs[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history),
                          title: Text('${entry.itemName} · ${entry.action}'),
                          subtitle: Text(
                            '${entry.details}\n${_formatLogTimestamp(entry.timestamp)} · ${entry.user}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    );
                  },
                ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedSettingsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline, size: 72, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Paramètres réservés au manager',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Veuillez demander à un manager de se connecter.',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogCard(MenuItem item) {
    final avatarImage = menuItemImageProvider(item);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.pillDefault,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(item.emoji, style: const TextStyle(fontSize: 24))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.availability ==
                                      MenuAvailability.outOfStock
                                  ? AppColors.textMuted
                                  : Colors.black,
                            ),
                          ),
                        ),
                        if (item.availability != MenuAvailability.available)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _availabilityColor(item.availability)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _availabilityLabel(item.availability),
                              style: TextStyle(
                                color: _availabilityColor(item.availability),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      item.category,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.price.toStringAsFixed(2)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'TVA ${item.vatRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  DropdownButton<MenuAvailability>(
                    value: item.availability,
                    underline: Container(),
                    items: MenuAvailability.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_availabilityLabel(status)),
                          ),
                        )
                        .toList(),
                    onChanged: (status) {
                      if (status == null) return;
                      _updateMenuAvailability(item, status);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description.isEmpty ? 'Aucune description' : item.description,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _editMenuItem(item),
                icon: const Icon(Icons.edit),
                label: const Text('Modifier'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Order Details Sheet
class OrderDetailsSheet extends StatefulWidget {
  final DiningTable table;
  final VoidCallback onUpdate;
  final ValueChanged<CheckoutResult> onCheckout;
  final bool isModal;
  final VoidCallback onSendToProduction;
  final PosRole? role;
  final String restaurantName;
  final String pdfDirectory;
  final ValueChanged<String>? onPdfDirectoryChanged;
  final Future<void> Function()? onCancelOrder;
  final Future<void> Function()? onReprintReceipt;

  const OrderDetailsSheet({
    super.key,
    required this.table,
    required this.onUpdate,
    required this.onCheckout,
    required this.onSendToProduction,
    required this.role,
    required this.restaurantName,
    required this.pdfDirectory,
    this.onPdfDirectoryChanged,
    this.isModal = true,
    this.onCancelOrder,
    this.onReprintReceipt,
  });

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  final List<String> _paymentMethods = ['Carte', 'Espèces', 'Autre'];
  late String _selectedPaymentMethod;
  late TextEditingController _tipController;
  late TextEditingController _discountController;
  late TextEditingController _paymentAmountController;
  double _tipAmount = 0;
  bool _usePercentageDiscount = false;
  final PdfService _pdfService = PdfService();
  final List<PaymentFragment> _payments = [];

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = _paymentMethods.first;
    _tipController = TextEditingController();
    _discountController = TextEditingController();
    _paymentAmountController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant OrderDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReset = widget.table.number != oldWidget.table.number ||
        (widget.table.orders.isEmpty && _payments.isNotEmpty);
    if (shouldReset) {
      setState(() {
        _payments.clear();
        _paymentAmountController.clear();
      });
    }
  }

  @override
  void dispose() {
    _tipController.dispose();
    _discountController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  Future<void> _confirmCancelOrder() async {
    final cancelCallback = widget.onCancelOrder;
    if (cancelCallback == null || widget.table.orders.isEmpty) {
      return;
    }
    final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Annuler la commande de la table ${widget.table.number}?'),
            content: Text(
              'Les ${widget.table.orders.length} article(s) seront supprimés et la table sera libérée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Conserver'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.occupiedStart,
                ),
                child: const Text('Annuler', style  : TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldCancel) return;
    await cancelCallback();
    if (widget.isModal && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _onTipChanged(String value) {
    setState(() {
      _tipAmount = double.tryParse(value.replaceAll(',', '.')) ?? 0;
      if (_tipAmount < 0) {
        _tipAmount = 0;
      }
    });
  }

  void _onDiscountChanged(String value) {
    setState(() {});
  }

  double get _discountAmount {
    final base = widget.table.total;
    final raw =
        double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0;
    if (_usePercentageDiscount) {
      final percentage = raw.clamp(0, 100);
      return (base * percentage / 100).clamp(0, base);
    }
    return raw.clamp(0, base);
  }

  double get _netSubtotal =>
      (widget.table.total - _discountAmount).clamp(0, double.infinity);

  double get _grandTotal => _netSubtotal + _tipAmount;

  double get _paymentsTotal =>
      _payments.fold(0, (sum, fragment) => sum + fragment.amount);

  double get _remainingAmount =>
      (_grandTotal - _paymentsTotal).clamp(0, double.infinity);

  Future<void> _editOrderNotes(OrderItem order) async {
    final controller = TextEditingController(text: order.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Note de préparation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Sauce à part, cuisson, allergie...',
            ),
            autofocus: true,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      order.notes = result.isEmpty ? null : result;
    });
    widget.onUpdate();
  }

  Widget _buildPaymentComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _paymentAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant (${_remainingAmount.toStringAsFixed(0)} FCFA restants)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selectedPaymentMethod,
              items: _paymentMethods
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedPaymentMethod = value);
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addPaymentFragment,
              child: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_payments.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paiements enregistrés',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._payments.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final payment = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(payment.method),
                    subtitle: Text('${payment.amount.toStringAsFixed(2)} FCFA'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removePaymentFragment(index),
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  void _addPaymentFragment() {
    final amountText = _paymentAmountController.text.trim();
    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showInlineSnack('Montant invalide');
      return;
    }
    if (amount > _remainingAmount) {
      _showInlineSnack('Montant supérieur au restant');
      return;
    }
    setState(() {
      _payments.add(
        PaymentFragment(method: _selectedPaymentMethod, amount: amount),
      );
      _paymentAmountController.clear();
    });
  }

  void _removePaymentFragment(int index) {
    setState(() {
      _payments.removeAt(index);
    });
  }

  void _showInlineSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.occupiedStart,
      ),
    );
  }

  Future<void> _confirmCheckout() async {
    if (widget.table.orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez des articles avant d’encaisser.'),
          backgroundColor: AppColors.textMuted,
        ),
      );
      return;
    }
    if (_payments.isNotEmpty && _remainingAmount > 0.01) {
      _showInlineSnack('Complétez les paiements avant d’encaisser');
      return;
    }

    final effectivePayments = _payments.isEmpty
        ? [
            PaymentFragment(
              method: _selectedPaymentMethod,
              amount: _grandTotal,
            ),
          ]
        : List<PaymentFragment>.from(_payments);
    final paymentLabel = effectivePayments.length == 1
        ? effectivePayments.first.method
        : 'Paiements multiples';

    var shouldSaveReceipt = true;
    final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Confirmer l’encaissement'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encaisser ${_grandTotal.toStringAsFixed(2)} FCFA '
                      'via $paymentLabel ?',
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: shouldSaveReceipt,
                      onChanged: (value) {
                        setStateDialog(() {
                          shouldSaveReceipt = value ?? true;
                        });
                      },
                      title: const Text('Sauvegarder le reçu PDF'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirmer'),
                  ),
                ],
              );
            },
          ),
        ) ??
        false;
    if (!shouldProceed) return;
    String? receiptDirectory;
    if (shouldSaveReceipt) {
      final selectedPath = await _promptPdfDirectory();
      if (!mounted || selectedPath == null) {
        return;
      }
      receiptDirectory = selectedPath;
    }

    widget.onCheckout(
      CheckoutResult(
        paymentMethod: paymentLabel,
        tipAmount: _tipAmount,
        subtotal: widget.table.total,
        discountAmount: _discountAmount,
        totalPaid: _grandTotal,
        paidAt: DateTime.now(),
        saveReceipt: shouldSaveReceipt,
        receiptDirectory: receiptDirectory,
        payments: effectivePayments,
      ),
    );
  }

  Future<void> _exportTicket() async {
    final selectedPath = await _promptPdfDirectory();
    if (!mounted || selectedPath == null) return;
    try {
      final file = await _pdfService.generateTicket(
        table: widget.table,
        items: widget.table.orders,
        restaurantName: widget.restaurantName,
        subtotal: widget.table.total,
        discount: _discountAmount,
        tip: _tipAmount,
        total: _grandTotal,
        customDirectory: selectedPath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket exporté: ${file.path}'),
          backgroundColor: AppColors.primaryAccent,
        ),
      );
      // ignore: avoid_print
      print('Export PDF réussi: ${file.path}');
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Erreur export PDF: $e');
      print(stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<String?> _promptPdfDirectory() async {
    final result = await getDirectoryPath(
      initialDirectory: widget.pdfDirectory.isEmpty
          ? null
          : widget.pdfDirectory,
      confirmButtonText: 'Valider',
    );
    if (result != null && result.isNotEmpty) {
      widget.onPdfDirectoryChanged?.call(result);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isModal
        ? const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          )
        : BorderRadius.circular(24);

    final panel = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: widget.isModal
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          if (widget.isModal)
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.pillDefault,
                borderRadius: BorderRadius.circular(10),
              ),
            )
          else
            const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryAccent,
                        AppColors.secondaryAccent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table ${widget.table.number}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.table.orders.length} articles',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (widget.isModal)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          Expanded(
            child: widget.table.orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: AppColors.pillDefault,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Aucune commande',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.onReprintReceipt != null &&
                            (widget.table.lastReceiptLines?.isNotEmpty ??
                                false)) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => widget.onReprintReceipt?.call(),
                            icon: const Icon(Icons.print),
                            label: const Text('Réimprimer le dernier reçu'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (int i = 0; i < widget.table.orders.length; i++)
                        _buildOrderItem(widget.table.orders[i], i),
                      const SizedBox(height: 12),
                      _buildCheckoutSection(),
                      if (widget.role == PosRole.manager) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onSendToProduction,
                            icon: const Icon(Icons.local_printshop_outlined),
                            label: const Text('Envoyer en préparation'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _exportTicket,
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Exporter en PDF'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.onReprintReceipt != null &&
                            (widget.table.lastReceiptLines?.isNotEmpty ??
                                false))
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => widget.onReprintReceipt?.call(),
                              icon: const Icon(Icons.print),
                              label: const Text('Réimprimer le dernier reçu'),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (widget.onCancelOrder != null &&
                            widget.table.orders.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _confirmCancelOrder,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.occupiedStart,
                                side: const BorderSide(
                                  color: AppColors.occupiedStart,
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Annuler la commande'),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );

    if (widget.isModal) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: panel,
      );
    }

    return panel;
  }

  Widget _buildOrderItem(OrderItem order, int index) {
    final itemImage = menuItemImageProvider(order.menuItem);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: itemImage == null
                  ? const LinearGradient(
                      colors: [
                        AppColors.menuGradientStart,
                        AppColors.menuGradientEnd,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              color: itemImage != null ? AppColors.pillDefault : null,
            ),
            child: itemImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: itemImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      order.menuItem.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.menuItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${order.menuItem.price.toStringAsFixed(2)} FCFA',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                if ((order.notes ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Note: ${order.notes}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _editOrderNotes(order),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: Text(
                      (order.notes ?? '').isNotEmpty
                          ? 'Modifier la note'
                          : 'Ajouter une note',
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (order.quantity > 1) {
                      order.quantity--;
                    } else {
                      widget.table.orders.removeAt(index);
                    }
                    widget.onUpdate();
                  });
                },
                icon: const Icon(
                  Icons.remove_circle,
                  color: AppColors.occupiedStart,
                ),
              ),
              Text(
                '${order.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    order.quantity++;
                    widget.onUpdate();
                  });
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.availableEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryAccent.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sous-total brut',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${widget.table.total.toStringAsFixed(2)} FCFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remise'),
                Text(
                  '-${_discountAmount.toStringAsFixed(2)} FCFA',
                  style: const TextStyle(color: AppColors.occupiedStart),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sous-total net',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${_netSubtotal.toStringAsFixed(2)} FCFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Mode de paiement',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _paymentMethods.map((method) {
              final selected = method == _selectedPaymentMethod;
              return ChoiceChip(
                label: Text(method),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedPaymentMethod = method);
                },
                selectedColor: AppColors.primaryAccent,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.pillDefault,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pourboire (optionnel)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _tipController,
            onChanged: _onTipChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: const InputDecoration(
              prefixText: 'FCFA ',
              hintText: '0',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Utiliser un pourcentage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _usePercentageDiscount,
                onChanged: (value) {
                  setState(() {
                    _usePercentageDiscount = value;
                  });
                },
              ),
            ],
          ),
          TextField(
            controller: _discountController,
            onChanged: _onDiscountChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: InputDecoration(
              labelText: _usePercentageDiscount
                  ? 'Remise (%)'
                  : 'Remise (FCFA)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentComposer(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total à encaisser',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_grandTotal.toStringAsFixed(2)} FCFA',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _confirmCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryAccent,
                      AppColors.secondaryAccent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Encaisser',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItemEditorDialog extends StatefulWidget {
  const MenuItemEditorDialog({
    super.key,
    this.existing,
    required this.onPickImage,
    required this.idFactory,
  });

  final MenuItem? existing;
  final Future<String?> Function() onPickImage;
  final String Function() idFactory;

  @override
  State<MenuItemEditorDialog> createState() => _MenuItemEditorDialogState();
}

class _MenuItemEditorDialogState extends State<MenuItemEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _emojiController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _vatController;
  final _formKey = GlobalKey<FormState>();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '',
    );
    _categoryController = TextEditingController(text: item?.category ?? 'Plats');
    _emojiController = TextEditingController(text: item?.emoji ?? '🍽️');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _vatController = TextEditingController(
      text: (item?.vatRate ?? 0).toString(),
    );
    _imagePath = item?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _emojiController.dispose();
    _descriptionController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    final picked = await widget.onPickImage();
    if (picked != null) {
      setState(() => _imagePath = picked);
    }
  }

  void _handleRemoveImage() {
    setState(() => _imagePath = null);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final parsedPrice = double.parse(
      _priceController.text.replaceAll(',', '.'),
    );
    final normalizedCategory = _categoryController.text.trim().isEmpty
        ? 'Divers'
        : _categoryController.text.trim();
    final emojiValue = _emojiController.text.trim().isEmpty
        ? (widget.existing?.emoji ?? '🍽️')
        : _emojiController.text.trim();
    final vatValue =
        double.tryParse(_vatController.text.replaceAll(',', '.')) ??
            (widget.existing?.vatRate ?? 0);
    final clampedVat = vatValue.clamp(0, 100).toDouble();

    final result = widget.existing?.copyWith(
          name: _nameController.text.trim(),
          price: parsedPrice,
          category: normalizedCategory,
          emoji: emojiValue,
          description: _descriptionController.text.trim(),
          imagePath: _imagePath,
          vatRate: clampedVat,
        ) ??
        MenuItem(
          id: widget.idFactory(),
          name: _nameController.text.trim(),
          price: parsedPrice,
          category: normalizedCategory,
          emoji: emojiValue,
          description: _descriptionController.text.trim(),
          imagePath: _imagePath,
          vatRate: clampedVat,
          availability: widget.existing?.availability ?? MenuAvailability.available,
        );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = _imagePath != null ? File(_imagePath!) : null;
    final hasPreview = imageFile?.existsSync() ?? false;
    final title = widget.existing == null
        ? 'Nouvel article'
        : 'Modifier ${widget.existing!.name}';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.pillDefault,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: hasPreview
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              _emojiController.text.isEmpty
                                  ? '🍽️'
                                  : _emojiController.text,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _handlePickImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _imagePath == null
                                ? 'Choisir une image'
                                : 'Changer l’image',
                          ),
                        ),
                        if (_imagePath != null)
                          TextButton(
                            onPressed: _handleRemoveImage,
                            child: const Text('Supprimer l’image'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Prix (FCFA)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    value?.replaceAll(',', '.') ?? '',
                  );
                  if (parsed == null || parsed <= 0) {
                    return 'Entrez un prix valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'TVA (%)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
