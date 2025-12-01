import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/document_template.dart';
import '../models/entity_info.dart';
import '../models/user.dart';

/// Provides a singleton access point to the local SQLite database.
class LocalDatabase {
  LocalDatabase._internal();

  static final LocalDatabase instance = LocalDatabase._internal();

  static const _roomsTable = 'rooms';
  static const _reservationsTable = 'reservations';
  static const _roomTypesTable = 'room_types';
  static const _roomCategoriesTable = 'room_categories';
  static const _roomEquipmentsTable = 'room_equipments';
  static const _servicesTable = 'services';
  static const _clientsTable = 'clients';
  static const _expensesTable = 'expenses';
  static const _usersTable = 'users';
  static const _entityTable = 'entity_info';
  static const _templatesTable = 'document_templates';
  static const _ecritureTemplatesTable = 'ecriture_templates';
  static const _planComptableTable = 'plan_comptable';
  static const _ecrituresTable = 'ecritures_comptables';
  static const _journauxTable = 'journaux';
  static const _maintenanceTable = 'maintenance_tickets';
  static const _inventoryTable = 'inventory_items';
  static const _serviceOrdersTable = 'service_orders';
  static const _dbVersion = 22;
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<String> _dbPath() async {
    final Directory supportDir = await getApplicationSupportDirectory();
    return p.join(supportDir.path, 'roommaster.db');
  }

