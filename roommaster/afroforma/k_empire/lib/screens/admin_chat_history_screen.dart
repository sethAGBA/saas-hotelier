import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:k_empire/models/student.dart';
import 'package:k_empire/services/firestore_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

// Screen to display a list of students for the admin to chat with
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
 _studentsFuture = _firestoreService.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Student>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun étudiant trouvé.'));
          }

          final students = snapshot.data!;
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (() {
                      final v = (student.name).trim();
                      return v.isEmpty ? 'U' : v.substring(0, 1).toUpperCase();
                    })(),
                  ),
                ),
                title: Text(student.name),
                subtitle: Text(student.email),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdminStudentChatScreen(student: student),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


// Screen to display the message history with a single student
class AdminStudentChatScreen extends StatefulWidget {
  final Student student;

  const AdminStudentChatScreen({Key? key, required this.student}) : super(key: key);

  @override
  _AdminStudentChatScreenState createState() => _AdminStudentChatScreenState();
}

class _AdminStudentChatScreenState extends State<AdminStudentChatScreen> {
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }
    return '';
  }

  Future<void> _copyMessage(String body) async {
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copié dans le presse-papiers.')),
    );
  }

  Future<void> _shareMessage(String title, String body) async {
    final content = '$title\n\n$body';
    await Share.share(content, subject: title);
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce message ? Cette action est irréversible.'),
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

    if (confirm != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.student.uid)
          .collection('messages')
          .doc(messageId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message supprimé.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
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
        SnackBar(content: Text('Impossible d\'ouvrir le lien: $url')),
      );
    }
  }

  Future<void> _handleAttachmentTap(String name, String url) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text('Que souhaitez-vous faire ?\n$url'),
        actions: [
          TextButton(
            child: const Text('Copier l\'URL'),
            onPressed: () {
              Navigator.of(context).pop();
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copiée.')),
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

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.student.uid)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Historique avec ${widget.student.name}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun message trouvé.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final message = docs[index];
              final data = message.data() as Map<String, dynamic>;
              final title = data['title'] ?? '(Sans titre)';
              final body = data['body'] ?? '';
              final time = _formatTimestamp(data['sentAt']);
              final attachments = data['attachments'] as List<dynamic>?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SelectableText(title, style: Theme.of(context).textTheme.titleLarge, toolbarOptions: const ToolbarOptions(copy: true, selectAll: true)),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'copy') _copyMessage(body);
                              if (value == 'share') _shareMessage(title, body);
                              if (value == 'delete') _deleteMessage(message.id);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'copy', child: Text('Copier')),
                              const PopupMenuItem(value: 'share', child: Text('Partager')),
                              const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      SelectableText(time, style: Theme.of(context).textTheme.bodySmall, toolbarOptions: const ToolbarOptions(copy: true, selectAll: true)),
                      const Divider(),
                      if (body.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: SelectableLinkify(
                            text: body,
                            onOpen: (link) => _launchURL(link.url),
                            linkStyle: const TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      if (attachments != null && attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Pièces jointes:', style: Theme.of(context).textTheme.titleSmall),
                        ...attachments.map((att) {
                          final name = att['name'] ?? 'Pièce jointe';
                          final url = att['url'] ?? '';
                          final isFile = url.contains('firebasestorage.googleapis.com');
                          return ListTile(
                            leading: Icon(isFile ? Icons.attachment : Icons.link),
                            title: SelectableText(name, toolbarOptions: const ToolbarOptions(copy: true, selectAll: true)),
                            onTap: () => _handleAttachmentTap(name, url),
                          );
                        }),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
