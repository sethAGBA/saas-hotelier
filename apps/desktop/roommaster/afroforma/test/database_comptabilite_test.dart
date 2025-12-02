import 'package:flutter_test/flutter_test.dart';
import 'package:afroforma/services/database_service.dart';

void main() {
  setUp(() async {
    await DatabaseService().init(useInMemory: true);
  });

  tearDown(() async {
    await DatabaseService().close();
  });

  test('hasChildAccounts detects children', () async {
    final db = DatabaseService();
    // insert parent and child
    await db.insertCompte({'id': 'p1', 'code': '900', 'title': 'Parent'});
    await db.insertCompte({'id': 'c1', 'code': '901', 'title': 'Child', 'parentId': 'p1'});

    final has = await db.hasChildAccounts('p1');
    expect(has, isTrue);
  });

  test('countEcrituresForAccountCode returns correct count', () async {
    final db = DatabaseService();
    // ensure account exists
    await db.insertCompte({'id': 'a1', 'code': '400', 'title': 'Clients'});
    // insert ecritures linked to account code
    await db.insertEcriture({'id': 'e1', 'pieceId': 'p1', 'pieceNumber': '1', 'date': DateTime.now().millisecondsSinceEpoch, 'journalId': 'j1', 'reference': '', 'accountCode': '400', 'label': 'Sale', 'debit': 100.0, 'credit': 0.0, 'lettrageId': null, 'createdAt': DateTime.now().millisecondsSinceEpoch});
    await db.insertEcriture({'id': 'e2', 'pieceId': 'p2', 'pieceNumber': '2', 'date': DateTime.now().millisecondsSinceEpoch, 'journalId': 'j1', 'reference': '', 'accountCode': '400', 'label': 'Sale2', 'debit': 50.0, 'credit': 0.0, 'lettrageId': null, 'createdAt': DateTime.now().millisecondsSinceEpoch});

    final cnt = await db.countEcrituresForAccountCode('400');
    expect(cnt, equals(2));
  });

  test('deleteCompteCascade removes descendants and clears ecritures accountCode', () async {
    final db = DatabaseService();
    // build tree parent->child->grandchild
    await db.insertCompte({'id': 'p', 'code': '100', 'title': 'P'});
    await db.insertCompte({'id': 'c', 'code': '110', 'title': 'C', 'parentId': 'p'});
    await db.insertCompte({'id': 'g', 'code': '111', 'title': 'G', 'parentId': 'c'});

    // insert ecritures referencing child and grandchild codes
    await db.insertEcriture({'id': 'e_child', 'pieceId': 'px', 'pieceNumber': '1', 'date': DateTime.now().millisecondsSinceEpoch, 'journalId': 'j', 'reference': '', 'accountCode': '110', 'label': 'L1', 'debit': 10.0, 'credit': 0.0, 'lettrageId': null, 'createdAt': DateTime.now().millisecondsSinceEpoch});
    await db.insertEcriture({'id': 'e_grand', 'pieceId': 'py', 'pieceNumber': '2', 'date': DateTime.now().millisecondsSinceEpoch, 'journalId': 'j', 'reference': '', 'accountCode': '111', 'label': 'L2', 'debit': 20.0, 'credit': 0.0, 'lettrageId': null, 'createdAt': DateTime.now().millisecondsSinceEpoch});

    // perform cascade delete on parent
    await db.deleteCompteCascade('p');

    // descendants should be gone
    final plan = await db.getPlanComptable();
    final ids = plan.map((r) => r['id'] as String).toSet();
    expect(ids.contains('p'), isFalse);
    expect(ids.contains('c'), isFalse);
    expect(ids.contains('g'), isFalse);

    // ecritures should have accountCode cleared
    final e = await db.getEcritures();
    final accCodes = e.map((r) => r['accountCode']).toSet();
    expect(accCodes.contains('110'), isFalse);
    expect(accCodes.contains('111'), isFalse);
  });
}
