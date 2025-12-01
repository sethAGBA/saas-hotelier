import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:k_empire/screens/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:share_plus/share_plus.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  Future<void> _markAllAsRead(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout marquer comme lu ?'),
        content: const Text('Cette action marquera tous vos messages comme lus.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final messagesRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('messages');
      final unreadMessages = await messagesRef.where('read', isEqualTo: false).get();

      if (unreadMessages.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun message non lu.')),
        );
        return;
      }

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les messages ont été marqués comme lus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: uid == null
          ? _buildNotLoggedInState()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('messages')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;
                return _buildMessagesList(docs);
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Boîte de réception',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.mark_chat_read_outlined),
          tooltip: 'Tout marquer comme lu',
          onPressed: () => _markAllAsRead(context),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0, left: 8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person, size: 20)  ,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous pour voir vos messages',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement des messages...', 
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos messages et annonces apparaîtront ici.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final d = docs[index];
        final data = d.data() as Map<String, dynamic>;
        final title = data['title'] ?? '(Sans titre)';
        final body = data['body'] ?? '';
        final ts = data['sentAt'];
        final time = _formatTimestamp(ts);
        final isRead = data['read'] ?? false;

        return _buildMessageListItem(context, d.id, title, body, time, isRead, data['attachments']);
      },
    );
  }

  Widget _buildMessageListItem(BuildContext context, String messageId, String title, String body, String time, bool isRead, List<dynamic>? attachments) {
    return Card(
      elevation: isRead ? 0 : 3,
      color: isRead ? Theme.of(context).cardColor : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MessageDetailScreen(
                messageId: messageId,
                title: title,
                body: body,
                sentAt: time,
                attachments: attachments,
                isRead: isRead,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (attachments != null && attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attachment, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${attachments.length} pièce(s) jointe(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(dt);
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return weekdays[dt.weekday - 1];
      } else {
        return DateFormat('dd/MM/yyyy').format(dt);
      }
    }
    return '';
  }
}

class MessageDetailScreen extends StatefulWidget {
  final String messageId;
  final String title;
  final String body;
  final String sentAt;
  final List<dynamic>? attachments;
  final bool isRead;

  const MessageDetailScreen({
    Key? key,
    required this.messageId,
    required this.title,
    required this.body,
    required this.sentAt,
    this.attachments,
    required this.isRead,
  }) : super(key: key);

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isRead) {
      _markMessageAsRead();
    }
  }

  Future<void> _markMessageAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('messages')
          .doc(widget.messageId)
          .update({'read': true});
    }
  }

  Future<void> _copyMessage() async {
    await Clipboard.setData(ClipboardData(text: widget.body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copié dans le presse-papiers.')),
    );
  }

  Future<void> _shareMessage() async {
    final content = '${widget.title}\n\n${widget.body}';
    await Share.share(content, subject: widget.title);
  }

  Future<void> _deleteMessage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce message ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('messages')
            .doc(widget.messageId)
            .delete();
        
        if (mounted) {
          Navigator.of(context).pop();
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
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleAttachmentTap(String name, String url) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyMessage();
                  break;
                case 'share':
                  _shareMessage();
                  break;
                case 'delete':
                  _deleteMessage();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'copy',
                child: ListTile(leading: Icon(Icons.copy), title: Text('Copier')),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: ListTile(leading: Icon(Icons.share), title: Text('Partager')),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Supprimer', style: TextStyle(color: Colors.red))),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              toolbarOptions: const ToolbarOptions(copy: true, selectAll: true),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Envoyé le: ${widget.sentAt}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              toolbarOptions: const ToolbarOptions(copy: true, selectAll: true),
            ),
            const Divider(height: 32),
            SelectableLinkify(
              text: widget.body,
              onOpen: (link) => _launchURL(link.url),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              linkStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            if (widget.attachments != null && widget.attachments!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Pièces jointes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.attachments!.map<Widget>((attachment) {
                final name = attachment['name'] ?? 'Fichier';
                final url = attachment['url'] ?? '';
                final isFile = url.contains('firebasestorage.googleapis.com');

                return ListTile(
                  leading: Icon(
                    isFile ? Icons.attachment : Icons.link, 
                    color: Theme.of(context).colorScheme.primary
                  ),
                  title: SelectableText(
                    name,
                    toolbarOptions: const ToolbarOptions(copy: true, selectAll: true),
                  ),
                  subtitle: SelectableText(
                    url, 
                    style: TextStyle(color: Colors.grey.shade600),
                    toolbarOptions: const ToolbarOptions(copy: true, selectAll: true),
                  ),
                  trailing: Icon(
                    isFile ? Icons.download : Icons.open_in_new, 
                    color: Colors.grey
                  ),
                  onTap: () => _handleAttachmentTap(name, url),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
