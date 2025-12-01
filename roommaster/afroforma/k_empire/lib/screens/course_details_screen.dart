import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course.dart';
import '../models/document.dart';
import '../models/certificate.dart';
import 'package:k_empire/services/firestore_service.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({Key? key, required this.course}) : super(key: key);

  @override
  _CourseDetailsScreenState createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Document> _documents = [];
  List<Certificate> _certificates = [];
  bool _isLoading = true;
  String _enrollmentStatus = 'none';
  bool _isEnrolling = false;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _enrolledStudents = [];
  late Course _currentCourse;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentCourse = widget.course;
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final isAdmin = await _firestoreService.isAdmin(user.uid);
    List<Map<String, dynamic>> enrolledStudents = [];
    if (isAdmin) {
      enrolledStudents = await _firestoreService.listEnrolledStudents(widget.course.id);
    }

    final documents = await _firestoreService.getDocuments(widget.course.id);
    final certificates = await _firestoreService.getCertificates(widget.course.id);
    final status = await _firestoreService.getEnrollmentStatus(widget.course.id, user.uid);

    if (mounted) {
      setState(() {
        _documents = documents;
        _certificates = certificates;
        _enrollmentStatus = status;
        _isAdmin = isAdmin;
        _enrolledStudents = enrolledStudents;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _requestEnrollment() async {
    setState(() => _isEnrolling = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isEnrolling = false);
      return;
    }

    try {
      final participant = await _firestoreService.getUser(user.uid);
      final participantName = participant?.name ?? user.displayName ?? 'Utilisateur inconnu';

      await _firestoreService.requestEnrollment(
        widget.course.id,
        user.uid,
        user.email ?? '',
        participantName,
      );
      final status = await _firestoreService.getEnrollmentStatus(widget.course.id, user.uid);

      if (mounted) {
        setState(() => _enrollmentStatus = status);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande d\'inscription envoyée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir le lien: $url'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleResourceTap(String name, String url) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text('Que souhaitez-vous faire avec ce lien ?\n$url'),
        actions: [
          TextButton(
            child: const Text('Copier l\'URL'),
            onPressed: () {
              Navigator.of(context).pop();
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copiée dans le presse-papiers.')),
              );
            },
          ),
          ElevatedButton(
            child: const Text('Ouvrir'),
            onPressed: () {
              Navigator.of(context).pop();
              _launchURL(url);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCourseDialog() async {
    final List<Map<String, dynamic>> resourcesControllers = [];
    final TextEditingController nameController = TextEditingController(text: _currentCourse.name);
    final TextEditingController descriptionController = TextEditingController(text: _currentCourse.description);

    if (_currentCourse.resources != null) {
      for (var resource in _currentCourse.resources!) {
        resourcesControllers.add({
          'id': resource['url'] ?? UniqueKey().toString(),
          'name': TextEditingController(text: resource['name']),
          'url': TextEditingController(text: resource['url']),
        });
      }
    }

    final bool? success = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier le cours'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du cours')),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                    const SizedBox(height: 20),
                    Text('Ressources', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Column(
                      children: resourcesControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> controllers = entry.value;
                        return Padding(
                          key: ValueKey(controllers['id']),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controllers['name'],
                                  decoration: InputDecoration(labelText: 'Nom de la ressource ${index + 1}')),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: controllers['url'],
                                  decoration: InputDecoration(labelText: 'URL de la ressource ${index + 1}')),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    (controllers['name'] as TextEditingController?)?.dispose();
                                    (controllers['url'] as TextEditingController?)?.dispose();
                                    resourcesControllers.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          resourcesControllers.add({
                            'id': UniqueKey().toString(),
                            'name': TextEditingController(),
                            'url': TextEditingController(),
                          });
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une ressource'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () async {
                    final List<Map<String, String>> updatedResources = resourcesControllers.map((controllers) {
                      return {
                        'name': (controllers['name'] as TextEditingController).text ?? '',
                        'url': (controllers['url'] as TextEditingController).text ?? '',
                      };
                    }).toList();

                    await _firestoreService.updateCourse(
                      _currentCourse.id,
                      nameController.text,
                      descriptionController.text,
                      resources: updatedResources,
                    );
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true) {
      setState(() {
        _currentCourse = Course(
          id: _currentCourse.id,
          name: nameController.text,
          description: descriptionController.text,
          resources: resourcesControllers.map((controllers) {
            return {
              'name': (controllers['name'] as TextEditingController).text ?? '',
              'url': (controllers['url'] as TextEditingController).text ?? '',
            };
          }).toList(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cours mis à jour')));
    }
  }

  Widget _buildEnrollmentStatus() {
    final theme = Theme.of(context);
    if (_isAdmin) {
      return const SizedBox.shrink();
    }
    switch (_enrollmentStatus) {
      case 'pending':
        return _StatusCard(
          title: 'Inscription en attente',
          subtitle: 'Votre demande est en cours de traitement',
          icon: Icons.hourglass_empty,
          color: theme.colorScheme.primary,
        );
      case 'enrolled':
        return _StatusCard(
          title: 'Inscrit avec succès',
          subtitle: 'Vous avez accès à tous les contenus du cours',
          icon: Icons.check_circle,
          color: Colors.green.shade600,
        );
      case 'rejected':
        return _StatusCard(
          title: 'Inscription refusée',
          subtitle: 'Contactez l\'administrateur pour plus d\'informations',
          icon: Icons.cancel,
          color: theme.colorScheme.error,
        );
      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isEnrolling ? null : _requestEnrollment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            icon: _isEnrolling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Icon(Icons.person_add_alt_1, size: 22),
            label: Text(_isEnrolling ? 'Inscription en cours...' : 'S\'inscrire à ce cours', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SelectableLinkify(
          text: content,
          onOpen: (link) => _launchURL(link.url),
          style: const TextStyle(fontSize: 16, height: 1.6),
          linkStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  Widget _buildListItemCard({required String title, required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(Icons.open_in_new, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canViewDocuments = _isAdmin || _enrollmentStatus == 'enrolled';

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCourse.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _showEditCourseDialog,
              tooltip: 'Modifier le cours',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Description', Icons.info_outline),
                      _buildInfoCard(_currentCourse.description),
                      
                      if (_isAdmin) ...[
                        _buildSectionHeader('Participants Inscrits (${_enrolledStudents.length})', Icons.people_outline),
                        if (_enrolledStudents.isEmpty)
                          const Text('Aucun participant inscrit pour le moment.')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _enrolledStudents.length,
                            itemBuilder: (context, index) {
                              final participant = _enrolledStudents[index];
                              final participantName = participant['name'] as String?;
                              final avatarText = (participantName != null && participantName.isNotEmpty) ? participantName[0].toUpperCase() : 'P';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(child: Text(avatarText)),
                                  title: Text(participantName ?? 'Utilisateur inconnu'),
                                  subtitle: Text(participant['email'] ?? 'Email non fourni'),
                                ),
                              );
                            },
                          ),
                      ],

                      if (canViewDocuments && _documents.isNotEmpty) ...[
                        _buildSectionHeader('Documents (${_documents.length})', Icons.folder_outlined),
                        ..._documents.map((doc) => _buildListItemCard(
                          title: doc.name,
                          icon: Icons.article_outlined,
                          onTap: () => _launchURL(doc.url),
                        )),
                      ],

                      if (canViewDocuments && _certificates.isNotEmpty) ...[
                        _buildSectionHeader('Certificats (${_certificates.length})', Icons.workspace_premium_outlined),
                        ..._certificates.map((cert) => _buildListItemCard(
                          title: cert.name,
                          icon: Icons.school_outlined,
                          onTap: () => _launchURL(cert.url),
                        )),
                      ],

                      if (canViewDocuments && _currentCourse.resources != null && _currentCourse.resources!.isNotEmpty) ...[
                        _buildSectionHeader('Ressources (${_currentCourse.resources!.length})', Icons.link),
                        ..._currentCourse.resources!.map((res) => _buildListItemCard(
                          title: res['name'] ?? 'Lien',
                          icon: Icons.link,
                          onTap: () => _handleResourceTap(res['name']!, res['url']!),
                        )),
                      ],

                      const SizedBox(height: 28),
                      _buildEnrollmentStatus(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatusCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}