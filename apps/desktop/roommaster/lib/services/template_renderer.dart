import 'dart:convert';

/// Replaces {{key}} placeholders in strings using values from [data].
String renderTemplateString(String template, Map<String, dynamic> data) {
  if (template.isEmpty) return template;
  String out = template;

  // Handle {{#each listKey}} ... {{/each}} blocks for simple lists of maps.
  final eachRegex = RegExp(r'{{#each (\\w+)}}(.*?){{\\/each}}', dotAll: true);
  out = out.replaceAllMapped(eachRegex, (match) {
    final listKey = match.group(1);
    final block = match.group(2) ?? '';
    if (listKey == null || data[listKey] is! List) return '';
    final List<dynamic> list = data[listKey];
    final buffer = StringBuffer();
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        String rendered = block;
        item.forEach((k, v) {
          rendered = rendered.replaceAll('{{this.$k}}', v?.toString() ?? '');
        });
        buffer.writeln(rendered);
      }
    }
    return buffer.toString();
  });

  // Flatten nested maps so {{a.b}} works.
  final flat = <String, String>{};
  void flatten(String prefix, dynamic value) {
    if (value is Map<String, dynamic>) {
      value.forEach((k, v) => flatten(prefix.isEmpty ? k : '$prefix.$k', v));
    } else {
      flat[prefix] = value?.toString() ?? '';
    }
  }

  data.forEach((k, v) => flatten(k, v));
  flat.forEach((k, v) {
    out = out.replaceAll('{{${k}}}', v);
  });

  // Also replace top-level keys directly.
  data.forEach((k, v) {
    if (v is! List && v is! Map) {
      out = out.replaceAll('{{${k}}}', v?.toString() ?? '');
    }
  });
  return out;
}

/// Recursively renders JSON content (canvas map or quill delta) with placeholders.
dynamic renderTemplateJsonContent(dynamic content, Map<String, dynamic> data) {
  if (content == null) return content;
  if (content is String) {
    try {
      final parsed = jsonDecode(content);
      return renderTemplateJsonContent(parsed, data);
    } catch (_) {
      return renderTemplateString(content, data);
    }
  }

  if (content is List) {
    return content.map((item) => renderTemplateJsonContent(item, data)).toList();
  }

  if (content is Map) {
    final Map<String, dynamic> out = {};
    content.forEach((k, v) {
      if (k == 'doc') {
        out[k] = v;
      } else if (v is String) {
        out[k] = renderTemplateString(v, data);
      } else if (v is Map || v is List) {
        out[k] = renderTemplateJsonContent(v, data);
      } else {
        out[k] = v;
      }
    });
    return out;
  }
  return content;
}
