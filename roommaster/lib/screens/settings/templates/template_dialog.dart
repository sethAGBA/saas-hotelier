import 'package:flutter/material.dart';

import '../../../data/local_database.dart';
import '../../../models/document_template.dart';

class TemplateDialog extends StatefulWidget {
  const TemplateDialog({super.key, this.template});

  final DocumentTemplate? template;

  @override
  State<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contentCtrl;
  String _type = 'canvas';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.template?.name ?? '');
    _contentCtrl =
        TextEditingController(text: widget.template?.content ?? '');
    _type = widget.template?.type ?? 'canvas';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<DocumentTemplate?> _save() async {
    if (!_formKey.currentState!.validate()) return null;
    final template = DocumentTemplate(
      id: widget.template?.id ??
          'tpl_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      type: _type,
      content: _type == 'canvas'
          ? (widget.template?.content ?? '{"canvas":[],"doc":{"width":595,"height":842}}')
          : _contentCtrl.text.trim(),
      lastModified: DateTime.now(),
    );
    await LocalDatabase.instance.saveDocumentTemplate(template);
    return template;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1220),
      title: Text(
        widget.template == null
            ? 'Nouveau template'
            : 'Modifier ${widget.template!.name}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem(value: 'facture', child: Text('Facture')),
                  DropdownMenuItem(value: 'recu', child: Text('Reçu')),
                  DropdownMenuItem(
                    value: 'attestation',
                    child: Text('Attestation'),
                  ),
                  DropdownMenuItem(value: 'canvas', child: Text('Canvas')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'canvas'),
              ),
              if (_type != 'canvas') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Contenu',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  maxLines: 5,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Contenu requis'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            final tpl = await _save();
            if (tpl != null && mounted) Navigator.of(context).pop(tpl);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
