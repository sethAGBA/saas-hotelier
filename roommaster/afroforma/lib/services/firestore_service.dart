
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:afroforma/models/student.dart';
// import 'database_interface.dart';

// class FirestoreService implements IDatabaseService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   @override
//   Future<void> init() async {
//     // Firestore is initialized via Firebase.initializeApp() in main.dart
//     // No specific initialization needed here.
//   }

//   @override
//   Future<void> deleteStudent(String id) {
//     return _db.collection('etudiants').doc(id).delete();
//   }

//   @override
//   Future<Student?> getStudentById(String id) async {
//     final doc = await _db.collection('etudiants').doc(id).get();
//     if (!doc.exists) return null;
//     return Student.fromMap(doc.data()!);
//   }

//   @override
//   Future<List<Student>> getStudents() async {
//     final snapshot = await _db.collection('etudiants').get();
//     return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
//   }

//   @override
//   Future<void> insertStudent(Student student) {
//     return _db.collection('etudiants').doc(student.id).set(student.toMap());
//   }

//   @override
//   Future<void> updateStudent(Student student) {
//     return _db.collection('etudiants').doc(student.id).update(student.toMap());
//   }
// }
