import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/local_database.dart';
import '../../../models/document_template.dart';
import '../../../services/template_renderer.dart';

class CanvasElement {
  CanvasElement({
    required this.id,
    required this.type,
    required this.left,
    required this.top,
    this.text = '',
    this.imagePath,
    this.style,
    this.shape = 'rectangle',
    this.width = 160,
    this.height = 40,
    this.rotation = 0,
    this.align = 'left',
  });

  final String id;
  final String type; // text | placeholder | image | shape | qrcode
  double left;
  double top;
  String text;
  String? imagePath;
  Map<String, dynamic>? style;
  String shape;
  double width;
  double height;
  double rotation;
  String align;

  CanvasElement copy() {
    return CanvasElement(
      id: id,
      type: type,
      left: left,
      top: top,
      text: text,
      imagePath: imagePath,
      style: style != null ? Map<String, dynamic>.from(style!) : null,
      shape: shape,
      width: width,
      height: height,
      rotation: rotation,
      align: align,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'left': left,
      'top': top,
      'text': text,
      'imagePath': imagePath,
      'style': style,
      'shape': shape,
      'width': width,
      'height': height,
      'rotation': rotation,
      'align': align,
    };
  }

  static CanvasElement fromJson(Map<String, dynamic> map) {
    return CanvasElement(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'text',
      left: (map['left'] as num?)?.toDouble() ?? 0,
      top: (map['top'] as num?)?.toDouble() ?? 0,
      text: map['text'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      style: map['style'] != null
          ? Map<String, dynamic>.from(map['style'] as Map)
          : null,
      shape: map['shape'] as String? ?? 'rectangle',
      width: (map['width'] as num?)?.toDouble() ?? 160,
      height: (map['height'] as num?)?.toDouble() ?? 40,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
      align: map['align'] as String? ?? 'left',
    );
  }
}

class TemplateCanvasDialog extends StatefulWidget {
  const TemplateCanvasDialog({super.key, required this.template});

  final DocumentTemplate template;

  @override
  State<TemplateCanvasDialog> createState() => _TemplateCanvasDialogState();
}

class _TemplateCanvasDialogState extends State<TemplateCanvasDialog> {
  final List<CanvasElement> _elements = [];
  String? _selectedId;
  double _docWidth = 595; // A4 @72dpi
  double _docHeight = 842;
  Color? _background;

  @override
  void initState() {
    super.initState();
    _loadFromTemplate();
  }

  void _loadFromTemplate() {
    try {
      dynamic content = widget.template.content;
      try {
        content = renderTemplateJsonContent(widget.template.content, {});
      } catch (_) {}
      final parsed = content is String ? jsonDecode(content) : content;
      if (parsed is Map<String, dynamic>) {
        if (parsed['canvas'] is List) {
          for (final el in parsed['canvas']) {
            _elements.add(CanvasElement.fromJson(
              Map<String, dynamic>.from(el as Map),
            ));
          }
        }
        if (parsed['doc'] is Map) {
          final doc = Map<String, dynamic>.from(parsed['doc'] as Map);
          _docWidth = (doc['width'] as num?)?.toDouble() ?? _docWidth;
          _docHeight = (doc['height'] as num?)?.toDouble() ?? _docHeight;
          final bgHex = doc['background'] as String?;
          if (bgHex != null && bgHex.startsWith('#')) {
            _background = _hexToColor(bgHex);
          }
        }
      }
    } catch (_) {
      // ignore parse errors, start fresh
    }
    setState(() {});
  }

