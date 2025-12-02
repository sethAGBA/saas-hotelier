import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

const AppSettings _defaultSettings = AppSettings(
  restaurantName: 'Restaurant POS',
  staffPin: '1111',
  managerPin: '7777',
  pdfDirectory: '',
  users: [
    UserProfile(name: 'Serveur', role: PosRole.staff, pin: '1111'),
    UserProfile(name: 'Manager', role: PosRole.manager, pin: '7777'),
  ],
  tableCount: 12,
  categories: ['Entrées', 'Plats', 'Desserts', 'Boissons'],
);

class PosRepository {
  PosRepository._({
    required List<DiningTable> tables,
    required List<MenuItem> menuItems,
    required AppSettings settings,
    required List<SalesRecord> sales,
    required List<CatalogLogEntry> catalogLogs,
    required File storageFile,
  })  : _tables = tables,
        _menuItems = menuItems,
        _settings = settings,
        _salesRecords = sales,
        _catalogLogs = catalogLogs,
        _storageFile = storageFile;

  final List<DiningTable> _tables;
  final List<MenuItem> _menuItems;
  AppSettings _settings;
  final List<SalesRecord> _salesRecords;
  final List<CatalogLogEntry> _catalogLogs;
  final File _storageFile;
  Future<void> _writeQueue = Future<void>.value();

  List<DiningTable> get tables => _tables;

