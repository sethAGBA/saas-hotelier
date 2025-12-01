import 'package:afroforma/services/database_service.dart';
import 'package:afroforma/models/document.dart';

Future<void> main() async {
  print('Starting db_insert_test');
  final dbs = DatabaseService();
  try {
    await dbs.init(useInMemory: true);
    print('DB initialized in memory');

    final doc = Document(
      id: 'doc-test-1',
      formationId: 'f1',
      fileName: 'test.pdf',
      path: '/tmp/test.pdf',
      certificateNumber: 'CERT-123',
      validationUrl: 'https://example.com/verify/CERT-123',
      qrcodeData: 'CERT-123',
    );

    await dbs.insertDocument(doc);
    print('Inserted document successfully');

    final fetched = await dbs.getDocumentByCertificateNumber('CERT-123');
    print('Fetched by certificateNumber: ${fetched?.id} ${fetched?.certificateNumber}');
  } catch (e, st) {
    print('Error during DB insert test: $e');
    print(st);
  } finally {
    try {
      await dbs.close();
    } catch (_) {}
  }
}
