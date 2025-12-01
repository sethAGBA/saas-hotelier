import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import '../models/course.dart';
import '../models/document.dart';
import '../models/certificate.dart';
import '../models/student.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Course>> getCourses() async {
    try {
      final snapshot = await _db.collection('courses').get();
      final courses = snapshot.docs.map((doc) {
        return Course.fromMap(doc.id, doc.data());
      }).toList();
      return courses;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Document>> getDocuments(String courseId) async {
    try {
      final snapshot = await _db.collection('courses').doc(courseId).collection('documents').get();
      final documents = snapshot.docs.map((doc) {
        final data = doc.data();
        return Document(
          id: doc.id,
          name: data['name'] ?? '',
          url: data['url'] ?? '',
        );
      }).toList();
      return documents;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Certificate>> getCertificates(String courseId) async {
    try {
      final snapshot = await _db.collection('courses').doc(courseId).collection('certificates').get();
      final certificates = snapshot.docs.map((doc) {
        final data = doc.data();
        return Certificate(
          id: doc.id,
          name: data['name'] ?? '',
          url: data['url'] ?? '',
        );
      }).toList();
      return certificates;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<Student?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Student(
          uid: uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
        );
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<List<Student>> getAllUsers() async {
    try {
      final usersSnapshot = await _db.collection('users').get();
      final users = usersSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return Student(
              uid: doc.id,
              name: data['name'] ?? 'Utilisateur inconnu',
              email: data['email'] ?? 'Email inconnu',
            );
          })
          .toList();
          
      return users;
    } catch (e) {
      print('getAllUsers error: $e');
      return [];
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document from 'users' collection
      await _db.collection('users').doc(uid).delete();

      // Note: This only deletes the user's Firestore document.
      // To fully delete the user (including their Firebase Authentication record),
      // you would typically use Firebase Admin SDK on a backend (e.g., Cloud Functions).
      // Deleting subcollections (like 'messages' or 'courses' under a user)
      // would also need to be handled here if they exist and are not automatically
      // deleted by Firestore rules or Cloud Functions.
    } catch (e) {
      print('deleteUser error: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String uid, String name) async {
    try {
      await _db.collection('users').doc(uid).update({'name': name});
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateUserEmail(String uid, String email) async {
    try {
      await _db.collection('users').doc(uid).update({'email': email});
    } catch (e) {
      print(e);
    }
  }

  /// Find a user's UID by exact email match in the `users` collection.
  /// Returns null if no user is found.
  Future<String?> getUidByEmail(String email) async {
    try {
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.id;
    } catch (e) {
      print('getUidByEmail error: $e');
      return null;
    }
  }

  /// Send a data payload (e.g. announcement) to every user by creating a
  /// document inside users/{uid}/messages. The payload will be complemented
  /// with a server timestamp under `sentAt`.
  Future<void> sendDataToAllUsers(Map<String, dynamic> data) async {
    try {
      final snapshot = await _db.collection('users').get();
      final futures = snapshot.docs.map((doc) {
        return _db
            .collection('users')
            .doc(doc.id)
            .collection('messages')
            .add({
          ...data,
          'sentAt': FieldValue.serverTimestamp(),
        });
      }).toList();
      await Future.wait(futures);
    } catch (e) {
      print('sendDataToAllUsers error: $e');
      rethrow;
    }
  }

  /// Returns true when the user document contains an `isAdmin: true` flag
  /// or a `role: 'admin'` field. Safe to call for non-existing docs.
  Future<bool> isAdmin(String uid) async {
    try {
      // First check dedicated admins collection
      final adminDoc = await _db.collection('admins').doc(uid).get();
      if (adminDoc.exists) return true;

      // Fallback: check users collection for legacy flags
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;
      if (data['isAdmin'] == true) return true;
      if (data['role'] != null && data['role'].toString().toLowerCase() == 'admin') return true;
    } catch (e) {
      print('isAdmin check error: $e');
    }
    return false;
  }

  /// Add a user to the `admins` collection. `data` can contain metadata like
  /// name, email, createdBy, etc. The document id will be the admin user's uid.
  Future<void> addAdmin(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('admins').doc(uid).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('addAdmin error: $e');
      rethrow;
    }
  }

  /// Remove a user from the `admins` collection.
  Future<void> removeAdmin(String uid) async {
    try {
      await _db.collection('admins').doc(uid).delete();
    } catch (e) {
      print('removeAdmin error: $e');
      rethrow;
    }
  }

  /// List admin uids (and optional metadata) from the `admins` collection.
  Future<List<Map<String, dynamic>>> listAdmins() async {
    try {
      final snap = await _db.collection('admins').get();
  return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
    } catch (e) {
      print('listAdmins error: $e');
      return [];
    }
  }

  /// Create a new course and return its generated id.
  /// Create a new course and optionally add documents and resources.
  ///
  /// `documents` and `resources` are lists of maps with keys 'name' and 'url'.
  Future<String?> createCourse(String name, String description, {List<Map<String, String>> documents = const [], List<Map<String, String>> resources = const []}) async {
    try {
      final ref = await _db.collection('courses').add({
        'name': name,
        'description': description,
        'resources': resources, // Add resources directly
        'isArchived': false, // Set isArchived to false by default
        'createdAt': FieldValue.serverTimestamp(),
      });

      // write documents as subcollection
      for (final doc in documents) {
        await _db.collection('courses').doc(ref.id).collection('documents').add({
          'name': doc['name'] ?? '',
          'url': doc['url'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return ref.id;
    } catch (e) {
      print('createCourse error: $e');
      return null;
    }
  }

  Future<void> updateCourse(String courseId, String name, String description, {List<Map<String, String>>? resources}) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (resources != null) {
        updateData['resources'] = resources;
      }
      await _db.collection('courses').doc(courseId).update(updateData);
    } catch (e) {
      print('updateCourse error: $e');
      rethrow;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      // Delete subcollection 'documents'
      final documentsSnapshot = await _db.collection('courses').doc(courseId).collection('documents').get();
      for (final doc in documentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete subcollection 'certificates'
      final certificatesSnapshot = await _db.collection('courses').doc(courseId).collection('certificates').get();
      for (final doc in certificatesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete subcollection 'enrollments'
      final enrollmentsSnapshot = await _db.collection('courses').doc(courseId).collection('enrollments').get();
      for (final doc in enrollmentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Finally, delete the course document itself
      await _db.collection('courses').doc(courseId).delete();
    } catch (e) {
      print('deleteCourse error: $e');
      rethrow;
    }
  }

  Future<void> archiveCourse(String courseId) async {
    try {
      await _db.collection('courses').doc(courseId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('archiveCourse error: $e');
      rethrow;
    }
  }

  /// Returns pending enrollment requests for a course (subcollection 'enrollments').
  Future<List<Map<String, dynamic>>> getPendingEnrollments(String courseId) async {
    try {
      final snap = await _db.collection('courses').doc(courseId).collection('enrollments').where('status', isEqualTo: 'pending').get();
      
      final studentFutures = snap.docs.map((enrollmentDoc) async {
        final enrollmentData = enrollmentDoc.data();
        final uid = enrollmentDoc.id; // The doc ID is now the UID

        try {
          final userDoc = await _db.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            return {
              'uid': uid,
              ...enrollmentData,
              'name': userData['name'] ?? enrollmentData['name'],
              'email': userData['email'] ?? enrollmentData['email'],
            };
          }
        } catch (e) {
          // if user doc fails, fall back to enrollment data
          print('Error fetching user $uid for pending enrollment: $e');
        }
        
        return {'uid': uid, ...enrollmentData};
      }).toList();

      return await Future.wait(studentFutures);
    } catch (e) {
      print('getPendingEnrollments error: $e');
      return [];
    }
  }

  /// Approve an enrollment request for a given user UID.
  Future<void> approveEnrollment(String courseId, String uid) async {
    try {
      final docRef = _db.collection('courses').doc(courseId).collection('enrollments').doc(uid);
      await docRef.update({'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()});

      // Add a reference in users/{uid}/courses for quick lookup
      await _db.collection('users').doc(uid).collection('courses').doc(courseId).set({'enrolledAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('approveEnrollment error: $e');
      rethrow;
    }
  }

  /// Reject an enrollment request for a given user UID.
  Future<void> rejectEnrollment(String courseId, String uid) async {
    try {
      final docRef = _db.collection('courses').doc(courseId).collection('enrollments').doc(uid);
      await docRef.update({'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('rejectEnrollment error: $e');
      rethrow;
    }
  }

  /// Revoke a user's enrollment from a course.
  Future<void> revokeEnrollment(String courseId, String uid) async {
    try {
      // Remove from enrollments subcollection
      await _db.collection('courses').doc(courseId).collection('enrollments').doc(uid).delete();
      // Remove from user's course list
      await _db.collection('users').doc(uid).collection('courses').doc(courseId).delete();
    } catch (e) {
      print('revokeEnrollment error: $e');
      rethrow;
    }
  }

  // ------------------ Formations sync helpers ------------------
  /// Upsert a formation document to top-level `formations` collection
  Future<void> upsertFormation(Map<String, dynamic> formation) async {
    try {
      final id = formation['id']?.toString() ?? _db.collection('formations').doc().id;
      final payload = Map<String, dynamic>.from(formation);
      // Convert DateTime to server timestamp or millis if present
      if (payload['updatedAt'] is DateTime) {
        payload['updatedAt'] = (payload['updatedAt'] as DateTime).millisecondsSinceEpoch;
      }
      await _db.collection('formations').doc(id).set(payload, SetOptions(merge: true));
    } catch (e) {
      print('upsertFormation error: $e');
      rethrow;
    }
  }

  /// Fetch formations updated since a given DateTime (or all if null).
  /// Returns a List of maps with `id` included and `updatedAt` converted to DateTime when possible.
  Future<List<Map<String, dynamic>>> fetchFormationsUpdatedSince(DateTime? since) async {
    try {
      Query q = _db.collection('formations');
      if (since != null) {
        q = q.where('updatedAt', isGreaterThan: since.millisecondsSinceEpoch);
      }
      final snap = await q.get();
      return snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data() as Map<String, dynamic>);
        data['id'] = d.id;
        final ua = data['updatedAt'];
        if (ua is int) data['updatedAt'] = DateTime.fromMillisecondsSinceEpoch(ua);
        return data;
      }).toList();
    } catch (e) {
      print('fetchFormationsUpdatedSince error: $e');
      return [];
    }
  }

  /// Manually enroll a student in a course, bypassing the request process.
  Future<void> forceEnrollStudent(String courseId, String uid) async {
    try {
      final studentDoc = await _db.collection('users').doc(uid).get();
      if (!studentDoc.exists) {
        throw Exception('Aucun étudiant trouvé avec l\'UID: $uid');
      }
      final studentData = studentDoc.data()!;

      // Create or update the enrollment document to approved status
      await _db.collection('courses').doc(courseId).collection('enrollments').doc(uid).set({
        'uid': uid,
        'name': studentData['name'] ?? 'Utilisateur inconnu',
        'email': studentData['email'] ?? 'Email inconnu',
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'enrolledByAdmin': true,
      }, SetOptions(merge: true));

      // Also add to the user's own course list for their convenience
      await _db.collection('users').doc(uid).collection('courses').doc(courseId).set({
        'enrolledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('forceEnrollStudent error: $e');
      rethrow;
    }
  }

  /// List approved/enrolled students for a course.
  Future<List<Map<String, dynamic>>> listEnrolledStudents(String courseId) async {
    try {
      final snap = await _db.collection('courses').doc(courseId).collection('enrollments').where('status', isEqualTo: 'approved').get();
      
      final studentFutures = snap.docs.map((enrollmentDoc) async {
        final enrollmentData = enrollmentDoc.data();
        final uid = enrollmentDoc.id; // The doc ID is now the UID

        try {
          final userDoc = await _db.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            return {
              'uid': uid,
              ...enrollmentData,
              'name': userData['name'] ?? enrollmentData['name'],
              'email': userData['email'] ?? enrollmentData['email'],
            };
          }
        } catch (e) {
          // if user doc fails, fall back to enrollment data
          print('Error fetching user $uid: $e');
        }
        
        return {'uid': uid, ...enrollmentData};
      }).toList();

      return await Future.wait(studentFutures);
    } catch (e) {
      print('listEnrolledStudents error: $e');
      return [];
    }
  }

  /// Send an individual message to a user.
  Future<void> sendIndividualMessage(String recipientUid, String title, String body, List<Map<String, String>> attachments) async {
    try {
      await _db.collection('users').doc(recipientUid).collection('messages').add({
        'title': title,
        'body': body,
        'attachments': attachments,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('sendIndividualMessage error: $e');
      rethrow;
    }
  }

  /// Send a payload to all approved students of a course by creating a message in each user's messages subcollection.
  Future<void> sendDataToCourseUsers(String courseId, Map<String, dynamic> data) async {
    try {
      final snap = await _db.collection('courses').doc(courseId).collection('enrollments').where('status', isEqualTo: 'approved').get();
      final futures = snap.docs.map((d) {
        final uid = d.id; // UID is the document ID
        return _db.collection('users').doc(uid).collection('messages').add({
          ...data,
          'sentAt': FieldValue.serverTimestamp(),
        });
      }).toList();
      await Future.wait(futures);
    } catch (e) {
      print('sendDataToCourseUsers error: $e');
      rethrow;
    }
  }

  /// Create a new enrollment request for the current user, using the UID as the document ID.
  Future<void> requestEnrollment(String courseId, String uid, String email, String name) async {
    try {
      await _db.collection('courses').doc(courseId).collection('enrollments').doc(uid).set({
        'uid': uid, // Keep uid in the doc for easier queries if needed
        'email': email,
        'name': name,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('requestEnrollment error: $e');
      rethrow;
    }
  }

  /// Get the enrollment status for a user in a course.
  /// Returns 'enrolled', 'pending', 'rejected', or 'none'.
  Future<String> getEnrollmentStatus(String courseId, String uid) async {
    try {
      final doc = await _db.collection('courses').doc(courseId).collection('enrollments').doc(uid).get();
      if (!doc.exists) {
        return 'none';
      }
      final status = doc.data()?['status'] as String?;
      if (status == 'approved') return 'enrolled';
      return status ?? 'none';
    } catch (e) {
      print('getEnrollmentStatus error: $e');
      return 'none';
    }
  }

  Stream<int> getPendingEnrollmentCount() {
    try {
      final stream = _db.collectionGroup('enrollments')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .handleError((err) {
            print('getPendingEnrollmentCount: Firestore stream error: $err');
          })
          .map((snapshot) => snapshot.docs.length);

      return stream;
    } catch (e) {
      print('getPendingEnrollmentCount: exception when creating stream: $e');
      return Stream.value(0);
    }
  }

  Future<Map<String, dynamic>?> getLatestUpdateInfo() async {
    try {
      final doc = await _db.collection('app_settings').doc('update_info').get();
      if (doc.exists) {
        final data = doc.data();
        print('FirestoreService.getLatestUpdateInfo: found document app_settings/update_info -> $data');
        return data;
      } else {
        print('FirestoreService.getLatestUpdateInfo: no document app_settings/update_info found');
      }
    } catch (e) {
      print('Error getting update info: $e');
    }
    return null;
  }

  /// Enhanced: try app_settings/update_info first; if it doesn't contain a
  /// download URL for the current platform, fall back to querying the
  /// `app_updates` collection for a platform-specific document.
  Future<Map<String, dynamic>?> getLatestUpdateInfoWithFallback() async {
    try {
      final base = await getLatestUpdateInfo();
      String platformKey;
      if (Platform.isAndroid) {
        platformKey = 'android';
      } else if (Platform.isWindows) {
        platformKey = 'windows';
      } else if (Platform.isMacOS) {
        platformKey = 'macos';
      } else if (Platform.isLinux) {
        platformKey = 'linux';
      } else if (Platform.isIOS) {
        platformKey = 'ios';
      } else {
        platformKey = 'other';
      }

      print('FirestoreService.getLatestUpdateInfoWithFallback: platformKey=$platformKey, base=$base');

      // If base exists, be defensive: normalize keys (trim + lowercase) to find
      // version and download_urls even if there are small key name variations.
      if (base != null) {
        final normalized = <String, dynamic>{};
        base.forEach((k, v) {
          final nk = (k.toString()).trim().toLowerCase();
          normalized[nk] = v;
        });
        final dl = normalized['download_urls'] ?? normalized['downloadurls'] ?? normalized['download-urls'];
        final bv = normalized['latest_version'] ?? normalized['version'] ?? normalized['latestversion'];
        print('FirestoreService.getLatestUpdateInfoWithFallback: normalized base keys -> version=$bv, download_urls=$dl');
        if (dl is Map && dl.containsKey(platformKey) && (dl[platformKey] ?? '').toString().isNotEmpty) {
          print('FirestoreService.getLatestUpdateInfoWithFallback: using normalized base download_urls for $platformKey');
          // Recompose a result map with normalized keys to match main.dart expectations
          final out = <String, dynamic>{};
          out['latest_version'] = bv ?? '';
          out['download_urls'] = dl;
          return out;
        }
      }

      // Fallback: query app_updates collection for a platform-specific document.
      // Avoid orderBy to prevent composite index requirement; we simply limit(1).
      final snap = await _db
          .collection('app_updates')
          .where('platform', isEqualTo: platformKey)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        print('FirestoreService.getLatestUpdateInfoWithFallback: found app_updates doc -> $d');
        // Normalize into the shape main.dart expects: { 'latest_version': ..., 'download_urls': {platform: url}, ... }
        final Map<String, dynamic> out = {};
        if (d.containsKey('version')) out['latest_version'] = d['version'];
        final url = (d['url'] ?? d['download_url'] ?? '') as String;
        out['download_urls'] = {platformKey: url};
        if (d.containsKey('notes')) out['notes'] = d['notes'];
        return out;
      } else {
        print('FirestoreService.getLatestUpdateInfoWithFallback: no app_updates document found for platform $platformKey');
      }
    } catch (e) {
      print('getLatestUpdateInfoWithFallback error: $e');
    }
    return null;
  }
}