  /// Initializes the appropriate database factory (mobile vs desktop) and opens
  /// the application database. Call once from `main` before runApp.
  Future<void> init() async {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _dbPath();

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createRoomsTable(db);
        await _createReferenceTables(db);
        await _createServicesTable(db);
        await _createReservationsTable(db);
        await _createClientsTable(db);
        await _createExpensesTable(db);
        await _createUsersTable(db);
        await _seedUsers(db);
        await _createEntityTable(db);
        await _seedEntity(db);
        await _createTemplatesTable(db);
        await _seedTemplates(db);
        await _createEcritureTemplatesTable(db);
        await _seedEcritureTemplates(db);
        await _createPlanComptableTable(db);
        await _createEcrituresTable(db);
        await _createJournauxTable(db);
        await _createMaintenanceTable(db);
        await _createInventoryTable(db);
        await _createServiceOrdersTable(db);
        await _seedCompta(db);
        await _ensureMaintenanceSeed(db);
        await _seedRooms(db);
        await _seedReferenceTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_roomsTable ADD COLUMN category TEXT');
          await db.execute(
            'ALTER TABLE $_roomsTable ADD COLUMN capacity INTEGER DEFAULT 1',
          );
          await db.execute('ALTER TABLE $_roomsTable ADD COLUMN bedType TEXT');
          await db.execute(
            'ALTER TABLE $_roomsTable ADD COLUMN equipments TEXT',
          );
          await db.execute('ALTER TABLE $_roomsTable ADD COLUMN view TEXT');
          await db.execute('ALTER TABLE $_roomsTable ADD COLUMN photoUrl TEXT');
          await db.execute(
            'ALTER TABLE $_roomsTable ADD COLUMN smoking INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_roomsTable ADD COLUMN accessible INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await _createReferenceTables(db);
          await _seedReferenceTables(db);
        }
        if (oldVersion < 8) {
          await _createServicesTable(db);
        }
        if (oldVersion < 4) {
          await _createReservationsTable(db);
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN dateOfBirth TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN placeOfBirth TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN nationality TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN profession TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN domicile TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN travelReason TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN comingFrom TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN goingTo TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN lodgingType TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN idNumber TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN idIssuedOn TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN idIssuedAt TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN visaNumber TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN visaIssuedOn TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN visaIssuedAt TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN emergencyAddress TEXT',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN roomType TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN bedType TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN adults INTEGER DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN children INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN reservationSource TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN paymentStatus TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN breakfastIncluded INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN parkingIncluded INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN wifiIncluded INTEGER DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN checkInTime TEXT',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN checkOutTime TEXT',
          );
        }
        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN services TEXT',
          );
        }
        if (oldVersion < 8) {
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN cancellationReason TEXT',
          );
        }
        if (oldVersion < 9) {
          try {
            await db.execute(
              'ALTER TABLE $_reservationsTable ADD COLUMN cancellationReason TEXT',
            );
          } catch (_) {
            // ignore if already exists
          }
        }
        if (oldVersion < 10) {
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN deposit REAL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_reservationsTable ADD COLUMN paymentMethod TEXT',
          );
        }
        if (oldVersion < 11) {
          await _createClientsTable(db);
          await _createExpensesTable(db);
        }
        if (oldVersion < 12) {
          await _addClientColumnsForV12(db);
        }
        if (oldVersion < 13) {
          await _createUsersTable(db);
          await _seedUsers(db);
        }
        if (oldVersion < 14) {
          await _createEntityTable(db);
          await _seedEntity(db);
        }
        if (oldVersion < 15) {
          await db.execute(
            'ALTER TABLE $_entityTable ADD COLUMN logoPath TEXT',
          );
        }
        if (oldVersion < 16) {
          try {
            await db.execute(
              'ALTER TABLE $_usersTable ADD COLUMN is2faEnabled INTEGER DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE $_usersTable ADD COLUMN twoFaSecret TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 17) {
          await _createTemplatesTable(db);
          await _seedTemplates(db);
        }
        if (oldVersion < 18) {
          await _createPlanComptableTable(db);
          await _createEcrituresTable(db);
          await _createJournauxTable(db);
          await _seedCompta(db);
        }
        if (oldVersion < 19) {
          await _createEcritureTemplatesTable(db);
          await _seedEcritureTemplates(db);
        }
        if (oldVersion < 21) {
          await _createMaintenanceTable(db);
          await _createInventoryTable(db);
          await _ensureMaintenanceSeed(db);
        }
        if (oldVersion < 22) {
          await _createServiceOrdersTable(db);
        }
      },
    );
  }

  Future<void> _createRoomsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_roomsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        rate REAL NOT NULL DEFAULT 0,
        notes TEXT,
        category TEXT,
        capacity INTEGER DEFAULT 1,
        bedType TEXT,
        equipments TEXT,
        view TEXT,
        photoUrl TEXT,
        smoking INTEGER DEFAULT 0,
        accessible INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createReferenceTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_roomTypesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_roomCategoriesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_roomEquipmentsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<void> _createServicesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_servicesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<void> _createReservationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_reservationsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guestName TEXT NOT NULL,
        guestEmail TEXT,
        guestPhone TEXT,
        dateOfBirth TEXT,
        placeOfBirth TEXT,
        nationality TEXT,
        profession TEXT,
        domicile TEXT,
        travelReason TEXT,
        comingFrom TEXT,
        goingTo TEXT,
        lodgingType TEXT,
        roomType TEXT,
        bedType TEXT,
        adults INTEGER DEFAULT 1,
        children INTEGER DEFAULT 0,
        reservationSource TEXT,
        paymentStatus TEXT,
        breakfastIncluded INTEGER DEFAULT 0,
        parkingIncluded INTEGER DEFAULT 0,
        wifiIncluded INTEGER DEFAULT 1,
        services TEXT,
        idNumber TEXT,
        idIssuedOn TEXT,
        idIssuedAt TEXT,
        visaNumber TEXT,
        visaIssuedOn TEXT,
        visaIssuedAt TEXT,
        emergencyAddress TEXT,
        checkInTime TEXT,
        checkOutTime TEXT,
        cancellationReason TEXT,
        roomNumber TEXT NOT NULL,
        checkIn TEXT NOT NULL,
        checkOut TEXT NOT NULL,
        status TEXT NOT NULL,
        amount REAL DEFAULT 0,
        deposit REAL DEFAULT 0,
        paymentMethod TEXT,
        notes TEXT
      )
    ''');
  }

  Future<void> _createClientsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_clientsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        lastName TEXT,
        email TEXT,
        phone TEXT,
        createdAt TEXT,
        firstName TEXT,
        phone2 TEXT,
        dateOfBirth TEXT,
        profession TEXT,
        placeOfBirth TEXT,
        domicile TEXT,
        maritalStatus TEXT,
        nationality TEXT,
        nationalityOther TEXT,
        address TEXT,
        city TEXT,
        postalCode TEXT,
        country TEXT,
        idNumber TEXT,
        idPlace TEXT,
        idIssuedOn TEXT,
        idExpiresOn TEXT,
        passportNumber TEXT,
        passportPlace TEXT,
        passportIssuedOn TEXT,
        passportExpiresOn TEXT,
        visaNumber TEXT,
        visaPlace TEXT,
        visaIssuedOn TEXT,
        visaExpiresOn TEXT,
        emergencyName TEXT,
        emergencyPhone TEXT,
        emergencyRelation TEXT,
        emergencyAddress TEXT,
        clientType TEXT,
        reservationSource TEXT,
        vip INTEGER DEFAULT 0,
        fidelityStatus TEXT,
        fidelityPoints INTEGER,
        fidelitySince TEXT,
        roomPreferences TEXT,
        allergies TEXT,
        diet TEXT,
        otherPreferences TEXT,
        bedType TEXT,
        floorPreference TEXT,
        smoker INTEGER DEFAULT 0,
        pets INTEGER DEFAULT 0,
        feedback TEXT,
        provenance TEXT,
        destination TEXT,
        travelReason TEXT,
        company TEXT,
        jobTitle TEXT,
        vatNumber TEXT,
        companyBilling INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_expensesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        amount REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createEntityTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_entityTable(
        id INTEGER PRIMARY KEY,
        name TEXT,
        type TEXT,
        address TEXT,
        contacts TEXT,
        website TEXT,
        rccm TEXT,
        nif TEXT,
        currency TEXT,
        exercice TEXT,
        plan TEXT,
        legalResponsible TEXT,
        targetRevenue TEXT,
        capacity TEXT,
        timezone TEXT,
        logoPath TEXT
      )
    ''');
  }

  Future<void> _createTemplatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_templatesTable(
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        content TEXT,
        lastModified INTEGER
      )
    ''');
  }

  Future<void> _createEcritureTemplatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_ecritureTemplatesTable(
        id TEXT PRIMARY KEY,
        label TEXT,
        journalId TEXT,
        content TEXT
      )
    ''');
  }

  Future<void> _createPlanComptableTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_planComptableTable(
        id TEXT PRIMARY KEY,
        code TEXT,
        title TEXT,
        parentId TEXT,
        isArchived INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createEcrituresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_ecrituresTable(
        id TEXT PRIMARY KEY,
        date TEXT,
        label TEXT,
        journalId TEXT,
        accountCode TEXT,
        debit REAL,
        credit REAL,
        piece TEXT
      )
    ''');
  }

  Future<void> _createJournauxTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_journauxTable(
        id TEXT PRIMARY KEY,
        code TEXT,
        name TEXT,
        description TEXT,
        type TEXT
      )
    ''');
  }

  Future<void> _createMaintenanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_maintenanceTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room TEXT,
        title TEXT,
        status TEXT,
        priority TEXT,
        assigned TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _createInventoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_inventoryTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT,
        stock INTEGER,
        threshold INTEGER
      )
    ''');
  }

  Future<void> _createServiceOrdersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_serviceOrdersTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serviceType TEXT, -- restaurant | bar | room_service
        item TEXT,
        room TEXT,
        status TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _seedEntity(Database db) async {
    final rows = await db.query(_entityTable, limit: 1);
    if (rows.isNotEmpty) return;
    final defaultEntity = EntityInfo(
      name: 'Roommaster Resort',
      type: 'Hôtellerie • 4 étoiles',
      address: '123 Avenue de la Plage, Douala',
      contacts: 'Tel: +237 699 00 00 00 • contact@roommaster.app',
      website: 'www.roommaster.app',
      rccm: 'RC/DLA/2024/B12345',
      nif: '0000000000123',
      currency: 'FCFA',
      exercice: '01/01/2024 - 31/12/2024',
      plan: 'SYSCOHADA',
      legalResponsible: 'Mme. Aissatou Ngassa',
      targetRevenue: '1 200 000 000',
      capacity: '120 chambres dont 8 suites',
      timezone: 'GMT+1 (Afrique centrale)',
      logoPath: '',
    );
    await db.insert(_entityTable, defaultEntity.toMap());
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_usersTable(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
      createdAt INTEGER NOT NULL,
      lastLogin INTEGER NOT NULL,
      isActive INTEGER DEFAULT 1,
      is2faEnabled INTEGER DEFAULT 0,
      twoFaSecret TEXT
    )
  ''');
  }

  Future<void> _seedUsers(Database db) async {
    final existing = await db.query(_usersTable, limit: 1);
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final admin = User(
      id: 'admin',
      name: 'Admin Hôtel',
      email: 'admin@roommaster.app',
      role: UserRole.admin,
      passwordHash: sha256.convert(utf8.encode('admin123')).toString(),
      createdAt: now,
      lastLogin: now,
      isActive: true,
    );

    await db.insert(_usersTable, admin.toMap());
  }

  Future<void> _seedRooms(Database db) async {
    await db.insert(_roomsTable, {
      'number': '101',
      'type': 'Suite',
      'status': 'occupied',
      'rate': 180000,
      'notes': 'VIP guest',
      'category': 'Suite Exécutive',
      'capacity': 3,
      'bedType': 'King + sofa',
      'view': 'Ville',
      'photoUrl': '',
      'smoking': 0,
      'accessible': 1,
      'equipments': 'Machine Nespresso, Bureau, Coffre',
    });
    await db.insert(_roomsTable, {
      'number': '102',
      'type': 'Deluxe',
      'status': 'available',
      'rate': 120000,
      'notes': 'Freshly cleaned',
      'category': 'Deluxe',
      'capacity': 2,
      'bedType': 'Queen',
      'view': 'Patio',
      'photoUrl': '',
      'smoking': 0,
      'accessible': 0,
      'equipments': 'TV 55", Mini-bar',
    });
  }

  Future<void> _seedReferenceTables(Database db) async {
    const types = ['Classique', 'Deluxe', 'Suite', 'Appartement'];
    const categories = [
      'Économique / Standard',
      'Confort / Supérieure',
      'Deluxe',
      'Suite Junior',
      'Suite Exécutive',
      'Appartement',
    ];
    const equipments = [
      'Climatisation',
      'TV',
      'WiFi',
      'Mini-bar',
      'Coffre-fort',
      'Bureau',
      'Balcon',
    ];
    const services = ['Petit-déjeuner', 'Navette aéroport', 'Spa', 'Pressing'];

    for (final t in types) {
      await db.insert(_roomTypesTable, {
        'name': t,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final c in categories) {
      await db.insert(_roomCategoriesTable, {
        'name': c,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final e in equipments) {
      await db.insert(_roomEquipmentsTable, {
        'name': e,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final s in services) {
      await db.insert(_servicesTable, {
        'name': s,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // Reservations CRUD
  Future<int> insertReservation({
    required String guestName,
    required String roomNumber,
    required DateTime checkIn,
    required DateTime checkOut,
    String status = 'confirmed',
    double amount = 0,
    String? guestEmail,
    String? guestPhone,
    DateTime? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? profession,
    String? domicile,
    String? travelReason,
    String? comingFrom,
    String? goingTo,
    String? lodgingType,
    String? roomType,
    String? bedType,
    int adults = 1,
    int children = 0,
    String? reservationSource,
    String? paymentStatus,
    bool breakfastIncluded = false,
    bool parkingIncluded = false,
    bool wifiIncluded = true,
    List<String>? services,
    double deposit = 0,
    String? paymentMethod,
    String? idNumber,
    DateTime? idIssuedOn,
    String? idIssuedAt,
    String? visaNumber,
    DateTime? visaIssuedOn,
    String? visaIssuedAt,
    String? emergencyAddress,
    TimeOfDay? checkInTime,
    TimeOfDay? checkOutTime,
    String? cancellationReason,
    String? notes,
  }) async {
    final db = await _database;
    return db.insert(_reservationsTable, {
      'guestName': guestName,
      'roomNumber': roomNumber,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'status': status,
      'amount': amount,
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'placeOfBirth': placeOfBirth,
      'nationality': nationality,
      'profession': profession,
      'domicile': domicile,
      'travelReason': travelReason,
      'comingFrom': comingFrom,
      'goingTo': goingTo,
      'lodgingType': lodgingType,
      'roomType': roomType,
      'bedType': bedType,
      'adults': adults,
      'children': children,
      'reservationSource': reservationSource,
      'paymentStatus': paymentStatus,
      'breakfastIncluded': breakfastIncluded ? 1 : 0,
      'parkingIncluded': parkingIncluded ? 1 : 0,
      'wifiIncluded': wifiIncluded ? 1 : 0,
      'services': services?.join(','),
      'deposit': deposit,
      'paymentMethod': paymentMethod,
      'idNumber': idNumber,
      'idIssuedOn': idIssuedOn?.toIso8601String(),
      'idIssuedAt': idIssuedAt,
      'visaNumber': visaNumber,
      'visaIssuedOn': visaIssuedOn?.toIso8601String(),
      'visaIssuedAt': visaIssuedAt,
      'emergencyAddress': emergencyAddress,
      'checkInTime': checkInTime != null
          ? '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}'
          : null,
      'checkOutTime': checkOutTime != null
          ? '${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}'
          : null,
      'cancellationReason': cancellationReason,
      'notes': notes,
    });
  }

  Future<List<Map<String, dynamic>>> fetchReservations() async {
    final db = await _database;
    return db.query(_reservationsTable, orderBy: 'checkIn DESC');
  }

  Future<void> updateReservationStatus(int id, String status) async {
    final db = await _database;
    await db.update(
      _reservationsTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReservationRoomNumber(int id, String roomNumber) async {
    final db = await _database;
    await db.update(
      _reservationsTable,
      {'roomNumber': roomNumber},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReservationPayment(
    int id, {
    double? deposit,
    String? paymentMethod,
  }) async {
    final db = await _database;
    await db.update(
      _reservationsTable,
      {
        if (deposit != null) 'deposit': deposit,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cancelReservation(int id, String reason) async {
    final db = await _database;
    await db.update(
      _reservationsTable,
      {'status': 'cancelled', 'cancellationReason': reason},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReservation(int id) async {
    final db = await _database;
    await db.delete(_reservationsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateReservation({
    required int id,
    required String guestName,
    required String roomNumber,
    required DateTime checkIn,
    required DateTime checkOut,
    String status = 'confirmed',
    double amount = 0,
    String? guestEmail,
    String? guestPhone,
    DateTime? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? profession,
    String? domicile,
    String? travelReason,
    String? comingFrom,
    String? goingTo,
    String? lodgingType,
    String? roomType,
    String? bedType,
    int adults = 1,
    int children = 0,
    String? reservationSource,
    String? paymentStatus,
    bool breakfastIncluded = false,
    bool parkingIncluded = false,
    bool wifiIncluded = true,
    List<String>? services,
    double deposit = 0,
    String? paymentMethod,
    String? idNumber,
    DateTime? idIssuedOn,
    String? idIssuedAt,
    String? visaNumber,
    DateTime? visaIssuedOn,
    String? visaIssuedAt,
    String? emergencyAddress,
    TimeOfDay? checkInTime,
    TimeOfDay? checkOutTime,
    String? cancellationReason,
    String? notes,
  }) async {
    final db = await _database;
    await db.update(
      _reservationsTable,
      {
        'guestName': guestName,
        'roomNumber': roomNumber,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'status': status,
        'amount': amount,
        'guestEmail': guestEmail,
        'guestPhone': guestPhone,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'placeOfBirth': placeOfBirth,
        'nationality': nationality,
        'profession': profession,
        'domicile': domicile,
        'travelReason': travelReason,
        'comingFrom': comingFrom,
        'goingTo': goingTo,
        'lodgingType': lodgingType,
        'roomType': roomType,
        'bedType': bedType,
        'adults': adults,
        'children': children,
        'reservationSource': reservationSource,
        'paymentStatus': paymentStatus,
        'breakfastIncluded': breakfastIncluded ? 1 : 0,
        'parkingIncluded': parkingIncluded ? 1 : 0,
        'wifiIncluded': wifiIncluded ? 1 : 0,
        'services': services?.join(','),
        'deposit': deposit,
        'paymentMethod': paymentMethod,
        'idNumber': idNumber,
        'idIssuedOn': idIssuedOn?.toIso8601String(),
        'idIssuedAt': idIssuedAt,
        'visaNumber': visaNumber,
        'visaIssuedOn': visaIssuedOn?.toIso8601String(),
        'visaIssuedAt': visaIssuedAt,
        'emergencyAddress': emergencyAddress,
        'cancellationReason': cancellationReason,
        'checkInTime': checkInTime != null
            ? '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}'
            : null,
        'checkOutTime': checkOutTime != null
            ? '${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}'
            : null,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final db = await _database;
    return db.query(_roomsTable, orderBy: 'number ASC');
  }

  Future<List<Map<String, dynamic>>> fetchClients() async {
    final db = await _database;
    return db.query(_clientsTable, orderBy: 'name COLLATE NOCASE ASC');
  }

  Future<Map<String, dynamic>?> fetchClientById(int id) async {
    final db = await _database;
    final rows = await db.query(
      _clientsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> insertClient({
    required String name,
    String? lastName,
    String? email,
    String? phone,
    String? firstName,
    String? phone2,
    String? dateOfBirth,
    String? profession,
    String? placeOfBirth,
    String? domicile,
    String? maritalStatus,
    String? nationality,
    String? nationalityOther,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? idNumber,
    String? idPlace,
    String? idIssuedOn,
    String? idExpiresOn,
    String? passportNumber,
    String? passportPlace,
    String? passportIssuedOn,
    String? passportExpiresOn,
    String? visaNumber,
    String? visaPlace,
    String? visaIssuedOn,
    String? visaExpiresOn,
    String? emergencyName,
    String? emergencyPhone,
    String? emergencyRelation,
    String? emergencyAddress,
    String? clientType,
    String? reservationSource,
    bool vip = false,
    String? fidelityStatus,
    int? fidelityPoints,
    String? fidelitySince,
    String? roomPreferences,
    String? allergies,
    String? diet,
    String? otherPreferences,
    String? bedType,
    String? floorPreference,
    bool smoker = false,
    bool pets = false,
    String? feedback,
    String? provenance,
    String? destination,
    String? travelReason,
    String? company,
    String? jobTitle,
    String? vatNumber,
    bool companyBilling = false,
  }) async {
    final db = await _database;
    return db.insert(_clientsTable, {
      'name': name,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'createdAt': DateTime.now().toIso8601String(),
      'firstName': firstName,
      'phone2': phone2,
      'dateOfBirth': dateOfBirth,
      'profession': profession,
      'placeOfBirth': placeOfBirth,
      'domicile': domicile,
      'maritalStatus': maritalStatus,
      'nationality': nationality,
      'nationalityOther': nationalityOther,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'idNumber': idNumber,
      'idPlace': idPlace,
      'idIssuedOn': idIssuedOn,
      'idExpiresOn': idExpiresOn,
      'passportNumber': passportNumber,
      'passportPlace': passportPlace,
      'passportIssuedOn': passportIssuedOn,
      'passportExpiresOn': passportExpiresOn,
      'visaNumber': visaNumber,
      'visaPlace': visaPlace,
      'visaIssuedOn': visaIssuedOn,
      'visaExpiresOn': visaExpiresOn,
      'emergencyName': emergencyName,
      'emergencyPhone': emergencyPhone,
      'emergencyRelation': emergencyRelation,
      'emergencyAddress': emergencyAddress,
      'clientType': clientType,
      'reservationSource': reservationSource,
      'vip': vip ? 1 : 0,
      'fidelityStatus': fidelityStatus,
      'fidelityPoints': fidelityPoints,
      'fidelitySince': fidelitySince,
      'roomPreferences': roomPreferences,
      'allergies': allergies,
      'diet': diet,
      'otherPreferences': otherPreferences,
      'bedType': bedType,
      'floorPreference': floorPreference,
      'smoker': smoker ? 1 : 0,
      'pets': pets ? 1 : 0,
      'feedback': feedback,
      'provenance': provenance,
      'destination': destination,
      'travelReason': travelReason,
      'company': company,
      'jobTitle': jobTitle,
      'vatNumber': vatNumber,
      'companyBilling': companyBilling ? 1 : 0,
    });
  }

  Future<void> updateClient(
    int id, {
    required String name,
    String? lastName,
    String? email,
    String? phone,
    String? firstName,
    String? phone2,
    String? dateOfBirth,
    String? profession,
    String? placeOfBirth,
    String? domicile,
    String? maritalStatus,
    String? nationality,
    String? nationalityOther,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? idNumber,
    String? idPlace,
    String? idIssuedOn,
    String? idExpiresOn,
    String? passportNumber,
    String? passportPlace,
    String? passportIssuedOn,
    String? passportExpiresOn,
    String? visaNumber,
    String? visaPlace,
    String? visaIssuedOn,
    String? visaExpiresOn,
    String? emergencyName,
    String? emergencyPhone,
    String? emergencyRelation,
    String? emergencyAddress,
    String? clientType,
    String? reservationSource,
    bool vip = false,
    String? fidelityStatus,
    int? fidelityPoints,
    String? fidelitySince,
    String? roomPreferences,
    String? allergies,
    String? diet,
    String? otherPreferences,
    String? bedType,
    String? floorPreference,
    bool smoker = false,
    bool pets = false,
    String? feedback,
    String? provenance,
    String? destination,
    String? travelReason,
    String? company,
    String? jobTitle,
    String? vatNumber,
    bool companyBilling = false,
  }) async {
    final db = await _database;
    await db.update(
      _clientsTable,
      {
        'name': name,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'phone2': phone2,
        'dateOfBirth': dateOfBirth,
        'profession': profession,
        'placeOfBirth': placeOfBirth,
        'domicile': domicile,
        'maritalStatus': maritalStatus,
        'nationality': nationality,
        'nationalityOther': nationalityOther,
        'address': address,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'idNumber': idNumber,
        'idPlace': idPlace,
        'idIssuedOn': idIssuedOn,
        'idExpiresOn': idExpiresOn,
        'passportNumber': passportNumber,
        'passportPlace': passportPlace,
        'passportIssuedOn': passportIssuedOn,
        'passportExpiresOn': passportExpiresOn,
        'visaNumber': visaNumber,
        'visaPlace': visaPlace,
        'visaIssuedOn': visaIssuedOn,
        'visaExpiresOn': visaExpiresOn,
        'emergencyName': emergencyName,
        'emergencyPhone': emergencyPhone,
        'emergencyRelation': emergencyRelation,
        'emergencyAddress': emergencyAddress,
        'clientType': clientType,
        'reservationSource': reservationSource,
        'vip': vip ? 1 : 0,
        'fidelityStatus': fidelityStatus,
        'fidelityPoints': fidelityPoints,
        'fidelitySince': fidelitySince,
        'roomPreferences': roomPreferences,
        'allergies': allergies,
        'diet': diet,
        'otherPreferences': otherPreferences,
        'bedType': bedType,
        'floorPreference': floorPreference,
        'smoker': smoker ? 1 : 0,
        'pets': pets ? 1 : 0,
        'feedback': feedback,
        'provenance': provenance,
        'destination': destination,
        'travelReason': travelReason,
        'company': company,
        'jobTitle': jobTitle,
        'vatNumber': vatNumber,
        'companyBilling': companyBilling ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final db = await _database;
    return db.query(_expensesTable, orderBy: 'createdAt DESC');
  }

  Future<int> insertExpense({
    required String label,
    required double amount,
    DateTime? createdAt,
  }) async {
    final db = await _database;
    return db.insert(_expensesTable, {
      'label': label,
      'amount': amount,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    });
  }

  Future<void> upsertRoom({
    int? id,
    required String number,
    required String type,
    required String status,
    required double rate,
    String? notes,
    String? category,
    int? capacity,
    String? bedType,
    String? equipments,
    String? view,
    String? photoUrl,
    bool smoking = false,
    bool accessible = false,
  }) async {
    final db = await _database;
    await db.insert(_roomsTable, {
      if (id != null) 'id': id,
      'number': number,
      'type': type,
      'status': status,
      'rate': rate,
      'notes': notes,
      'category': category,
      'capacity': capacity,
      'bedType': bedType,
      'equipments': equipments,
      'view': view,
      'photoUrl': photoUrl,
      'smoking': smoking ? 1 : 0,
      'accessible': accessible ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> fetchRoomTypes() async {
    final db = await _database;
    final rows = await db.query(_roomTypesTable, orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> fetchRoomCategories() async {
    final db = await _database;
    final rows = await db.query(_roomCategoriesTable, orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> fetchRoomEquipments() async {
    final db = await _database;
    final rows = await db.query(_roomEquipmentsTable, orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> fetchServices() async {
    final db = await _database;
    final rows = await db.query(_servicesTable, orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> addRoomType(String name) async {
    final db = await _database;
    await db.insert(_roomTypesTable, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> addRoomCategory(String name) async {
    final db = await _database;
    await db.insert(_roomCategoriesTable, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> addRoomEquipment(String name) async {
    final db = await _database;
    await db.insert(_roomEquipmentsTable, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> addService(String name) async {
    final db = await _database;
    await db.insert(_servicesTable, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteRoomType(String name) async {
    final db = await _database;
    await db.delete(_roomTypesTable, where: 'name = ?', whereArgs: [name]);
  }

  Future<void> deleteRoomCategory(String name) async {
    final db = await _database;
    await db.delete(_roomCategoriesTable, where: 'name = ?', whereArgs: [name]);
  }

  Future<void> deleteRoomEquipment(String name) async {
    final db = await _database;
    await db.delete(_roomEquipmentsTable, where: 'name = ?', whereArgs: [name]);
  }

  Future<void> deleteService(String name) async {
    final db = await _database;
    await db.delete(_servicesTable, where: 'name = ?', whereArgs: [name]);
  }

  Future<void> updateRoomStatus(int id, String status) async {
    final db = await _database;
    await db.update(
      _roomsTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRoom(int id) async {
    final db = await _database;
    await db.delete(_roomsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> fetchStatusOverview() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT status, COUNT(*) as total FROM $_roomsTable GROUP BY status',
    );
    return {
      for (final row in result)
        (row['status'] as String): (row['total'] as int?) ?? 0,
    };
  }

  Future<void> ensureDefaultAdmin() async {
    final db = await _database;
    await _createUsersTable(db);
    await _seedUsers(db);
  }

  Future<EntityInfo> getEntityInfo() async {
    final db = await _database;
    await _createEntityTable(db);
    final rows = await db.query(_entityTable, limit: 1);
    if (rows.isNotEmpty) {
      return EntityInfo.fromMap(rows.first);
    }
    final defaultEntity = EntityInfo(
      name: 'Roommaster Resort',
      type: 'Hôtellerie • 4 étoiles',
      address: '123 Avenue de la Plage, Douala',
      contacts: 'Tel: +237 699 00 00 00 • contact@roommaster.app',
      website: 'www.roommaster.app',
      rccm: 'RC/DLA/2024/B12345',
      nif: '0000000000123',
      currency: 'FCFA',
      exercice: '01/01/2024 - 31/12/2024',
      plan: 'SYSCOHADA',
      legalResponsible: 'Mme. Aissatou Ngassa',
      targetRevenue: '1 200 000 000',
      capacity: '120 chambres dont 8 suites',
      timezone: 'GMT+1 (Afrique centrale)',
      logoPath: '',
    );
    await db.insert(_entityTable, defaultEntity.toMap());
    return defaultEntity;
  }

  Future<void> saveEntityInfo(EntityInfo info) async {
    final db = await _database;
    await _createEntityTable(db);
    await db.insert(
      _entityTable,
      info.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<String> backupDatabase({required String targetPath}) async {
    final source = await _dbPath();
    final sourceFile = File(source);
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<void> restoreDatabase({required String sourcePath}) async {
    final destPath = await _dbPath();
    await close();
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    await init();
  }

  Future<List<DocumentTemplate>> getDocumentTemplates() async {
    final db = await _database;
    await _createTemplatesTable(db);
    final rows = await db.query(_templatesTable, orderBy: 'lastModified DESC');
    return rows.map(DocumentTemplate.fromMap).toList();
  }

  Future<void> saveDocumentTemplate(DocumentTemplate template) async {
    final db = await _database;
    await _createTemplatesTable(db);
    await db.insert(
      _templatesTable,
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDocumentTemplate(String id) async {
    final db = await _database;
    await db.delete(_templatesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _seedTemplates(Database db) async {
    final existing = await db.query(_templatesTable, limit: 1);
    if (existing.isNotEmpty) return;
    final now = DateTime.now();
    final defaults = [
      DocumentTemplate(
        id: 'facture_default',
        name: 'Facture',
        type: 'facture',
        content: 'Modèle de facture de base',
        lastModified: now,
      ),
      DocumentTemplate(
        id: 'recu_default',
        name: 'Reçu',
        type: 'recu',
        content: 'Modèle de reçu de base',
        lastModified: now,
      ),
      DocumentTemplate(
        id: 'attestation_default',
        name: 'Attestation',
        type: 'attestation',
        content: 'Modèle d\'attestation de base',
        lastModified: now,
      ),
      DocumentTemplate(
        id: 'canvas_default',
        name: 'Template Canvas',
        type: 'canvas',
        content: '{"canvas":[]}',
        lastModified: now,
      ),
    ];
    for (final t in defaults) {
      await db.insert(_templatesTable, t.toMap());
    }
  }

  Future<void> _seedEcritureTemplates(Database db) async {
    final existing = await db.query(_ecritureTemplatesTable, limit: 1);
    if (existing.isNotEmpty) return;
    final seeds = [
      {
        'id': 'tpl_salaires',
        'label': 'Paie / Salaires',
        'journalId': 'j_od',
        'content': jsonEncode([
          {
            'account': '641',
            'label': 'Charges salariales',
            'debit': 0,
            'credit': 0,
          },
          {
            'account': '421',
            'label': 'Dettes salariales',
            'debit': 0,
            'credit': 0,
          },
        ]),
      },
      {
        'id': 'tpl_fournisseur',
        'label': 'Facture fournisseur',
        'journalId': 'j_ach',
        'content': jsonEncode([
          {
            'account': '60',
            'label': 'Achat marchandises',
            'debit': 0,
            'credit': 0,
          },
          {'account': '401', 'label': 'Fournisseur', 'debit': 0, 'credit': 0},
        ]),
      },
    ];
    for (final t in seeds) {
      await db.insert(
        _ecritureTemplatesTable,
        t,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> resetDefaultTemplates() async {
    final db = await _database;
    await db.delete(_templatesTable);
    await _seedTemplates(db);
  }

  // ---------- Comptabilité ----------
  Future<List<Map<String, dynamic>>> getJournaux() async {
    final db = await _database;
    await _createJournauxTable(db);
    return db.query(_journauxTable, orderBy: 'code');
  }

  Future<void> insertJournal(Map<String, Object?> journal) async {
    final db = await _database;
    await _createJournauxTable(db);
    await db.insert(
      _journauxTable,
      journal,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPlanComptable() async {
    final db = await _database;
    await _createPlanComptableTable(db);
    return db.query(_planComptableTable, orderBy: 'code');
  }

  Future<void> insertCompte(Map<String, Object?> compte) async {
    final db = await _database;
    await _createPlanComptableTable(db);
    await db.insert(
      _planComptableTable,
      compte,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCompte(String id) async {
    final db = await _database;
    await db.delete(_planComptableTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasChildAccounts(String id) async {
    final db = await _database;
    final rows = await db.query(
      _planComptableTable,
      where: 'parentId = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> countEcrituresForAccountCode(String accountCode) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as c FROM $_ecrituresTable WHERE accountCode = ?',
      [accountCode],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getEcritures({
    DateTime? start,
    DateTime? end,
    String? journalId,
  }) async {
    final db = await _database;
    await _createEcrituresTable(db);
    final where = <String>[];
    final args = <Object?>[];
    if (start != null) {
      where.add('date >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('date <= ?');
      args.add(end.toIso8601String());
    }
    if (journalId != null &&
        journalId.isNotEmpty &&
        journalId.toLowerCase() != 'tous') {
      where.add('journalId = ?');
      args.add(journalId);
    }
    return db.query(
      _ecrituresTable,
      orderBy: 'date DESC',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
    );
  }

  Future<void> insertEcriture(Map<String, Object?> ecriture) async {
    final db = await _database;
    await _createEcrituresTable(db);
    await db.insert(
      _ecrituresTable,
      ecriture,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteEcriture(String id) async {
    final db = await _database;
    await db.delete(_ecrituresTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetPlanComptable() async {
    final db = await _database;
    await db.delete(_planComptableTable);
    await _seedCompta(db);
  }

  Future<List<Map<String, dynamic>>> getEcritureTemplates() async {
    final db = await _database;
    await _createEcritureTemplatesTable(db);
    return db.query(_ecritureTemplatesTable, orderBy: 'label');
  }

  Future<void> saveEcritureTemplate(Map<String, dynamic> map) async {
    final db = await _database;
    await _createEcritureTemplatesTable(db);
    await db.insert(
      _ecritureTemplatesTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteEcritureTemplate(String id) async {
    final db = await _database;
    await db.delete(_ecritureTemplatesTable, where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Maintenance / Inventaire ----------
  Future<List<Map<String, dynamic>>> getMaintenanceTickets() async {
    final db = await _database;
    await _createMaintenanceTable(db);
    return db.query(_maintenanceTable, orderBy: 'createdAt DESC');
  }

  Future<int> addMaintenanceTicket({
    required String room,
    required String title,
    required String status,
    required String priority,
    required String assigned,
  }) async {
    final db = await _database;
    await _createMaintenanceTable(db);
    return db.insert(_maintenanceTable, {
      'room': room,
      'title': title,
      'status': status,
      'priority': priority,
      'assigned': assigned,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateMaintenanceTicket(
    int id, {
    String? status,
    String? assigned,
    String? priority,
  }) async {
    final db = await _database;
    await _createMaintenanceTable(db);
    await db.update(
      _maintenanceTable,
      {
        if (status != null) 'status': status,
        if (assigned != null) 'assigned': assigned,
        if (priority != null) 'priority': priority,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMaintenanceTicket(int id) async {
    final db = await _database;
    await _createMaintenanceTable(db);
    await db.delete(_maintenanceTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    final db = await _database;
    await _createInventoryTable(db);
    return db.query(_inventoryTable, orderBy: 'label');
  }

  Future<int> addInventoryItem({
    required String label,
    required int stock,
    required int threshold,
  }) async {
    final db = await _database;
    await _createInventoryTable(db);
    return db.insert(_inventoryTable, {
      'label': label,
      'stock': stock,
      'threshold': threshold,
    });
  }

  Future<void> updateInventoryItem(int id, {int? stock, int? threshold}) async {
    final db = await _database;
    await _createInventoryTable(db);
    await db.update(
      _inventoryTable,
      {
        if (stock != null) 'stock': stock,
        if (threshold != null) 'threshold': threshold,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInventoryItem(int id) async {
    final db = await _database;
    await _createInventoryTable(db);
    await db.delete(_inventoryTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addServiceOrder({
    required String serviceType,
    required String item,
    String? room,
    String status = 'En cours',
  }) async {
    final db = await _database;
    await _createServiceOrdersTable(db);
    return db.insert(_serviceOrdersTable, {
      'serviceType': serviceType,
      'item': item,
      'room': room,
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getServiceOrders(
    String serviceType,
  ) async {
    final db = await _database;
    await _createServiceOrdersTable(db);
    return db.query(
      _serviceOrdersTable,
      where: 'serviceType = ?',
      whereArgs: [serviceType],
      orderBy: 'createdAt DESC',
    );
  }

  Future<void> updateServiceOrderStatus(int id, String status) async {
    final db = await _database;
    await _createServiceOrdersTable(db);
    await db.update(
      _serviceOrdersTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteServiceOrder(int id) async {
    final db = await _database;
    await _createServiceOrdersTable(db);
    await db.delete(_serviceOrdersTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _seedCompta(Database db) async {
    final journals = await db.query(_journauxTable, limit: 1);
    if (journals.isEmpty) {
      final defaults = [
        {
          'id': 'j_ach',
          'code': 'ACH',
          'name': 'Achats',
          'description': 'Journal des achats',
          'type': 'ACHATS',
        },
        {
          'id': 'j_vte',
          'code': 'VTE',
          'name': 'Ventes',
          'description': 'Journal des ventes',
          'type': 'VENTES',
        },
        {
          'id': 'j_bq',
          'code': 'BQ',
          'name': 'Banque',
          'description': 'Opérations bancaires',
          'type': 'BANQUE',
        },
        {
          'id': 'j_cai',
          'code': 'CAI',
          'name': 'Caisse',
          'description': 'Journal de caisse',
          'type': 'CAISSE',
        },
        {
          'id': 'j_od',
          'code': 'OD',
          'name': 'Opérations diverses',
          'description': 'OD',
          'type': 'DIVERS',
        },
      ];
      for (final j in defaults) {
        await db.insert(
          _journauxTable,
          j,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    final plan = await db.query(_planComptableTable, limit: 1);
    if (plan.isEmpty) {
      final seeds = [
        {'id': '1', 'code': '1', 'title': 'Capitaux propres', 'parentId': null},
        {
          'id': '101',
          'code': '101',
          'title': 'Capital social',
          'parentId': '1',
        },
        {'id': '2', 'code': '2', 'title': 'Immobilisations', 'parentId': null},
        {
          'id': '211',
          'code': '211',
          'title': 'Immobilisations corporelles',
          'parentId': '2',
        },
        {'id': '3', 'code': '3', 'title': 'Stocks', 'parentId': null},
        {'id': '4', 'code': '4', 'title': 'Tiers', 'parentId': null},
        {'id': '401', 'code': '401', 'title': 'Fournisseurs', 'parentId': '4'},
        {'id': '411', 'code': '411', 'title': 'Clients', 'parentId': '4'},
        {'id': '5', 'code': '5', 'title': 'Banque & caisse', 'parentId': null},
        {'id': '512', 'code': '512', 'title': 'Banques', 'parentId': '5'},
        {'id': '53', 'code': '53', 'title': 'Caisse', 'parentId': '5'},
        {'id': '6', 'code': '6', 'title': 'Charges', 'parentId': null},
        {'id': '60', 'code': '60', 'title': 'Achats', 'parentId': '6'},
        {'id': '7', 'code': '7', 'title': 'Produits', 'parentId': null},
      ];
      for (final s in seeds) {
        await db.insert(
          _planComptableTable,
          s,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> _ensureMaintenanceSeed(Database db) async {
    final existing = await db.query(_maintenanceTable, limit: 1);
    if (existing.isEmpty) {
      final now = DateTime.now();
      await db.insert(_maintenanceTable, {
        'room': '204',
        'title': 'Clim ne démarre pas',
        'status': 'En cours',
        'priority': 'Haute',
        'assigned': 'Technicien A',
        'createdAt': now.toIso8601String(),
      });
    }
    final inv = await db.query(_inventoryTable, limit: 1);
    if (inv.isEmpty) {
      await db.insert(_inventoryTable, {
        'label': 'Draps',
        'stock': 120,
        'threshold': 60,
      });
      await db.insert(_inventoryTable, {
        'label': 'Serviettes',
        'stock': 80,
        'threshold': 50,
      });
      await db.insert(_inventoryTable, {
        'label': 'Shampoings',
        'stock': 40,
        'threshold': 80,
      });
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _database;
    final rows = await db.query(
      _usersTable,
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<List<User>> getUsers() async {
    final db = await _database;
    final rows = await db.query(_usersTable, orderBy: 'createdAt DESC');
    return rows.map(User.fromMap).toList();
  }

  Future<void> saveUser(User user) async {
    final db = await _database;
    await db.insert(
      _usersTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUser(User user) async {
    final db = await _database;
    await db.update(
      _usersTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setLastLogin(String userId, DateTime dateTime) async {
    final db = await _database;
    await db.update(
      _usersTable,
      {'lastLogin': dateTime.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> countActiveAdmins() async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as c FROM $_usersTable WHERE role = ? AND isActive = 1',
      [UserRole.admin.index],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<Map<String, String>> resetAdminUser() async {
    final db = await _database;
    final rng = Random.secure();
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*()-_=+';
    final plainPassword = List.generate(
      12,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    final hashedPassword = sha256
        .convert(utf8.encode(plainPassword))
        .toString();
    final now = DateTime.now();
    final adminId = 'admin_${now.millisecondsSinceEpoch}';
    final admin = User(
      id: adminId,
      name: 'Admin Hôtel',
      email: 'admin@roommaster.app',
      role: UserRole.admin,
      passwordHash: hashedPassword,
      createdAt: now,
      lastLogin: now,
      isActive: true,
      is2faEnabled: false,
      twoFaSecret: '',
    );

    await db.transaction((txn) async {
      await txn.delete(_usersTable);
      await txn.insert(_usersTable, admin.toMap());
    });

    return {'email': admin.email, 'password': plainPassword};
  }

  Future<void> _addClientColumnsForV12(Database db) async {
    final columns = <String, String>{
      'lastName': 'TEXT',
      'firstName': 'TEXT',
      'phone2': 'TEXT',
      'dateOfBirth': 'TEXT',
      'profession': 'TEXT',
      'placeOfBirth': 'TEXT',
      'domicile': 'TEXT',
      'maritalStatus': 'TEXT',
      'nationality': 'TEXT',
      'nationalityOther': 'TEXT',
      'address': 'TEXT',
      'city': 'TEXT',
      'postalCode': 'TEXT',
      'country': 'TEXT',
      'idNumber': 'TEXT',
      'idPlace': 'TEXT',
      'idIssuedOn': 'TEXT',
      'idExpiresOn': 'TEXT',
      'passportNumber': 'TEXT',
      'passportPlace': 'TEXT',
      'passportIssuedOn': 'TEXT',
      'passportExpiresOn': 'TEXT',
      'visaNumber': 'TEXT',
      'visaPlace': 'TEXT',
      'visaIssuedOn': 'TEXT',
      'visaExpiresOn': 'TEXT',
      'emergencyName': 'TEXT',
      'emergencyPhone': 'TEXT',
      'emergencyRelation': 'TEXT',
      'emergencyAddress': 'TEXT',
      'clientType': 'TEXT',
      'reservationSource': 'TEXT',
      'vip': 'INTEGER',
      'fidelityStatus': 'TEXT',
      'fidelityPoints': 'INTEGER',
      'fidelitySince': 'TEXT',
      'roomPreferences': 'TEXT',
      'allergies': 'TEXT',
      'diet': 'TEXT',
      'otherPreferences': 'TEXT',
      'bedType': 'TEXT',
      'floorPreference': 'TEXT',
      'smoker': 'INTEGER',
      'pets': 'INTEGER',
      'feedback': 'TEXT',
      'provenance': 'TEXT',
      'destination': 'TEXT',
      'travelReason': 'TEXT',
      'company': 'TEXT',
      'jobTitle': 'TEXT',
      'vatNumber': 'TEXT',
      'companyBilling': 'INTEGER',
    };

    for (final entry in columns.entries) {
      try {
        await db.execute(
          'ALTER TABLE $_clientsTable ADD COLUMN ${entry.key} ${entry.value}',
        );
      } catch (_) {
        // ignore if already exists
      }
    }
  }
}
