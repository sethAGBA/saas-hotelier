import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart' as cf;
import 'package:k_empire/models/student.dart';
import 'package:k_empire/screens/admin_chat_history_screen.dart';
import 'package:k_empire/screens/pending_enrollments_screen.dart';
import '../models/document.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

// Modèle pour gérer les uploads en file d'attente
class QueuedUpload {
  final File file;
  final String fileName;
  final int? docIndex;
  UploadTask? task;
  double progress = 0.0;
  UploadStatus status = UploadStatus.queued;

  QueuedUpload(this.file, this.fileName, {this.docIndex});
}

enum UploadStatus { queued, uploading, done, failed, canceled }

class AdminScreen extends StatefulWidget {
  final int? initialTabIndex;
  const AdminScreen({Key? key, this.initialTabIndex}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  // Controllers
  final _courseNameController = TextEditingController();
  final _courseDescController = TextEditingController();

  // Tab Controllers
  late TabController _mainTabController;
  late TabController _enrollmentsTabController;

  // State variables
  bool _isLoading = false;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _pendingEnrollments = [];
  List<Map<String, dynamic>> _enrolledStudents = [];
  List<Student> _users = [];
  String? _selectedCourseId;
  int _globalPendingEnrollmentCount = 0; // New state variable
  StreamSubscription? _globalEnrollmentCountSubscription; // New subscription variable

  // Course creation data
  final List<Map<String, String>> _courseResources = [];
  final List<Map<String, String>> _courseDocuments = [];
  final List<Map<String, TextEditingController>> _resourceItemControllers = [];

  // Upload queue
  final List<QueuedUpload> _uploadQueue = [];
  bool _isProcessingQueue = false;

  String _safeInitial(String? s, {String fallback = 'A'}) {
    final v = (s ?? '').trim();
    if (v.isEmpty) return fallback;
    return v.substring(0, 1).toUpperCase();
  }

  // Sanitize file names to avoid problematic characters in Storage paths
  String _safeFileName(String name) {
    // Replace spaces with underscores
    var n = name.replaceAll(RegExp(r"\s+"), "_");
    // Remove any path separators just in case
    n = n.replaceAll(RegExp(r"[\\/]+"), "_");
    // Remove characters other than letters, numbers, dot, dash and underscore
    n = n.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), "");
    // Prevent empty name
    if (n.isEmpty) n = "file";
    return n;
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex ?? 0);
    _enrollmentsTabController = TabController(length: 2, vsync: this);
    _initializeData();
    _listenToGlobalPendingEnrollments(); // New method call
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _enrollmentsTabController.dispose();
    _courseNameController.dispose();
    _courseDescController.dispose();
    _globalEnrollmentCountSubscription?.cancel(); // Cancel subscription
    super.dispose();
  }

  // === INITIALIZATION ===
  Future<void> _initializeData() async {
    await Future.wait([
      _loadAdmins(),
      _loadCourses(),
      _loadUsers(),
    ]);
  }

  // === DATALOADING METHODS ===
  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final admins = await _firestoreService.listAdmins();
      if (mounted) {
        setState(() => _admins = admins);
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des administrateurs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _firestoreService.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses
              .map((c) => {
                    'id': c.id,
                    'name': c.name,
                    'description': c.description
                  })
              .toList();
        });
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des cours: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _firestoreService.getAllUsers();
      if (mounted) {
        setState(() => _users = users);
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des utilisateurs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEnrollmentData(String courseId) async {
    setState(() {
      _isLoading = true;
      _selectedCourseId = courseId;
    });
    try {
      final pending = _firestoreService.getPendingEnrollments(courseId);
      final enrolled = _firestoreService.listEnrolledStudents(courseId);
      final results = await Future.wait([pending, enrolled]);
      if (mounted) {
        setState(() {
          _pendingEnrollments = results[0];
          _enrolledStudents = results[1];
        });
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des inscriptions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToGlobalPendingEnrollments() {
    _globalEnrollmentCountSubscription = _firestoreService.getPendingEnrollmentCount().listen((count) {
      if (mounted) {
        setState(() {
          _globalPendingEnrollmentCount = count;
        });
      }
    });
  }

  // === USER SELECTION DIALOG ===
  void _showUserSelectionDialog({
    required String title,
    required String actionText,
    required Function(Student) onSelect,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return _UserSelectionDialog(
          users: _users,
          title: title,
          actionText: actionText,
          onSelect: onSelect,
        );
      },
    );
  }

  // === ADMIN MANAGEMENT ===
  void _showAdminPromotionDialog() {
    _showUserSelectionDialog(
      title: 'Promouvoir un administrateur',
      actionText: 'Promouvoir',
      onSelect: (student) {
        _addAdminByEmail(student.email);
      },
    );
  }

  Future<void> _addAdminByEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar('Email invalide');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? uid;
      String name = '';

      // Try Cloud Function first
      try {
        final callable = cf.FirebaseFunctions.instance.httpsCallable('getUserByEmail');
        final result = await callable.call({'email': email});
        uid = result.data['uid'] as String?;
        name = (result.data['name'] as String?) ?? '';
      } catch (e) {
        // Fallback to Firestore query
        uid = await _firestoreService.getUidByEmail(email);
      }

      if (uid == null) {
        throw Exception('Aucun utilisateur trouvé pour cet email.');
      }

      await _firestoreService.addAdmin(uid, {'name': name, 'email': email});
      await _loadAdmins();
      _showSuccessSnackbar('Administrateur ajouté avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'ajout: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAdmin(String uid) async {
    setState(() => _isLoading = true);
    try {
      await _attemptRemoveAdminWithCloudFunction(uid);
      await _loadAdmins();
      _showSuccessSnackbar('Administrateur retiré avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la suppression: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _attemptRemoveAdminWithCloudFunction(String uid) async {
    try {
      final callable = cf.FirebaseFunctions.instance.httpsCallable('demoteAdmin');
      await callable.call({'uid': uid});
    } catch (_) {
      await _firestoreService.removeAdmin(uid);
    }
  }

  // === COURSE MANAGEMENT ===
  Future<void> _createCourse() async {
    final name = _courseNameController.text.trim();
    final description = _courseDescController.text.trim();

    if (name.isEmpty) {
      _showErrorSnackbar('Veuillez saisir un nom de cours');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestoreService.createCourse(
        name,
        description,
        documents: _courseDocuments,
        resources: _courseResources,
      );
      _clearCourseForm();
      await _loadCourses();
      _showSuccessSnackbar('Cours créé avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la création du cours: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce cours ? Cette action est irréversible et supprimera toutes les données associées (inscriptions, documents, ressources).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteCourse(courseId);
        await _loadCourses();
        _showSuccessSnackbar('Cours supprimé avec succès');
      } catch (e) {
        _showErrorSnackbar('Erreur lors de la suppression du cours: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _archiveCourse(String courseId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'archivage'),
        content: const Text('Êtes-vous sûr de vouloir archiver ce cours ? Il ne sera plus visible pour les étudiants.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.archiveCourse(courseId);
        await _loadCourses();
        _showSuccessSnackbar('Cours archivé avec succès');
      } catch (e) {
        _showErrorSnackbar('Erreur lors de l\'archivage du cours: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // === ENROLLMENT MANAGEMENT ===
  void _showAddStudentDialog() {
    if (_selectedCourseId == null) {
      _showErrorSnackbar('Veuillez d\'abord sélectionner un cours.');
      return;
    }
    _showUserSelectionDialog(
      title: 'Inscrire un étudiant au cours',
      actionText: 'Inscrire',
      onSelect: (student) {
        _forceEnrollStudentByEmail(student.email);
      },
    );
  }

  Future<void> _approveEnrollment(String uid) async {
    if (_selectedCourseId == null) return;

    try {
      await _firestoreService.approveEnrollment(_selectedCourseId!, uid);
      await _loadEnrollmentData(_selectedCourseId!);
      _showSuccessSnackbar('Inscription approuvée');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'approbation: $e');
    }
  }

  Future<void> _rejectEnrollment(String uid) async {
    if (_selectedCourseId == null) return;

    try {
      await _firestoreService.rejectEnrollment(_selectedCourseId!, uid);
      await _loadEnrollmentData(_selectedCourseId!);
      _showSuccessSnackbar('Inscription rejetée');
    } catch (e) {
      _showErrorSnackbar('Erreur lors du rejet: $e');
    }
  }

  Future<void> _revokeEnrollment(String uid) async {
    if (_selectedCourseId == null) return;

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la révocation'),
        content: const Text('Êtes-vous sûr de vouloir révoquer l\'accès de cet étudiant au cours ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.revokeEnrollment(_selectedCourseId!, uid);
        await _loadEnrollmentData(_selectedCourseId!);
        _showSuccessSnackbar('Accès révoqué avec succès');
      } catch (e) {
        _showErrorSnackbar('Erreur lors de la révocation: $e');
      }
    }
  }

  Future<void> _forceEnrollStudentByEmail(String email) async {
    if (_selectedCourseId == null) {
      _showErrorSnackbar('Veuillez d\'abord sélectionner un cours.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar('Veuillez saisir un email valide.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? uid;
      // Try Cloud Function first, fallback to Firestore
      try {
        final callable = cf.FirebaseFunctions.instance.httpsCallable('getUserByEmail');
        final result = await callable.call({'email': email});
        uid = result.data['uid'] as String?;
      } catch (e) {
        uid = await _firestoreService.getUidByEmail(email);
      }

      if (uid == null) {
        throw Exception('Aucun utilisateur trouvé pour cet email.');
      }

      await _firestoreService.forceEnrollStudent(_selectedCourseId!, uid);
      await _loadEnrollmentData(_selectedCourseId!);
      _showSuccessSnackbar('Étudiant inscrit avec succès.');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'inscription: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // === FILE UPLOAD MANAGEMENT ===
  QueuedUpload? _findQueueForIndex(int? index) {
    return _uploadQueue.cast<QueuedUpload?>().firstWhere(
      (q) => q?.docIndex == index,
      orElse: () => null,
    );
  }

  Future<void> _enqueueUploadForIndex(int index) async {
    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path == null) return;

    final file = File(result!.files.single.path!);
    final fileName = result.files.single.name;

    setState(() {
      _uploadQueue.add(QueuedUpload(file, fileName, docIndex: index));
    });
    _startQueueProcessor();
  }

  Future<void> _enqueueNewUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path == null) return;

    final file = File(result!.files.single.path!);
    final fileName = result.files.single.name;

    setState(() {
      _uploadQueue.add(QueuedUpload(file, fileName));
    });
    _startQueueProcessor();
  }

  void _startQueueProcessor() {
    if (!_isProcessingQueue) _processQueue();
  }

  Future<void> _processQueue() async {
    _isProcessingQueue = true;

    while (true) {
      final nextUpload = _uploadQueue.cast<QueuedUpload?>().firstWhere(
        (q) => q?.status == UploadStatus.queued,
        orElse: () => null,
      );

      if (nextUpload == null) break;

      await _processUpload(nextUpload);
    }

    _isProcessingQueue = false;
  }

  Future<void> _processUpload(QueuedUpload upload) async {
    setState(() => upload.status = UploadStatus.uploading);

    try {
      final url = await _storageService.uploadFile(
        'courses/${DateTime.now().millisecondsSinceEpoch}_${_safeFileName(upload.fileName)}',
        upload.file,
      );
      _handleUploadSuccess(upload, url);
    } catch (e) {
      if (mounted) setState(() => upload.status = UploadStatus.failed);
    }
  }

  void _handleUploadSuccess(QueuedUpload upload, String url) {
    if (!mounted) return;

    setState(() {
      if (upload.docIndex != null && upload.docIndex! < _courseDocuments.length) {
        _courseDocuments[upload.docIndex!]['url'] = url;
        if ((_courseDocuments[upload.docIndex!]['name'] ?? '').isEmpty) {
          _courseDocuments[upload.docIndex!]['name'] = upload.fileName;
        }
      } else {
        _courseDocuments.add({'name': upload.fileName, 'url': url});
      }
      upload.status = UploadStatus.done;
    });
  }

  void _cancelUpload(QueuedUpload upload) {
    if (upload.status == UploadStatus.queued) {
      setState(() => _uploadQueue.remove(upload));
      return;
    }

    if (upload.status == UploadStatus.uploading && upload.task != null) {
      upload.task!.cancel();
      setState(() => upload.status = UploadStatus.canceled);
    }
  }

  void _retryUpload(QueuedUpload upload) {
    if (upload.status == UploadStatus.uploading || upload.status == UploadStatus.queued) return;
    setState(() {
      upload.status = UploadStatus.queued;
      upload.progress = 0.0;
    });
    _startQueueProcessor();
  }

  // === ANNOUNCEMENT MANAGEMENT ===
  Future<void> _showCourseAnnouncementDialog(String courseId, String courseName) async {
    final result = await showDialog<Map<String, dynamic>?>( 
      context: context,
      builder: (context) => _CourseAnnouncementDialog(
        courseId: courseId,
        courseName: courseName,
        firestoreService: _firestoreService,
      ),
    );

    if (result == null || result['send'] != true) return;

    await _sendAnnouncement(courseId, result);
  }

  Future<void> _sendAnnouncement(String courseId, Map<String, dynamic> data) async {
    final title = (data['title'] as String?)?.trim() ?? '';
    final body = (data['body'] as String?)?.trim() ?? '';

    if (title.isEmpty && body.isEmpty) {
      _showErrorSnackbar('Veuillez saisir un titre ou un message');
      return;
    }

    try {
      final payload = {
        'title': title,
        'body': body,
        'attachments': data['attachments'] ?? [],
      };
      await _firestoreService.sendDataToCourseUsers(courseId, payload);
      _showSuccessSnackbar('Message envoyé aux étudiants du cours');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'envoi: $e');
    }
  }

  Future<void> _processMessageUploadQueue(String recipientUid, List<QueuedUpload> queue, List<Map<String, String>> attachments, Function setStateCallback) async {
    bool isProcessing = true;
    while (isProcessing) {
      final nextUpload = queue.firstWhere(
        (q) => q.status == UploadStatus.queued,
        orElse: () => QueuedUpload(File(''), ''), // Dummy to break loop
      );

      if (nextUpload.fileName.isEmpty) {
        isProcessing = false;
        break;
      }

      setStateCallback(() => nextUpload.status = UploadStatus.uploading);

      try {
        final task = _storageService.startUpload(
          'messages_attachments/$recipientUid/${DateTime.now().millisecondsSinceEpoch}_${_safeFileName(nextUpload.fileName)}',
          nextUpload.file,
        );
        nextUpload.task = task;

        await for (final snapshot in task.snapshotEvents) {
          final progress = snapshot.totalBytes > 0
              ? snapshot.bytesTransferred / snapshot.totalBytes
              : 0.0;
          setStateCallback(() => nextUpload.progress = progress);
        }

        final url = await task.snapshot.ref.getDownloadURL();
        setStateCallback(() {
          attachments.add({'name': nextUpload.fileName, 'url': url});
          nextUpload.status = UploadStatus.done;
        });
      } catch (e) {
        setStateCallback(() => nextUpload.status = UploadStatus.failed);
        _showErrorSnackbar('Erreur d\'upload: $e');
      }
    }
  }

  Future<void> _sendIndividualMessage(String recipientUid, String recipientName, String recipientEmail) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final List<Map<String, String>> uploadedAttachments = [];
    final List<Map<String, String>> messageLinks = [];
    final List<QueuedUpload> messageUploadQueue = [];

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateInDialog) {
          
          // Helper for dialog-specific upload logic
          Future<void> _enqueueMessageUpload() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
            );
            if (result?.files.single.path == null) return;

            final file = File(result!.files.single.path!);
            final fileName = result.files.single.name;

            setStateInDialog(() {
              messageUploadQueue.add(QueuedUpload(file, fileName));
            });
            _processMessageUploadQueue(recipientUid, messageUploadQueue, uploadedAttachments, setStateInDialog);
          }

          // Helper to build a link item widget
          Widget _buildLinkItem(int index) {
            return Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: messageLinks[index]['name']),
                        decoration: const InputDecoration(labelText: 'Nom du lien', isDense: true),
                        onChanged: (value) => messageLinks[index]['name'] = value.trim(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: messageLinks[index]['url']),
                        decoration: const InputDecoration(labelText: 'URL', isDense: true),
                        onChanged: (value) => messageLinks[index]['url'] = value.trim(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setStateInDialog(() => messageLinks.removeAt(index)),
                    ),
                  ],
                ),
              ),
            );
          }

          return AlertDialog(
            title: Text('Envoyer un message à ${recipientName}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- Attachments Section ---
                  Text('Pièces jointes (fichiers)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...uploadedAttachments.asMap().entries.map((entry) {
                    final doc = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text(doc['name'] ?? ''),
                      subtitle: Text(doc['url'] ?? '', overflow: TextOverflow.ellipsis),
                      // Cannot be deleted once uploaded
                    );
                  }),
                  ...messageUploadQueue.asMap().entries.map((entry) {
                    final upload = entry.value;
                    if (upload.status == UploadStatus.uploading || upload.status == UploadStatus.queued) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: LinearProgressIndicator(value: upload.progress),
                      );
                    } else if (upload.status == UploadStatus.failed) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('Upload échoué: ${upload.fileName}', style: TextStyle(color: Colors.red)),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  ElevatedButton.icon(
                    onPressed: _enqueueMessageUpload,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Uploader un fichier'),
                  ),

                  const SizedBox(height: 16),

                  // --- Links Section ---
                  Text('Ressources (liens)', style: Theme.of(context).textTheme.titleMedium),
                  ...messageLinks.asMap().entries.map((entry) => _buildLinkItem(entry.key)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => setStateInDialog(() => messageLinks.add({'name': '', 'url': ''})),
                    icon: const Icon(Icons.add_link),
                    label: const Text('Ajouter un lien'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  final allAttachments = [...uploadedAttachments, ...messageLinks];
                  if (titleController.text.trim().isEmpty && bodyController.text.trim().isEmpty && allAttachments.isEmpty) {
                    _showErrorSnackbar('Veuillez saisir un titre, un message ou ajouter une pièce jointe/lien.');
                    return;
                  }
                  Navigator.of(context).pop();
                  await _firestoreService.sendIndividualMessage(
                    recipientUid,
                    titleController.text.trim(),
                    bodyController.text.trim(),
                    allAttachments,
                  );
                  _showSuccessSnackbar('Message envoyé à ${recipientName}');
                },
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      ),
    );
  }

  // === UTILITY METHODS ===
  void _clearCourseForm() {
    _courseNameController.clear();
    _courseDescController.clear();
    _courseDocuments.clear();
    _courseResources.clear();
    // Dispose and clear resource controllers
    for (var controllers in _resourceItemControllers) {
      controllers['name']?.dispose();
      controllers['url']?.dispose();
    }
    _resourceItemControllers.clear();
  }

  bool get _hasUploadsInProgress =>
      _uploadQueue.any((q) =>
          q.status == UploadStatus.queued || q.status == UploadStatus.uploading) ||
      _isProcessingQueue;

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // === UI BUILD METHODS ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        elevation: 0,
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
            Tab(icon: Icon(Icons.school), text: 'Cours'),
            Tab(icon: Icon(Icons.group), text: 'Inscriptions'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildAdminsTab(),
          _buildCoursesTab(),
          _buildEnrollmentsTab(),
          const StudentListScreen(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildAdminsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminForm(),
          const SizedBox(height: 24),
          _buildPendingEnrollmentsCard(), // New card
          const SizedBox(height: 24),
          _buildAdminsList(),
        ],
      ),
    );
  }

  Widget _buildPendingEnrollmentsCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PendingEnrollmentsScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, size: 36, color: Colors.orange),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demandes d\'inscription en attente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_globalPendingEnrollmentCount nouvelle(s) demande(s)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (_globalPendingEnrollmentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_globalPendingEnrollmentCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajouter un administrateur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Promouvez un utilisateur existant au rang d\'administrateur. L\'utilisateur doit déjà avoir un compte.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _showAdminPromotionDialog,
                icon: const Icon(Icons.add_moderator),
                label: const Text('Promouvoir un utilisateur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Administrateurs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadAdmins,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _admins.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Aucun administrateur'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _admins.length,
                    itemBuilder: (context, index) => _buildAdminListItem(_admins[index]),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminListItem(Map<String, dynamic> admin) {
    String _initial() {
      final name = (admin['name'] as String?)?.trim() ?? '';
      final uid = (admin['uid'] as String?)?.trim() ?? '';
      final base = name.isNotEmpty ? name : uid.isNotEmpty ? uid : 'A';
      return base.substring(0, 1).toUpperCase();
    }
    return ListTile(
      leading: CircleAvatar(
        child: Text(_initial()),
      ),
      title: Text(admin['name'] ?? admin['uid'] ?? 'Nom inconnu'),
      subtitle: Text(admin['email'] ?? admin['uid'] ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        onPressed: () => _showDeleteAdminConfirmation(admin['uid']),
        tooltip: 'Supprimer',
      ),
    );
  }

  void _showDeleteAdminConfirmation(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir retirer cet administrateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeAdmin(uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCourseForm(),
          const SizedBox(height: 24),
          _buildCoursesList(),
        ],
      ),
    );
  }

  Widget _buildCourseForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créer un nouveau cours',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du cours',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _courseDescController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),
            _buildDocumentsSection(),
            const SizedBox(height: 24),
            _buildResourcesSection(),
            const SizedBox(height: 24),
            if (_hasUploadsInProgress) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Uploads en cours, veuillez patienter...', 
                style: TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_hasUploadsInProgress || _isLoading) ? null : _createCourse,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'Création...' : 'Créer le cours'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents (PDF, etc.)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._courseDocuments.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          return _buildDocumentItem(index, doc);
        }),
        const SizedBox(height: 8),
        _buildNewDocumentUpload(),
      ],
    );
  }

  Widget _buildDocumentItem(int index, Map<String, String> doc) {
    final upload = _findQueueForIndex(index);
    final isUploading = upload != null && 
        (upload.status == UploadStatus.uploading || upload.status == UploadStatus.queued);

    final nameController = TextEditingController(text: doc['name']);
    final urlController = TextEditingController(text: doc['url']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du document',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        setState(() => _courseDocuments[index]['name'] = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        setState(() => _courseDocuments[index]['url'] = value),
                  ),
                ),
              ],
            ),
            if (isUploading) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(value: upload.progress),
                  ),
                  const SizedBox(width: 8),
                  Text('${(upload.progress * 100).toStringAsFixed(0)}%'),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () => _cancelUpload(upload),
                  ),
                ],
              ),
            ] else if (upload != null && upload.status == UploadStatus.failed) ...[
              const SizedBox(height: 8),
              Row(children: [ 
                ElevatedButton.icon(onPressed: () => _retryUpload(upload), icon: const Icon(Icons.refresh), label: const Text('Retry')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () => setState(() => _courseDocuments.removeAt(index)), icon: const Icon(Icons.delete), label: const Text('Supprimer')),
              ]),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _enqueueUploadForIndex(index),
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Upload'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _courseDocuments.removeAt(index)),
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewDocumentUpload() {
    final newUpload = _findQueueForIndex(null);
    final isUploading = newUpload != null && 
        (newUpload.status == UploadStatus.uploading || newUpload.status == UploadStatus.queued);

    if (isUploading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(value: newUpload.progress),
              ),
              const SizedBox(width: 8),
              Text('${(newUpload.progress * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _cancelUpload(newUpload),
              ),
            ],
          ),
        ),
      );
    }
    if (newUpload != null && newUpload.status == UploadStatus.failed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(children: [ 
            ElevatedButton.icon(onPressed: () => _retryUpload(newUpload), icon: const Icon(Icons.refresh), label: const Text('Retry')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => setState(() => _uploadQueue.remove(newUpload)), icon: const Icon(Icons.delete), label: const Text('Supprimer')),
          ]),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _enqueueNewUpload,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter / uploader document'),
    );
  }

  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ressources (liens)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._resourceItemControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = entry.value;
          return _buildResourceItem(index, controllers);
        }).toList(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _resourceItemControllers.add({
                'name': TextEditingController(),
                'url': TextEditingController(),
              });
              _courseResources.add({'name': '', 'url': ''}); // Keep _courseResources in sync
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Ajouter ressource'),
        ),
      ],
    );
  }

  Widget _buildResourceItem(int index, Map<String, TextEditingController> controllers) {
    return Card(
      key: ValueKey(controllers['url']!.hashCode), // Use a stable key
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers['name'],
                decoration: const InputDecoration(
                  labelText: 'Nom de la ressource',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) =>
                    _courseResources[index]['name'] = value, // Update underlying data
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controllers['url'],
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) =>
                    _courseResources[index]['url'] = value, // Update underlying data
                textDirection: TextDirection.ltr, // Add this
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  controllers['name']?.dispose();
                  controllers['url']?.dispose();
                  _resourceItemControllers.removeAt(index);
                  _courseResources.removeAt(index); // Keep _courseResources in sync
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Cours existants',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadCourses,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _courses.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Aucun cours créé'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) => _buildCourseListItem(_courses[index]),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseListItem(Map<String, dynamic> course) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.school),
      ),
      title: Text(course['name'] ?? 'Cours sans nom'),
      subtitle: Text(course['description'] ?? 'Aucune description'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'enrollments':
              _loadEnrollmentData(course['id']);
              _mainTabController.animateTo(2); // Switch to enrollments tab
              break;
            case 'announcement':
              _showCourseAnnouncementDialog(course['id'], course['name'] ?? '');
              break;
            case 'archive':
              _archiveCourse(course['id']);
              break;
            case 'delete':
              _deleteCourse(course['id']);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'enrollments',
            child: Row(
              children: [ 
                Icon(Icons.pending_actions),
                SizedBox(width: 8),
                Text('Gérer les inscriptions'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'announcement',
            child: Row(
              children: [ 
                Icon(Icons.campaign),
                SizedBox(width: 8),
                Text('Envoyer une annonce'),
              ],
            ),
          ),
          const PopupMenuDivider(), // Add a divider
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [ 
                Icon(Icons.archive),
                SizedBox(width: 8),
                Text('Archiver le cours'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [ 
                Icon(Icons.delete_forever, color: Colors.red),
                SizedBox(width: 8),
                Text('Supprimer le cours', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        _loadEnrollmentData(course['id']);
        _mainTabController.animateTo(2);
      },
    );
  }

  Widget _buildEnrollmentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un cours',
                    border: OutlineInputBorder(),
                  ),
                  items: _courses.map((course) {
                    return DropdownMenuItem<String>(
                      value: course['id'],
                      child: Text(course['name'] ?? 'Cours sans nom'),
                    );
                  }).toList(),
                  onChanged: (courseId) {
                    if (courseId != null) {
                      _loadEnrollmentData(courseId);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _selectedCourseId == null ? null : _showAddStudentDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Inscrire'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedCourseId == null
              ? const Center(child: Text('Veuillez sélectionner un cours pour voir les inscriptions.'))
              : Column(
                  children: [
                    TabBar(
                      controller: _enrollmentsTabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'En attente (${_pendingEnrollments.length})'),
                        Tab(text: 'Inscrits (${_enrolledStudents.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _enrollmentsTabController,
                        children: [
                          _buildEnrollmentList(_pendingEnrollments, isPending: true),
                          _buildEnrollmentList(_enrolledStudents, isPending: false),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentList(List<Map<String, dynamic>> enrollments, {required bool isPending}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (enrollments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(isPending ? 'Aucune inscription en attente' : 'Aucun étudiant inscrit'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadEnrollmentData(_selectedCourseId!),
      child: ListView.builder(
        itemCount: enrollments.length,
        itemBuilder: (context, index) {
          final enrollment = enrollments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(_safeInitial(enrollment['name'] as String?, fallback: 'U')),
              ),
              title: Text(enrollment['name'] ?? 'Utilisateur inconnu'),
              subtitle: Text(enrollment['email'] ?? enrollment['uid'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPending) ...[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveEnrollment(enrollment['uid']),
                      tooltip: 'Approuver',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectEnrollment(enrollment['uid']),
                      tooltip: 'Rejeter',
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.blue),
                      onPressed: () => _sendIndividualMessage(
                        enrollment['uid'],
                        enrollment['name'] ?? 'Utilisateur',
                        enrollment['email'] ?? '',
                      ),
                      tooltip: 'Envoyer un message',
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: () => _revokeEnrollment(enrollment['uid']),
                      tooltip: 'Révoquer l\'accès',
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Utilisateurs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Aucun utilisateur trouvé.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) => _buildUserListItem(_users[index]),
                    ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(Student user) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        ),
      ),
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: IconButton(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        onPressed: () => _deleteUser(user.uid),
        tooltip: 'Supprimer l\'utilisateur',
      ),
    );
  }

  Future<void> _deleteUser(String uid) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet utilisateur ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteUser(uid); // This method needs to be implemented in FirestoreService
        await _loadUsers();
        _showSuccessSnackbar('Utilisateur supprimé avec succès');
      } catch (e) {
        _showErrorSnackbar('Erreur lors de la suppression de l\'utilisateur: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

// === COURSE ANNOUNCEMENT DIALOG ===
class _CourseAnnouncementDialog extends StatefulWidget {
  final String courseId;
  final String courseName;
  final FirestoreService firestoreService;

  const _CourseAnnouncementDialog({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.firestoreService,
  }) : super(key: key);

  @override
  State<_CourseAnnouncementDialog> createState() => _CourseAnnouncementDialogState();
}

class _CourseAnnouncementDialogState extends State<_CourseAnnouncementDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  List<Document> _documents = [];
  final Set<String> _selectedDocumentIds = <String>{};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _loadDocuments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final documents = await widget.firestoreService.getDocuments(widget.courseId);
      if (mounted) {
        setState(() {
          _documents = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Annonce pour ${widget.courseName}'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pièces jointes (optionnel)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _documents.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun document disponible',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Scrollbar(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _documents.length,
                              itemBuilder: (context, index) {
                                final document = _documents[index];
                                final isSelected = _selectedDocumentIds.contains(document.id);
                                return CheckboxListTile(
                                  value: isSelected,
                                  title: Text(
                                    document.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: document.url.isNotEmpty
                                      ? Text(
                                          document.url,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedDocumentIds.add(document.id);
                                      } else {
                                        _selectedDocumentIds.remove(document.id);
                                      }
                                    });
                                  },
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final attachments = _documents
                .where((doc) => _selectedDocumentIds.contains(doc.id))
                .map((doc) => {
                      'id': doc.id,
                      'name': doc.name,
                      'url': doc.url,
                    })
                .toList();

            Navigator.of(context).pop({
              'send': true,
              'attachments': attachments,
              'title': _titleController.text,
              'body': _bodyController.text,
            });
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}

// === USER SELECTION DIALOG ===
class _UserSelectionDialog extends StatefulWidget {
  final List<Student> users;
  final String title;
  final String actionText;
  final Function(Student) onSelect;

  const _UserSelectionDialog({
    Key? key,
    required this.users,
    required this.title,
    required this.actionText,
    required this.onSelect,
  }) : super(key: key);

  @override
  __UserSelectionDialogState createState() => __UserSelectionDialogState();
}

class __UserSelectionDialogState extends State<_UserSelectionDialog> {
  String _searchTerm = '';
  List<Student> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.users;
  }

  void _filterUsers(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _searchTerm = lowerCaseQuery;
      _filteredUsers = widget.users.where((user) {
        return user.name.toLowerCase().contains(lowerCaseQuery) ||
               user.email.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: _filterUsers,
              decoration: const InputDecoration(
                labelText: 'Rechercher par nom ou email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredUsers.isEmpty
                  ? const Center(child: Text('Aucun utilisateur trouvé.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: ElevatedButton(
                              child: Text(widget.actionText),
                              onPressed: () {
                                widget.onSelect(user);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
} 
