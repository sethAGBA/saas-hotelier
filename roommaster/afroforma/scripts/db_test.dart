import 'package:afroforma/screen/parametres/models.dart';

void main() {
  // Simulate DB row where numeric values may come back as int rather than double
  final Map<String, dynamic> row = {
    'name': 'Test Co',
    'address': 'Rue Test',
    'phone': '000',
    'email': 'test@example.com',
    'rccm': '',
    'nif': '',
    'website': '',
    'logoPath': '',
    'autoBackup': 0,
    'backupFrequency': 'Quotidienne',
    'retentionDays': 30,
    'exercice': '',
    'monnaie': 'FCFA',
    'planComptable': 'SYSCOHADA',
    'academic_year': '2024-2025',
    // Here SQLite may return an int for zero values
    'targetRevenue': 0,
    'directorName': 'Dir Test',
    'location': 'Ville Test',
  };

  try {
    final info = CompanyInfo.fromMap(row);
    print('CompanyInfo parsed successfully. targetRevenue type: ${info.targetRevenue.runtimeType}, value: ${info.targetRevenue}');
  } catch (e, st) {
    print('Error while parsing CompanyInfo: $e');
    print(st);
  }
}
