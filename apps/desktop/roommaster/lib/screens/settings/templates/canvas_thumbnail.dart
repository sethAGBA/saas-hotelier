import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/document_template.dart';

class CanvasThumbnail extends StatelessWidget {
  const CanvasThumbnail({
    super.key,
    required this.template,
    this.width = 72,
    this.height = 72,
  });

  final DocumentTemplate template;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    try {
      final parsed = jsonDecode(template.content);
      if (parsed is Map && parsed['canvas'] is List) {
        final canvas = List<Map<String, dynamic>>.from(
          (parsed['canvas'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        final doc = parsed['doc'] as Map?;
        final docW = (doc?['width'] as num?)?.toDouble() ?? 595.0;
        final docH = (doc?['height'] as num?)?.toDouble() ?? 842.0;
        final aspect = docW > 0 ? docW / docH : 595 / 842;
        return SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: aspect,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: canvas.take(8).map((m) {
                  final left = (m['left'] as num?)?.toDouble() ?? 0.0;
                  final top = (m['top'] as num?)?.toDouble() ?? 0.0;
                  final w = (m['width'] as num?)?.toDouble() ?? 80.0;
                  final h = (m['height'] as num?)?.toDouble() ?? 20.0;
                  final text = (m['text'] as String?) ?? (m['type'] as String? ?? '');
                  return Positioned(
                    left: (left / docW) * width,
                    top: (top / docH) * (width / aspect),
                    child: Container(
                      width: (w / docW) * width,
                      height: (h / docH) * (width / aspect),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        text.length > 18 ? '${text.substring(0, 18)}…' : text,
                        style: const TextStyle(fontSize: 8, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      // ignore parsing errors, show fallback
    }
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.grid_view, color: Colors.white70),
      ),
    );
  }
}
