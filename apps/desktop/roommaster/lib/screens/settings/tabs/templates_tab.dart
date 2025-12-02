import 'package:flutter/material.dart';

import '../../../data/local_database.dart';
import '../../../models/document_template.dart';
import '../templates/canvas_thumbnail.dart';
import '../templates/template_canvas_dialog.dart';
import '../templates/template_dialog.dart';
import '../widgets/setting_card.dart';

class TemplatesTab extends StatefulWidget {
  const TemplatesTab({super.key});

  @override
  State<TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<TemplatesTab> {
  late Future<List<DocumentTemplate>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.getDocumentTemplates();
  }

  Future<void> _reload() async {
    setState(() {
      _future = LocalDatabase.instance.getDocumentTemplates();
    });
  }

  Future<void> _createOrEdit({DocumentTemplate? template}) async {
    final result = await showDialog<DocumentTemplate>(
      context: context,
      builder: (context) => TemplateDialog(template: template),
    );
    if (!mounted) return;
    if (result == null) {
      await _reload();
      return;
    }
    // If canvas: open designer directly.
    if (result.type == 'canvas') {
      await showDialog(
        context: context,
        builder: (_) => TemplateCanvasDialog(template: result),
      );
    }
    await _reload();
  }

  Future<void> _delete(DocumentTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le template ?'),
        content: Text('Supprimer "${template.name}" définitivement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await LocalDatabase.instance.deleteDocumentTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template supprimé')),
        );
      }
      await _reload();
    }
  }

  Future<void> _duplicate(DocumentTemplate template) async {
    final copy = DocumentTemplate(
      id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
      name: '${template.name} (copie)',
      type: template.type,
      content: template.content,
      lastModified: DateTime.now(),
    );
    await LocalDatabase.instance.saveDocumentTemplate(copy);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copie créée')),
      );
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingCard(
          title: 'Templates de documents',
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Factures, reçus, attestations ou canvas personnalisés',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _createOrEdit(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nouveau template',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Restaurer les modèles'),
                          content: const Text(
                            'Réinitialiser les modèles par défaut ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent),
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text('Restaurer'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (ok) {
                    await LocalDatabase.instance.resetDefaultTemplates();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Modèles par défaut restaurés'),
                        ),
                      );
                    }
                    await _reload();
                  }
                },
                icon:
                    const Icon(Icons.restore_page, color: Colors.white70),
                label: const Text(
                  'Restaurer',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<DocumentTemplate>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              final templates = snapshot.data ?? [];
              if (templates.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun template pour le moment.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) =>
                    _TemplateCard(
                  template: templates[index],
                  onEdit: () => _createOrEdit(
                    template: templates[index],
                  ),
                  onDesigner: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => TemplateCanvasDialog(
                        template: templates[index],
                      ),
                    );
                    await _reload();
                  },
                  onDelete: () => _delete(templates[index]),
                  onDuplicate: () => _duplicate(templates[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDesigner,
    required this.onDelete,
    required this.onDuplicate,
  });

  final DocumentTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDesigner;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: template.type == 'canvas' ? onDesigner : onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  template.type == 'canvas'
                      ? CanvasThumbnail(template: template)
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconForType(template.type),
                            color: Colors.white,
                          ),
                        ),
                  const Spacer(),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white70),
                    color: const Color(0xFF334155),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      if (template.type == 'canvas')
                        const PopupMenuItem(
                          value: 'designer',
                          child: Text('Designer'),
                        ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Dupliquer'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'designer':
                          onDesigner();
                          break;
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(template.type.toUpperCase()),
                backgroundColor: Colors.white.withOpacity(0.08),
                labelStyle: const TextStyle(color: Colors.white),
              ),
              const Spacer(),
              Text(
                _lastMod(template.lastModified),
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'facture':
        return Icons.receipt_long;
      case 'recu':
        return Icons.receipt;
      case 'attestation':
        return Icons.verified;
      case 'canvas':
        return Icons.design_services;
      default:
        return Icons.description;
    }
  }

  String _lastMod(DateTime dt) =>
      'Modifié le ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
