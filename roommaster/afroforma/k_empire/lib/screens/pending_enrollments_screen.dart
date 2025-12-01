import 'package:flutter/material.dart';
import 'package:k_empire/services/firestore_service.dart';

class PendingEnrollmentsScreen extends StatefulWidget {
  const PendingEnrollmentsScreen({Key? key}) : super(key: key);

  @override
  State<PendingEnrollmentsScreen> createState() => _PendingEnrollmentsScreenState();
}

class _PendingEnrollmentsScreenState extends State<PendingEnrollmentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _pendingEnrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingEnrollments();
  }

  Future<void> _loadPendingEnrollments() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all courses to then get pending enrollments for each
      final courses = await _firestoreService.getCourses();
      List<Map<String, dynamic>> allPending = [];
      for (var course in courses) {
        final pending = await _firestoreService.getPendingEnrollments(course.id);
        for (var req in pending) {
          allPending.add({
            ...req,
            'courseId': course.id,
            'courseName': course.name,
          });
        }
      }
      if (mounted) {
        setState(() {
          _pendingEnrollments = allPending;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des demandes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveEnrollment(String courseId, String uid) async {
    try {
      await _firestoreService.approveEnrollment(courseId, uid);
      _showSuccessSnackbar('Demande approuvée');
      _loadPendingEnrollments(); // Refresh list
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'approbation: $e');
    }
  }

  Future<void> _rejectEnrollment(String courseId, String uid) async {
    try {
      await _firestoreService.rejectEnrollment(courseId, uid);
      _showSuccessSnackbar('Demande rejetée');
      _loadPendingEnrollments(); // Refresh list
    } catch (e) {
      _showErrorSnackbar('Erreur lors du rejet: $e');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'inscription en attente'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingEnrollments.isEmpty
              ? const Center(
                  child: Text('Aucune demande d\'inscription en attente.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingEnrollments,
                  child: ListView.builder(
                    itemCount: _pendingEnrollments.length,
                    itemBuilder: (context, index) {
                      final request = _pendingEnrollments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (() {
                                final v = ((request['name'] as String?) ?? '').trim();
                                return v.isEmpty ? 'U' : v.substring(0, 1).toUpperCase();
                              })(),
                            ),
                          ),
                          title: Text(request['name'] ?? 'Utilisateur inconnu'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(request['email'] ?? 'Email non fourni'),
                              Text('Cours: ${request['courseName'] ?? 'Inconnu'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _approveEnrollment(request['courseId'], request['uid']),
                                tooltip: 'Approuver',
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectEnrollment(request['courseId'], request['uid']),
                                tooltip: 'Rejeter',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
