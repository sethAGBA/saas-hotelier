import 'dart:async';
import 'dart:io';
import 'package:afroforma/services/storage_service.dart';
import 'package:afroforma/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'dart:convert';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Future<void> runOnce() async {
    // Pull then push or push then pull – here we push first to publish local changes
    await _autoUploadDocuments();
    await _pushTable('formations');
    await _pushTable('formateurs');
    await _pushTable('etudiants');
    await _pushTable('sessions');
    await _pushTable('inscriptions');
    await _pushTable('student_payments');
    await _pushTable('documents');
    await _pushTable('journaux');
    await _pushTable('plan_comptable');
    await _pushTable('numerotation');
    await _pushTable('lettrages');
    await _pushTable('exercices');
    await _pushTable('app_prefs');
    await _pushTable('ecritures_comptables');
    await _pushDeletions();
    await _pullTable('formations');
    await _pullTable('formateurs');
    await _pullTable('etudiants');
    await _pullTable('sessions');
    await _pullTable('inscriptions');
    await _pullTable('student_payments');
    await _pullTable('documents');
    await _pullTable('journaux');
    await _pullTable('plan_comptable');
    await _pullTable('numerotation');
    await _pullTable('lettrages');
    await _pullTable('exercices');
    await _pullTable('app_prefs');
    await _pullTable('ecritures_comptables');
    await _markSyncedNow();
  }

  /// Safe variant of runOnce that returns a result map instead of throwing.
  /// { 'success': bool, 'error': String? }
  Future<Map<String, Object?>> runOnceSafe() async {
    try {
      await runOnce();
      return {'success': true};
    } catch (e, st) {
      // Return summarized error for UI
  final msg = e.toString();
      // Optionally log stacktrace to console
      // ignore: avoid_print
      print('[SyncService] runOnceSafe error: $msg\n$st');
      return {'success': false, 'error': msg};
    }
  }

  /// Sync a single table now (push, deletions, pull). Returns {'success':bool, 'error':String?}
  Future<Map<String, Object?>> syncTableNow(String table) async {
    try {
      await _autoUploadDocuments(); // safe to call; will early-return if not relevant
      await _pushTable(table);
      await _pushDeletions();
      await _pullTable(table);
      await _markSyncedNow();
      return {'success': true};
    } catch (e, st) {
      // ignore: avoid_print
      print('[SyncService] syncTableNow($table) error: $e\n$st');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Force-refresh a table from Firestore without considering lastSyncAt.
  /// Downloads all docs, filters to known columns, and upserts locally.
  /// Returns {'success':bool, 'error':String?}
  Future<Map<String, Object?>> refreshTableFromFirestore(String table) async {
    try {
      final db = await _db;
      final col = _fs.collection(_collectionFor(table));
      final qs = await col.get();

      // Inspect table columns to filter unknown fields
      Set<String> cols = {};
      try {
        final info = await db.rawQuery('PRAGMA table_info($table)');
        cols = info.map((r) => (r['name'] as String).toLowerCase()).toSet();
      } catch (_) {}

      for (final d in qs.docs) {
        final data = d.data();
        if (data == null) continue;
        final del = data['isDeleted'];
        if (del == true || del == 1) continue;

        final raw = Map<String, Object?>.from(data);
        if (table == 'app_prefs') {
          raw['key'] = d.id;
        } else {
          raw['id'] = d.id;
        }

        final toInsert = <String, Object?>{};
        raw.forEach((k, v) {
          final keyLower = k.toLowerCase();
          if (!cols.contains(keyLower)) return;
          toInsert[k] = _coerceSqlValue(v);
        });
        if (toInsert.isEmpty) continue;
        await db.insert(table, toInsert, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await _markSyncedNow();
      return {'success': true};
    } catch (e, st) {
      // ignore: avoid_print
      print('[SyncService] refreshTableFromFirestore($table) error: $e\n$st');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sync only formations and their related master data (formateurs, sessions).
  /// Returns {'success':bool, 'error':String?}
  Future<Map<String, Object?>> syncFormationBundleNow() async {
    try {
      await _autoUploadDocuments();
      await _pushTable('formations');
      await _pushTable('formateurs');
      await _pushTable('sessions');
      await _pushTable('documents');
      await _pushDeletions();
      await _pullTable('formations');
      await _pullTable('formateurs');
      await _pullTable('sessions');
      await _pullTable('documents');
      await _markSyncedNow();
      return {'success': true};
    } catch (e, st) {
      // ignore: avoid_print
      print('[SyncService] syncFormationBundleNow error: $e\n$st');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sync only accounting-related tables: journaux, plan_comptable, numerotation,
  /// lettrages, ecritures_comptables, and app_prefs (for compta settings).
  Future<Map<String, Object?>> syncComptaBundleNow() async {
    try {
      await _pushTable('journaux');
      await _pushTable('plan_comptable');
      await _pushTable('numerotation');
      await _pushTable('lettrages');
      await _pushTable('ecritures_comptables');
      await _pushTable('app_prefs');
      await _pushDeletions();
      await _pullTable('journaux');
      await _pullTable('plan_comptable');
      await _pullTable('numerotation');
      await _pullTable('lettrages');
      await _pullTable('ecritures_comptables');
      await _pullTable('app_prefs');
      await _markSyncedNow();
      return {'success': true};
    } catch (e, st) {
      // ignore: avoid_print
      print('[SyncService] syncComptaBundleNow error: $e\n$st');
      return {'success': false, 'error': e.toString()};
    }
  }

  Timer? _timer;
  void startPeriodic({Duration interval = const Duration(minutes: 5)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      try { await runOnce(); } catch (_) {}
    });
  }

  Future<void> _autoUploadDocuments() async {
    // Upload local document files that are not yet uploaded to Storage
    final db = await _db;
    // Inspect columns to avoid errors on older schemas
    Set<String> cols = {};
    try {
      final info = await db.rawQuery("PRAGMA table_info(documents)");
      cols = info.map((r) => (r['name'] as String).toString().toLowerCase()).toSet();
    } catch (_) {}
    final hasRemoteUrl = cols.contains('remoteurl');
    final hasPath = cols.contains('path');
    final hasIsDeleted = cols.contains('isdeleted');

    if (!hasPath) return; // cannot proceed without path
    if (!hasRemoteUrl) {
      // Older DB: no remoteUrl column; skip auto-upload to avoid re-upload loops
      // ignore: avoid_print
      print('[Sync] Skip _autoUploadDocuments: documents.remoteUrl column missing');
      return;
    }

    String where = "COALESCE(remoteUrl,'') = '' AND COALESCE(path,'') != ''";
    if (hasIsDeleted) {
      where += " AND COALESCE(isDeleted,0)=0";
    }
    final rows = await db.query('documents', where: where);
    if (rows.isEmpty) return;
    try {
      // Lazy import to avoid cycles
      // ignore: unnecessary_import
    } catch (_) {}
    for (final r in rows) {
      final path = (r['path'] ?? '').toString();
      final fileName = (r['fileName'] ?? '').toString();
      if (path.isEmpty || fileName.isEmpty) continue;
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final folder = (r['studentId']?.toString().isNotEmpty ?? false)
            ? 'students/${r['studentId']}'
            : ((r['formationId']?.toString().isNotEmpty ?? false) ? 'formations/${r['formationId']}' : 'misc');
        final uploadPath = 'uploads/$folder/$fileName';
        final storage = StorageService();
        final url = await storage.uploadFile(uploadPath, file);
        // Update remoteUrl only if column exists
        if (hasRemoteUrl) {
          await db.update('documents', {'remoteUrl': url}, where: 'id = ?', whereArgs: [r['id']]);
        }
      } catch (_) {
        // best-effort; continue other files
      }
    }
  }
  void stop() => _timer?.cancel();

  Future<Database> get _db async => await DatabaseService().db;

  Future<int> _lastSyncAt() async {
    final db = await _db;
    final rows = await db.query('app_prefs', where: 'key = ?', whereArgs: ['lastSyncAt'], limit: 1);
    if (rows.isEmpty) return 0;
    try { return int.tryParse(rows.first['value']?.toString() ?? '0') ?? 0; } catch (_) { return 0; }
  }

  /// Returns sync status for a single student record.
  /// Map contains: existsLocally, localUpdatedAt, lastSyncAt, needsPush, remoteExists, remoteUpdatedAt, needsPull
  Future<Map<String, Object?>> isStudentSynced(String studentId) async {
    final db = await _db;
    final rows = await db.query('etudiants', where: 'id = ?', whereArgs: [studentId], limit: 1);
    if (rows.isEmpty) return {'existsLocally': false};
    final row = rows.first;
    final localUpdatedAt = int.tryParse(row['updatedAt']?.toString() ?? '0') ?? 0;
    final lastSync = await _lastSyncAt();

    // Fetch remote doc
    final docRef = _fs.collection(_collectionFor('etudiants')).doc(studentId);
    final docSnap = await docRef.get();
    bool remoteExists = false;
    int remoteUpdatedAt = 0;
    if (docSnap.exists) {
      final data = docSnap.data();
      if (data != null) {
        final del = data['isDeleted'];
        if (del == true || del == 1) {
          remoteExists = false;
        } else {
          remoteExists = true;
          final ru = data['updatedAt'];
          remoteUpdatedAt = ru is int ? ru : int.tryParse(ru?.toString() ?? '0') ?? 0;
        }
      }
    }

    final needsPush = localUpdatedAt > lastSync;
    final needsPull = remoteUpdatedAt > lastSync;

    return {
      'existsLocally': true,
      'localUpdatedAt': localUpdatedAt,
      'lastSyncAt': lastSync,
      'needsPush': needsPush,
      'remoteExists': remoteExists,
      'remoteUpdatedAt': remoteUpdatedAt,
      'needsPull': needsPull,
    };
  }

  /// Upload a single document's file to storage now (if path exists) and update remoteUrl.
  Future<void> uploadDocumentNow(String documentId) async {
    final db = await _db;
    final rows = await db.query('documents', where: 'id = ?', whereArgs: [documentId], limit: 1);
    if (rows.isEmpty) {
      NotificationService().showNotification(NotificationItem(id: DateTime.now().toString(), message: 'Document introuvable', backgroundColor: Colors.redAccent));
      return;
    }
    final r = rows.first;
    final path = (r['path'] ?? '').toString();
    final fileName = (r['fileName'] ?? '').toString();
    if (path.isEmpty || fileName.isEmpty) {
      NotificationService().showNotification(NotificationItem(id: DateTime.now().toString(), message: 'Fichier local manquant', backgroundColor: Colors.redAccent));
      return;
    }
    try {
      final file = File(path);
      if (!await file.exists()) {
        NotificationService().showNotification(NotificationItem(id: DateTime.now().toString(), message: 'Fichier local introuvable', backgroundColor: Colors.redAccent));
        return;
      }
      final folder = (r['studentId']?.toString().isNotEmpty ?? false)
          ? 'students/${r['studentId']}'
          : ((r['formationId']?.toString().isNotEmpty ?? false) ? 'formations/${r['formationId']}' : 'misc');
      final uploadPath = 'uploads/$folder/$fileName';
      final storage = StorageService();
      final url = await storage.uploadFile(uploadPath, file);
      await db.update('documents', {'remoteUrl': url}, where: 'id = ?', whereArgs: [documentId]);
      NotificationService().showNotification(NotificationItem(id: DateTime.now().toString(), message: 'Fichier uploadé'));
    } catch (e) {
      NotificationService().showNotification(NotificationItem(id: DateTime.now().toString(), message: 'Erreur upload fichier', backgroundColor: Colors.redAccent));
    }
  }

  /// Returns a per-section sync summary for a student.
  /// Sections: student (etudiants), inscriptions (evaluations), payments, communications, documents
  Future<Map<String, Object?>> studentSyncSummary(String studentId) async {
    final db = await _db;
    final lastSync = await _lastSyncAt();

    // Helper to check local rows updated after lastSync
    Future<int> _localCount(String table, {String? whereExtra}) async {
      final where = 'studentId = ?' + (whereExtra != null ? ' AND $whereExtra' : '');
      final rows = await db.rawQuery('SELECT COUNT(*) as c FROM $table WHERE $where', [studentId]);
      return int.tryParse(rows.first['c']?.toString() ?? '0') ?? 0;
    }

    Future<int> _localUpdatedCount(String table) async {
      // if updatedAt column missing, fallback to total count
      try {
        final info = await db.rawQuery("PRAGMA table_info('$table')");
        final cols = info.map((r) => (r['name'] as String).toLowerCase()).toSet();
        if (!cols.contains('updatedat')) {
          return await _localCount(table);
        }
      } catch (_) {}
      final rows = await db.rawQuery('SELECT COUNT(*) as c FROM $table WHERE studentId = ? AND COALESCE(updatedAt,0) > ?', [studentId, lastSync]);
      return int.tryParse(rows.first['c']?.toString() ?? '0') ?? 0;
    }

    // Local checks
    final studentRows = await db.query('etudiants', where: 'id = ?', whereArgs: [studentId], limit: 1);
    final studentLocalUpdated = studentRows.isEmpty ? 0 : (int.tryParse(studentRows.first['updatedAt']?.toString() ?? '0') ?? 0) > lastSync ? 1 : 0;
    final inscriptionsLocalUpdated = await _localUpdatedCount('inscriptions');
    final paymentsLocalUpdated = await _localUpdatedCount('student_payments');
    final commsLocalUpdated = await _localUpdatedCount('communications');
    final docsLocalUpdated = await _localUpdatedCount('documents');

    // Remote checks: query Firestore for any docs for this student updated after lastSync
    int inscriptionsRemoteUpdated = 0;
    int paymentsRemoteUpdated = 0;
    int commsRemoteUpdated = 0;
    int docsRemoteUpdated = 0;
    try {
      final insQs = await _fs.collection(_collectionFor('inscriptions')).where('studentId', isEqualTo: studentId).where('updatedAt', isGreaterThan: lastSync).limit(1).get();
      if (insQs.docs.isNotEmpty) inscriptionsRemoteUpdated = 1;
      final payQs = await _fs.collection(_collectionFor('student_payments')).where('studentId', isEqualTo: studentId).where('updatedAt', isGreaterThan: lastSync).limit(1).get();
      if (payQs.docs.isNotEmpty) paymentsRemoteUpdated = 1;
      final comQs = await _fs.collection(_collectionFor('communications')).where('studentId', isEqualTo: studentId).where('updatedAt', isGreaterThan: lastSync).limit(1).get();
      if (comQs.docs.isNotEmpty) commsRemoteUpdated = 1;
      final docQs = await _fs.collection(_collectionFor('documents')).where('studentId', isEqualTo: studentId).where('updatedAt', isGreaterThan: lastSync).limit(1).get();
      if (docQs.docs.isNotEmpty) docsRemoteUpdated = 1;
    } catch (_) {}

    return {
      'student': {
        'existsLocally': studentRows.isNotEmpty,
        'needsPush': studentLocalUpdated > 0,
      },
      'inscriptions': {
        'localChanges': inscriptionsLocalUpdated,
        'remoteChanges': inscriptionsRemoteUpdated,
      },
      'payments': {
        'localChanges': paymentsLocalUpdated,
        'remoteChanges': paymentsRemoteUpdated,
      },
      'communications': {
        'localChanges': commsLocalUpdated,
        'remoteChanges': commsRemoteUpdated,
      },
      'documents': {
        'localChanges': docsLocalUpdated,
        'remoteChanges': docsRemoteUpdated,
      },
      'lastSyncAt': lastSync,
    };
  }

  Future<void> _markSyncedNow() async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('app_prefs', {'key': 'lastSyncAt', 'value': now.toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Map<String, Object?> _clean(Map<String, Object?> m) {
    // Remove nulls for Firestore
    final out = <String, Object?>{};
    m.forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
  }

  String _collectionFor(String table) {
    // Simple 1:1 mapping for now
    return table;
  }

  Future<void> _pushTable(String table) async {
    final db = await _db;
    final since = await _lastSyncAt();
    // Check schema for updatedAt column; if missing, fallback to pushing all rows
    bool hasUpdatedAt = false;
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final cols = info.map((r) => (r['name'] as String?)?.toLowerCase() ?? '').toSet();
      hasUpdatedAt = cols.contains('updatedat');
    } catch (_) {}

    List<Map<String, Object?>> rows;
    if (!hasUpdatedAt || since <= 0) {
      rows = await db.rawQuery('SELECT * FROM ' + table);
    } else {
      rows = await db.rawQuery('SELECT * FROM ' + table + ' WHERE COALESCE(updatedAt, 0) > ?', [since]);
    }
    if (rows.isEmpty) return;
    final col = _fs.collection(_collectionFor(table));
    for (final r in rows) {
      final data = Map<String, Object?>.from(r);
      data['updatedAt'] = (data['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch) as Object?;
      final id = table == 'app_prefs' ? (r['key'] ?? '').toString() : (r['id'] ?? '').toString();
      if (id.isEmpty) continue;
      await col.doc(id).set(_clean(data), SetOptions(merge: true));
    }
  }

  Future<void> _pullTable(String table) async {
    final db = await _db;
    final since = await _lastSyncAt();
    final col = _fs.collection(_collectionFor(table));
    final qs = await col.where('updatedAt', isGreaterThan: since).get();
    // Fetch table columns to filter unknown fields
    Set<String> cols = {};
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      cols = info.map((r) => (r['name'] as String).toLowerCase()).toSet();
    } catch (_) {}

    for (final d in qs.docs) {
      final data = d.data();
      if (table == 'etudiants') {
        final del = data['isDeleted'];
        if (del == true || del == 1) {
          continue;
        }
      }
      final raw = Map<String, Object?>.from(data);
      if (table == 'app_prefs') {
        raw['key'] = d.id;
      } else {
        raw['id'] = d.id;
      }

      // Filter by existing columns and coerce bool → int, map/list → json string
      final toInsert = <String, Object?>{};
      raw.forEach((k, v) {
        final keyLower = k.toLowerCase();
        if (!cols.contains(keyLower)) return;
        toInsert[k] = _coerceSqlValue(v);
      });
      if (toInsert.isEmpty) continue;
      await db.insert(table, toInsert, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Object? _coerceSqlValue(Object? v) {
    if (v == null) return null;
    if (v is bool) return v ? 1 : 0;
    if (v is num || v is String || v is int || v is double) return v;
    if (v is Map || v is List) return jsonEncode(v);
    return v.toString();
  }

  Future<void> _pushDeletions() async {
    final db = await _db;
    final since = await _lastSyncAt();
    final rows = await db.query('deletions_log',
        columns: ['tableName', 'rowId', 'deletedAt'],
        where: 'deletedAt > ?', whereArgs: [since]);
    final idsToPurge = <Map<String, Object?>>[];
    for (final r in rows) {
      final table = r['tableName'] as String?;
      final id = r['rowId']?.toString();
      final deletedAt = int.tryParse(r['deletedAt']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch;
      if (table == null || id == null) continue;
      await _fs.collection(_collectionFor(table)).doc(id)
        .set({'isDeleted': 1, 'updatedAt': deletedAt}, SetOptions(merge: true));
      idsToPurge.add({'tableName': table, 'rowId': id, 'deletedAt': deletedAt});
    }
    // Purge processed deletions to keep the log small
    if (idsToPurge.isNotEmpty) {
      final db = await _db;
      final batch = db.batch();
      for (final item in idsToPurge) {
        batch.delete('deletions_log',
            where: 'tableName=? AND rowId=? AND deletedAt=?',
            whereArgs: [item['tableName'], item['rowId'], item['deletedAt']]);
      }
      await batch.commit(noResult: true);
    }
  }
}
