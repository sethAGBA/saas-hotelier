import 'package:flutter_test/flutter_test.dart';
import 'package:afroforma/services/database_service.dart';
import 'package:afroforma/models/formation.dart';
import 'package:afroforma/models/formateur.dart';
import 'package:afroforma/models/session.dart';

void main() {
  group('DatabaseService (in-memory)', () {
    final dbs = DatabaseService();

    setUpAll(() async {
      await dbs.init(useInMemory: true);
    });

    test('insert and read formation with children', () async {
      final f = Formation(
        id: 't1',
        title: 'Test Formation',
        description: 'desc',
        duration: '1 mois',
        price: 1000,
        imageUrl: '',
        category: 'IT',
        level: 'Débutant',
        formateurs: [Formateur(id: 'ft1', name: 'Alice', speciality: 'X', hourlyRate: 1000)],
  sessions: [Session(id: 's1', name: 'Test session', startDate: DateTime(2025,1,1), endDate: DateTime(2025,1,10), room: 'R1', maxCapacity: 10)],
      );

      await dbs.saveFormationTransaction(f);

      final loaded = await dbs.getFormations();
      expect(loaded.any((e) => e.id == 't1'), isTrue);
      final loadedF = loaded.firstWhere((e) => e.id == 't1');
      expect(loadedF.formateurs.length, 1);
      expect(loadedF.sessions.length, 1);
    });

    test('detect session conflict', () async {
      final conflict = await dbs.checkSessionConflict(
        formationId: 't1',
        startMs: DateTime(2025,1,5).millisecondsSinceEpoch,
        endMs: DateTime(2025,1,6).millisecondsSinceEpoch,
      );
      expect(conflict, isTrue);
    });

      test('hasConflict detects room or formateur overlap', () async {
        // Session 1: room R2, formateur ft2
  final s1 = Session(id: 's2', name: 'S2', startDate: DateTime(2025,2,1), endDate: DateTime(2025,2,10), room: 'R2', maxCapacity: 10, status: 'planned');
        // Session 2: room R2, formateur ft3, overlap
  final s2 = Session(id: 's3', name: 'S3', startDate: DateTime(2025,2,5), endDate: DateTime(2025,2,15), room: 'R2', maxCapacity: 10, status: 'planned');
        // Session 3: room R3, formateur ft2, overlap
  final s3 = Session(id: 's4', name: 'S4', startDate: DateTime(2025,2,5), endDate: DateTime(2025,2,15), room: 'R3', maxCapacity: 10, status: 'planned');

        // Insert sessions manually (simulate formateurId)
        final db = await dbs.db;
        await db.insert('sessions', {
          'id': s1.id,
          'formationId': 't1',
          'startDate': s1.startDate.millisecondsSinceEpoch,
          'endDate': s1.endDate.millisecondsSinceEpoch,
          'room': s1.room,
          'formateurId': 'ft2',
          'maxCapacity': s1.maxCapacity,
          'currentEnrollments': s1.currentEnrollments,
          'status': s1.status,
          'isArchived': 0,
        });
        await db.insert('sessions', {
          'id': s2.id,
          'formationId': 't1',
          'startDate': s2.startDate.millisecondsSinceEpoch,
          'endDate': s2.endDate.millisecondsSinceEpoch,
          'room': s2.room,
          'formateurId': 'ft3',
          'maxCapacity': s2.maxCapacity,
          'currentEnrollments': s2.currentEnrollments,
          'status': s2.status,
          'isArchived': 0,
        });
        await db.insert('sessions', {
          'id': s3.id,
          'formationId': 't1',
          'startDate': s3.startDate.millisecondsSinceEpoch,
          'endDate': s3.endDate.millisecondsSinceEpoch,
          'room': s3.room,
          'formateurId': 'ft2',
          'maxCapacity': s3.maxCapacity,
          'currentEnrollments': s3.currentEnrollments,
          'status': s3.status,
          'isArchived': 0,
        });

        // Test: overlap by room
        final conflictRoom = await dbs.hasConflict(
          room: 'R2',
          formateurId: 'ftX',
          startMs: DateTime(2025,2,6).millisecondsSinceEpoch,
          endMs: DateTime(2025,2,8).millisecondsSinceEpoch,
        );
        expect(conflictRoom, isTrue);

        // Test: overlap by formateur
        final conflictFormateur = await dbs.hasConflict(
          room: 'R9',
          formateurId: 'ft2',
          startMs: DateTime(2025,2,6).millisecondsSinceEpoch,
          endMs: DateTime(2025,2,8).millisecondsSinceEpoch,
        );
        expect(conflictFormateur, isTrue);

        // Test: no conflict
        final noConflict = await dbs.hasConflict(
          room: 'R9',
          formateurId: 'ft9',
          startMs: DateTime(2025,3,1).millisecondsSinceEpoch,
          endMs: DateTime(2025,3,10).millisecondsSinceEpoch,
        );
        expect(noConflict, isFalse);
      });
  });
}
