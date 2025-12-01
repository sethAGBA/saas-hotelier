import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/document.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
// Removed debug upload helpers
import 'course_details_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _storageBucket = '';
  String _userName = 'Étudiant';
  String _searchQuery = '';
  int _pendingEnrollmentCount = 0; // New state variable
  StreamSubscription? _enrollmentCountSubscription; // New subscription variable

  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
    _listenToPendingEnrollments(); // New method call
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _enrollmentCountSubscription?.cancel(); // Cancel subscription
    super.dispose();
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCourses = _courses.where((course) {
        return course.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _loadCourses();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final student = await _firestoreService.getUser(user.uid);
      final isAdmin = await _firestoreService.isAdmin(user.uid);
      final bucket = Firebase.app().options.storageBucket ?? '';
      if (mounted) {
        setState(() {
          _userName = student?.name ?? user.displayName ?? 'Étudiant';
          _isAdmin = isAdmin;
          _storageBucket = bucket;
        });
      }
    } catch (e) {
      // ignore and keep defaults
    }
  }

  Future<void> _loadCourses() async {
    if (mounted) setState(() => _isLoading = true);
    final courses = await _firestoreService.getCourses();
    if (mounted) {
      setState(() {
        _courses = courses;
        _filteredCourses = courses;
        _isLoading = false;
      });
      _headerAnimationController.forward();
      _listAnimationController.forward();
    }
  }

  void _listenToPendingEnrollments() {
    _enrollmentCountSubscription = _firestoreService.getPendingEnrollmentCount().listen((count) {
      if (mounted) {
        setState(() {
          _pendingEnrollmentCount = count;
        });
      }
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Autocomplete<Course>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Course>.empty();
          }
          return _courses.where((Course option) {
            return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        displayStringForOption: (Course option) => option.name,
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            onChanged: (String value) {
              _filterCourses(value);
            },
            onSubmitted: (String value) {
              onFieldSubmitted();
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un cours...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: textEditingController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        textEditingController.clear();
                        _filterCourses('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          );
        },
        onSelected: (Course selection) {
          _filterCourses(selection.name);
        },
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final theme = Theme.of(context);
    final timeOfDay = DateTime.now().hour;
    String greeting = timeOfDay < 12 ? 'Bonjour' : timeOfDay < 17 ? 'Bonne après-midi' : 'Bonsoir';

    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: SlideTransition(
        position: _headerSlideAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                Color.lerp(theme.colorScheme.primary, Colors.black, 0.3)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The two status chips have been removed as requested.
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _isAdmin ? 'Voici un aperçu de votre organisation.' : 'Continuez votre apprentissage',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_courses.length} cours disponibles',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Debug upload removed per request

  Widget _buildCourseCard(Course course, int index) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CourseDetailsScreen(course: course),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.book_outlined,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.name,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Disponible',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          course.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(_isAdmin ? Icons.edit : Icons.play_circle_outline, 
                                 color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isAdmin ? 'Gérer le cours' : 'Commencer le cours',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    if (!_isAdmin) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.campaign,
                  title: 'Message global',
                
                  subtitle: 'Envoyer à tous',
                  color: theme.colorScheme.primary,
                  onTap: _showBroadcastDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Administration',
                  subtitle: 'Gérer admins',
                  color: theme.colorScheme.surface,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen())
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bool isPrimary = color == theme.colorScheme.primary;
    final onColor = isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(isPrimary ? 1.0 : 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: onColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: onColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: onColor.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAdmin ? 'Tableau de bord Admin' : 'Mon Parcours',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: 'Mes messages',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessagesScreen())
              );
            },
          ),
          if (_isAdmin)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'Administration',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen())
                  ),
                ),
                if (_pendingEnrollmentCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$_pendingEnrollmentCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildWelcomeHeader()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildQuickActions()),
                  if (_filteredCourses.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 80,
                              color: theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun cours disponible'
                                  : 'Aucun résultat trouvé',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Les cours apparaîtront ici une fois disponibles'
                                  : 'Essayez avec un autre mot-clé',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCourseCard(_filteredCourses[index], index),
                        childCount: _filteredCourses.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  Future<void> _showBroadcastDialog() async {
    final theme = Theme.of(context);
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _BroadcastDialog(
        courses: _courses,
        firestoreService: _firestoreService,
      ),
    );

    if (result == null || result['send'] != true) return;

    final title = (result['title'] as String?)?.trim() ?? '';
    final body = (result['body'] as String?)?.trim() ?? '';

    if (title.isEmpty && body.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Text('Veuillez saisir un titre ou un message'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    final attachments = result['attachments'] as List<dynamic>? ?? [];
    final payload = {'title': title, 'body': body, 'attachments': attachments};
    
    try {
      await _firestoreService.sendDataToAllUsers(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Message envoyé à tous les étudiants'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

class _BroadcastDialog extends StatefulWidget {
  final List<Course> courses;
  final FirestoreService firestoreService;

  const _BroadcastDialog({Key? key, required this.courses, required this.firestoreService}) : super(key: key);

  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  late final TextEditingController _titleC;
  late final TextEditingController _bodyC;
  String? _selectedCourseId;
  List<Document> _docs = [];
  final Set<String> _selectedDocIds = <String>{};
  bool _isLoadingDocs = false;

  @override
  void initState() {
    super.initState();
    _titleC = TextEditingController();
    _bodyC = TextEditingController();
    _selectedCourseId = widget.courses.isNotEmpty ? widget.courses.first.id : null;
    if (_selectedCourseId != null) _loadDocs(_selectedCourseId);
  }

  Future<void> _loadDocs(String? courseId) async {
    if (courseId == null) return;
    setState(() => _isLoadingDocs = true);
    final docs = await widget.firestoreService.getDocuments(courseId);
    if (mounted) {
      setState(() {
        _docs = docs;
        _isLoadingDocs = false;
      });
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _bodyC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.campaign, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Envoyer un message global',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleC,
                      decoration: const InputDecoration(
                        labelText: 'Titre du message',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyC,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Contenu du message',
                        prefixIcon: Icon(Icons.message),
                      ),
                    ),
                    
                    if (widget.courses.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Pièces jointes (optionnel)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCourseId,
                        decoration: const InputDecoration(
                          labelText: 'Choisir un cours',
                          prefixIcon: Icon(Icons.school),
                        ),
                        items: widget.courses.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )).toList(),
                        onChanged: (val) async {
                          setState(() {
                            _selectedCourseId = val;
                            _docs = [];
                            _selectedDocIds.clear();
                          });
                          await _loadDocs(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoadingDocs
                            ? const Center(child: CircularProgressIndicator())
                            : _docs.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.folder_outlined, 
                                             color: theme.colorScheme.onSurface.withOpacity(0.4), size: 48),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Aucun document disponible',
                                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _docs.length,
                                    itemBuilder: (context, i) {
                                      final d = _docs[i];
                                      final checked = _selectedDocIds.contains(d.id);
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        decoration: BoxDecoration(
                                          color: checked ? theme.colorScheme.primary.withOpacity(0.1) : null,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: CheckboxListTile(
                                          value: checked,
                                          title: Text(d.name),
                                          subtitle: d.url.isNotEmpty ? Text(
                                            d.url,
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ) : null,
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) {
                                                _selectedDocIds.add(d.id);
                                              } else {
                                                _selectedDocIds.remove(d.id);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final attachments = _docs
                            .where((d) => _selectedDocIds.contains(d.id))
                            .map((d) => {
                                  'id': d.id,
                                  'name': d.name,
                                  'url': d.url,
                                })
                            .toList();
                        Navigator.of(context).pop({
                          'send': true,
                          'attachments': attachments,
                          'title': _titleC.text,
                          'body': _bodyC.text,
                        });
                      },
                      child: const Text('Envoyer'),
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
