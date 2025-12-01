import 'package:afroforma/models/document.dart';
import 'package:afroforma/models/formation.dart';
import 'package:afroforma/models/inscription.dart';
import 'package:afroforma/models/session.dart';
import 'package:afroforma/models/student.dart';
import 'package:afroforma/screen/parametres/models.dart';

abstract class IDatabaseService {
  Future<void> init();

  // Student CRUD
  Future<List<Student>> getStudents();
  Future<Student?> getStudentById(String id);
  Future<void> insertStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String id);

  // Formation
  Future<List<Formation>> getFormations();

  // Communication
  Future<void> insertCommunication(Map<String, Object?> m);

  // Document Templates
  Future<List<DocumentTemplate>> getDocumentTemplates();

  // Company Info
  Future<CompanyInfo?> getCompanyInfo();

  // Document
  Future<void> insertDocument(Document doc);
  Future<void> updateDocument(Map<String, Object?> m);
  Future<void> deleteDocument(String id);
  Future<List<Document>> getDocumentsByStudent(String studentId);

  // Inscription
  Future<void> updateInscriptionEvaluation(
      {required String inscriptionId, required String status, double? finalGrade, String? appreciation});
  Future<List<Inscription>> getInscriptionsForStudent(String studentId);
  Future<void> updateInscriptionCertificate(String inscriptionId, String certificatePath);
  Future<void> updateInscriptionStatus(String inscriptionId, String status);
  Future<void> addInscription(Map<String, Object?> inscriptionData);

  // Payment
  Future<List<Map<String, Object?>>> getPaymentsByStudent(String? studentId, {String? inscriptionId});
  Future<void> insertPayment(Map<String, Object?> m);

  // Session
  Future<List<Session>> getSessionsForFormation(String formationId);
}