  CanvasElement? get _selected {
    for (final el in _elements) {
      if (el.id == _selectedId) return el;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0B1220),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCanvas()),
                  const SizedBox(width: 12),
                  SizedBox(width: 320, child: _buildInspector()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(
            'Designer Canva - ${widget.template.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          _buildActionButton(
            icon: Icons.text_fields,
            label: 'Texte',
            onTap: _addText,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.merge_type,
            label: 'Placeholder',
            onTap: _addPlaceholder,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.image,
            label: 'Image',
            onTap: _addImage,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.crop_square,
            label: 'Shape',
            onTap: () => _addShape('rectangle'),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.qr_code_2,
            label: 'QR',
            onTap: _addQr,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saveTemplate,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth - 16;
        final availableH = constraints.maxHeight - 16;
        final scale = min(
          availableW / _docWidth,
          availableH / _docHeight,
        );
        final canvasW = _docWidth * scale;
        final canvasH = _docHeight * scale;
        return Center(
          child: Container(
            width: canvasW,
            height: canvasH,
            decoration: BoxDecoration(
              color: _background ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: _elements
                  .map(
                    (el) => _buildElement(el, scale),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildElement(CanvasElement el, double scale) {
    final isSelected = el.id == _selectedId;
    final color = _hexToColor(el.style?['color'] as String?) ??
        const Color(0xFF111827);
    final fontSize =
        (el.style?['fontSize'] as num?)?.toDouble() ?? 14.0;
    final fontWeight =
        (el.style?['bold'] == true) ? FontWeight.bold : FontWeight.w500;
    final align = _textAlignFrom(el.align);
    final child = GestureDetector(
      onTap: () => setState(() => _selectedId = el.id),
      onPanUpdate: (d) {
        setState(() {
          el.left += d.delta.dx / scale;
          el.top += d.delta.dy / scale;
        });
      },
      child: Transform.rotate(
        angle: el.rotation * pi / 180,
        child: Container(
          width: el.width * scale,
          height: el.height * scale,
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
              width: 2,
            ),
            color: el.type == 'shape'
                ? _hexToColor(el.style?['color'] as String?)?.withOpacity(0.8) ??
                    Colors.amber.withOpacity(0.3)
                : Colors.transparent,
          ),
          alignment: _alignFrom(el.align),
          padding: const EdgeInsets.all(6),
          child: _buildElementContent(el, color, fontSize, fontWeight, align),
        ),
      ),
    );
    return Positioned(
      left: el.left * scale,
      top: el.top * scale,
      child: child,
    );
  }

  Widget _buildElementContent(
    CanvasElement el,
    Color color,
    double fontSize,
    FontWeight fontWeight,
    TextAlign align,
  ) {
    switch (el.type) {
      case 'image':
        if (el.imagePath != null && el.imagePath!.isNotEmpty) {
          return Image(
            image: kIsWeb
                ? NetworkImage(el.imagePath!)
                : FileImage(File(el.imagePath!)),
            fit: BoxFit.cover,
          );
        }
        return const Icon(Icons.broken_image, color: Colors.grey);
      case 'placeholder':
        return Text(
          el.text.isEmpty ? '{{placeholder}}' : el.text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle:
                (el.style?['italic'] == true) ? FontStyle.italic : null,
          ),
          textAlign: align,
        );
      case 'qrcode':
        return const Icon(Icons.qr_code_2, color: Colors.black87, size: 32);
      default:
        return Text(
          el.text.isEmpty ? 'Texte' : el.text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle:
                (el.style?['italic'] == true) ? FontStyle.italic : null,
          ),
          textAlign: align,
        );
    }
  }

  Widget _buildInspector() {
    final el = _selected;
    if (el == null) {
      return _inspectorShell(
        child: const Center(
          child: Text(
            'Sélectionnez un élément pour le modifier',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return _inspectorShell(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  el.type.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _elements.removeWhere((e) => e.id == el.id);
                      _selectedId = null;
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                ),
              ],
            ),
            if (el.type != 'image') ...[
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: el.text),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: el.type == 'placeholder'
                      ? 'Placeholder (ex: {{guest_name}})'
                      : 'Texte',
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
                onChanged: (v) => el.text = v,
              ),
            ],
            const SizedBox(height: 8),
            _buildLabeledSlider(
              label: 'Largeur',
              value: el.width,
              min: 40,
              max: _docWidth,
              onChanged: (v) => setState(() => el.width = v),
            ),
            _buildLabeledSlider(
              label: 'Hauteur',
              value: el.height,
              min: 20,
              max: _docHeight,
              onChanged: (v) => setState(() => el.height = v),
            ),
            _buildLabeledSlider(
              label: 'Rotation',
              value: el.rotation,
              min: -45,
              max: 45,
              onChanged: (v) => setState(() => el.rotation = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Alignement',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            Wrap(
              spacing: 6,
              children: [
                'left',
                'center',
                'right',
              ]
                  .map(
                    (a) => ChoiceChip(
                      label: Text(a),
                      selected: el.align == a,
                      onSelected: (_) => setState(() => el.align = a),
                      labelStyle: const TextStyle(color: Colors.white),
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: Colors.white.withOpacity(0.06),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Couleur',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _palette
                  .map(
                    (c) => GestureDetector(
                      onTap: () {
                        el.style ??= {};
                        el.style!['color'] = c.value.toRadixString(16).padLeft(
                              8,
                              '0',
                            ).substring(2);
                        setState(() {});
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (el.type == 'text' || el.type == 'placeholder') ...[
              const SizedBox(height: 8),
              _buildLabeledSlider(
                label: 'Taille texte',
                value: (el.style?['fontSize'] as num?)?.toDouble() ?? 14,
                min: 8,
                max: 48,
                onChanged: (v) {
                  el.style ??= {};
                  el.style!['fontSize'] = v;
                  setState(() {});
                },
              ),
              Row(
                children: [
                  Checkbox(
                    value: el.style?['bold'] == true,
                    onChanged: (v) {
                      el.style ??= {};
                      el.style!['bold'] = v ?? false;
                      setState(() {});
                    },
                  ),
                  const Text('Gras', style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  Checkbox(
                    value: el.style?['italic'] == true,
                    onChanged: (v) {
                      el.style ??= {};
                      el.style!['italic'] = v ?? false;
                      setState(() {});
                    },
                  ),
                  const Text('Italique',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inspectorShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
    );
  }

  Widget _buildLabeledSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${value.toStringAsFixed(0)})',
          style: const TextStyle(color: Colors.white70),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Future<void> _addText() async {
    setState(() {
      final el = CanvasElement(
        id: 'el_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        left: 40,
        top: 40,
        text: 'Texte libre',
        style: {'color': '111827', 'fontSize': 16},
      );
      _elements.add(el);
      _selectedId = el.id;
    });
  }

  Future<void> _addPlaceholder() async {
    final ctrl = TextEditingController(text: '{{placeholder}}');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Placeholder'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '{{guest_name}}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, ctrl.text.trim().isEmpty ? null : ctrl.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (value == null) return;
    setState(() {
      final el = CanvasElement(
        id: 'el_${DateTime.now().millisecondsSinceEpoch}',
        type: 'placeholder',
        left: 50,
        top: 60,
        text: value,
        style: {'color': '0F172A', 'fontSize': 14},
      );
      _elements.add(el);
      _selectedId = el.id;
    });
  }

  Future<void> _addImage() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image);
      if (res == null || res.files.isEmpty) return;
      final path = res.files.single.path;
      if (path == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = await Directory('${appDir.path}/template_images')
          .create(recursive: true);
      final ext = p.extension(path);
      final dest = p.join(
        imagesDir.path,
        'tpl_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await File(path).copy(dest);

      setState(() {
        final el = CanvasElement(
          id: 'el_${DateTime.now().millisecondsSinceEpoch}',
          type: 'image',
          left: 60,
          top: 60,
          width: 180,
          height: 120,
          imagePath: dest,
        );
        _elements.add(el);
        _selectedId = el.id;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger l\'image: $e')),
        );
      }
    }
  }

  Future<void> _addShape(String shape) async {
    setState(() {
      final el = CanvasElement(
        id: 'el_${DateTime.now().millisecondsSinceEpoch}',
        type: 'shape',
        left: 70,
        top: 70,
        width: 140,
        height: 60,
        shape: shape,
        style: {'color': 'E5A81B'},
      );
      _elements.add(el);
      _selectedId = el.id;
    });
  }

  Future<void> _addQr() async {
    setState(() {
      final el = CanvasElement(
        id: 'el_${DateTime.now().millisecondsSinceEpoch}',
        type: 'qrcode',
        left: 80,
        top: 80,
        width: 120,
        height: 120,
        text: 'https://example.com',
      );
      _elements.add(el);
      _selectedId = el.id;
    });
  }

  Future<void> _saveTemplate() async {
    final doc = <String, dynamic>{
      'width': _docWidth,
      'height': _docHeight,
      if (_background != null) 'background': _colorToHex(_background!),
    };
    final jsonContent = jsonEncode({
      'canvas': _elements.map((e) => e.toJson()).toList(),
      'doc': doc,
    });
    final updated = DocumentTemplate(
      id: widget.template.id,
      name: widget.template.name,
      type: widget.template.type,
      content: jsonContent,
      lastModified: DateTime.now(),
    );
    await LocalDatabase.instance.saveDocumentTemplate(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template sauvegardé')),
      );
      Navigator.of(context).pop(updated);
    }
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final value = hex.replaceAll('#', '');
    if (value.length != 6) return null;
    final r = int.parse(value.substring(0, 2), radix: 16);
    final g = int.parse(value.substring(2, 4), radix: 16);
    final b = int.parse(value.substring(4, 6), radix: 16);
    return Color.fromARGB(255, r, g, b);
  }

  String _colorToHex(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}';

  TextAlign _textAlignFrom(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Alignment _alignFrom(String align) {
    switch (align) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  List<Color> get _palette => const [
        Color(0xFF0F172A),
        Color(0xFF111827),
        Color(0xFF1E293B),
        Color(0xFF6366F1),
        Color(0xFF8B5CF6),
        Color(0xFF10B981),
        Color(0xFF0EA5E9),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
        Color(0xFFF3F4F6),
        Color(0xFFFFFFFF),
      ];
}