  List<MenuItem> get menuItems {
    final items = List<MenuItem>.from(_menuItems);
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Map<String, MenuItem> get menuCatalog => {
    for (final item in _menuItems) item.id: item,
  };

  List<SalesRecord> get salesRecords => List.unmodifiable(_salesRecords);
  List<CatalogLogEntry> get catalogLogs => List.unmodifiable(_catalogLogs);
  AppSettings get settings => _settings;

  static Future<PosRepository> initialize({
    List<MenuItem> initialMenu = seedMenuItems,
    int tableCount = 12,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pos_state.json');
    final backupFile = File('${file.path}.bak');

    Future<PosRepository> createSeedRepository() async {
      final seededMenu = List<MenuItem>.from(initialMenu);
      final seedTables = buildSeedTables(count: tableCount);
      final seedSettings = _defaultSettings.copyWith(tableCount: tableCount);
      final payload = {
        'tables': seedTables.map((t) => t.toJson()).toList(),
        'menu': seededMenu.map((item) => item.toJson()).toList(),
        'sales': <dynamic>[],
        'settings': seedSettings.toJson(),
        'catalogLogs': <dynamic>[],
      };
      await file.writeAsString(jsonEncode(payload), flush: true);
      return PosRepository._(
        tables: seedTables,
        menuItems: seededMenu,
        settings: seedSettings,
        sales: const [],
        catalogLogs: const [],
        storageFile: file,
      );
    }

    Future<Map<String, dynamic>?> decodeFile(File target) async {
      if (!await target.exists()) return null;
      try {
        final raw = await target.readAsString();
        if (raw.trim().isEmpty) {
          return null;
        }
        return jsonDecode(raw) as Map<String, dynamic>;
      } on FormatException {
        return null;
      }
    }

    if (!await file.exists()) {
      if (await backupFile.exists()) {
        await backupFile.rename(file.path);
      } else {
        return createSeedRepository();
      }
    }

    Map<String, dynamic>? decoded = await decodeFile(file);
    if (decoded == null) {
      decoded = await decodeFile(backupFile);
      if (decoded != null) {
        await file.writeAsString(jsonEncode(decoded), flush: true);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      } else {
        if (await file.exists()) {
          final backup = File(
            '${file.path}_backup_${DateTime.now().millisecondsSinceEpoch}',
          );
          await file.rename(backup.path);
        }
        return createSeedRepository();
      }
    }

    final state = decoded!;

    List<MenuItem> storedMenu;
    if (state['menu'] != null) {
      storedMenu = (state['menu'] as List<dynamic>)
          .map(
            (entry) =>
                MenuItem.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList();
    } else {
      storedMenu = List<MenuItem>.from(initialMenu);
      state['menu'] = storedMenu.map((item) => item.toJson()).toList();
      await file.writeAsString(jsonEncode(state), flush: true);
    }

    final catalog = {for (final item in storedMenu) item.id: item};

    final tables = (state['tables'] as List<dynamic>? ?? [])
        .map(
          (tableJson) => DiningTable.fromJson(
            Map<String, dynamic>.from(tableJson as Map),
            catalog,
          ),
        )
        .toList();

    final sales = (state['sales'] as List<dynamic>? ?? [])
        .map(
          (entry) =>
              SalesRecord.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
    final catalogLogs = (state['catalogLogs'] as List<dynamic>? ?? [])
        .map(
          (entry) => CatalogLogEntry.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
    var settings = state['settings'] != null
        ? AppSettings.fromJson(
            Map<String, dynamic>.from(state['settings'] as Map),
          )
        : _defaultSettings;
    if (settings.categories.isEmpty) {
      settings = settings.copyWith(categories: _defaultSettings.categories);
      decoded['settings'] = settings.toJson();
      await file.writeAsString(jsonEncode(decoded), flush: true);
    }

    if (tables.isEmpty) {
      final fallbackCount =
          settings.tableCount > 0 ? settings.tableCount : tableCount;
      tables.addAll(buildSeedTables(count: fallbackCount));
    }

    final normalizedTables = _buildTablesForCount(
      tables,
      settings.tableCount,
      preserveOverflow: true,
    );
    final tablesChanged = _tablesChanged(tables, normalizedTables);
    final shouldUpdateSettings =
        normalizedTables.length != settings.tableCount;
    if (shouldUpdateSettings) {
      settings = settings.copyWith(tableCount: normalizedTables.length);
    }

    final repository = PosRepository._(
      tables: normalizedTables,
      menuItems: storedMenu,
      settings: settings,
      sales: sales,
      catalogLogs: catalogLogs,
      storageFile: file,
    );

    if (tablesChanged || shouldUpdateSettings) {
      await repository._writeState();
    }

    return repository;
  }

  Future<void> saveTables() async {
    await _writeState();
  }

  DiningTable getTable(int tableNumber) {
    return _tables.firstWhere((table) => table.number == tableNumber);
  }

  Future<void> replaceTable(DiningTable updated) async {
    final index = _tables.indexWhere((table) => table.number == updated.number);
    if (index == -1) {
      _tables.add(updated);
    } else {
      _tables[index] = updated;
    }
    await saveTables();
  }

  Future<void> resetAllTables() async {
    _tables
      ..clear()
      ..addAll(buildSeedTables(count: _tables.length));
    await saveTables();
  }

  Future<void> updateMenuItem(MenuItem updated) async {
    final index = _menuItems.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      _menuItems.add(updated);
    } else {
      _menuItems[index] = updated;
    }
    await _writeState();
  }

  Future<void> appendSale(SalesRecord record) async {
    _salesRecords.add(record);
    await _writeState();
  }

  Future<void> appendCatalogLog(CatalogLogEntry entry) async {
    _catalogLogs.add(entry);
    await _writeState();
  }

  Future<void> updateSettings(AppSettings updated) async {
    _settings = updated;
    await _writeState();
  }

  Future<void> setTableCount(int newCount) async {
    final updatedTables = _buildTablesForCount(
      _tables,
      newCount,
      preserveOverflow: false,
    );
    _tables
      ..clear()
      ..addAll(updatedTables);
    _settings = _settings.copyWith(tableCount: updatedTables.length);
    await _writeState();
  }

  Future<void> _scheduleWrite(Future<void> Function() writer) {
    final next = _writeQueue.then((_) => writer());
    _writeQueue = next.catchError((error, stackTrace) {
      stderr.writeln('Failed to write POS state: $error');
      stderr.writeln(stackTrace);
    });
    return next;
  }

  Future<void> _writeState() {
    final payload = {
      'tables': _tables.map((t) => t.toJson()).toList(),
      'menu': _menuItems.map((item) => item.toJson()).toList(),
      'settings': _settings.toJson(),
      'sales': _salesRecords.map((sale) => sale.toJson()).toList(),
      'catalogLogs': _catalogLogs.map((log) => log.toJson()).toList(),
    };
    return _scheduleWrite(() async {
      final encoded = jsonEncode(payload);
      final tempFile = File('${_storageFile.path}.tmp');
      await tempFile.writeAsString(encoded, flush: true);

      final backupFile = File('${_storageFile.path}.bak');
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      if (await _storageFile.exists()) {
        await _storageFile.rename(backupFile.path);
      }

      try {
        try {
          await tempFile.rename(_storageFile.path);
        } on FileSystemException {
          if (await _storageFile.exists()) {
            await _storageFile.delete();
          }
          await tempFile.rename(_storageFile.path);
        }
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });
  }

  static List<DiningTable> _buildTablesForCount(
    List<DiningTable> existing,
    int desiredCount, {
    required bool preserveOverflow,
  }) {
    final sanitized = desiredCount < 1 ? 1 : desiredCount;
    final existingByNumber = <int, DiningTable>{
      for (final table in existing) table.number: table,
    };
    var finalCount = sanitized;
    if (preserveOverflow && existingByNumber.isNotEmpty) {
      var maxNumber = 0;
      for (final key in existingByNumber.keys) {
        if (key > maxNumber) {
          maxNumber = key;
        }
      }
      if (maxNumber > finalCount) {
        finalCount = maxNumber;
      }
    }
    return List<DiningTable>.generate(
      finalCount,
      (index) {
        final number = index + 1;
        return existingByNumber[number] ?? DiningTable(number: number);
      },
    );
  }

  static bool _tablesChanged(
    List<DiningTable> original,
    List<DiningTable> normalized,
  ) {
    if (original.length != normalized.length) {
      return true;
    }
    for (var i = 0; i < original.length; i++) {
      if (original[i].number != normalized[i].number) {
        return true;
      }
    }
    return false;
  }
}
