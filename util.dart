import 'dart:convert';

import 'package:http/http.dart' as http;

/// Always decode as UTF-8 (Arabic text), whatever charset the server sends.
String bodyOf(http.Response r) => utf8.decode(r.bodyBytes, allowMalformed: true);

String tail(String s, int max) => s.length <= max ? s : s.substring(s.length - max);

int countFileMarkers(String text) => RegExp(r'=== FILE: ').allMatches(text).length;

/// Parses the blocks
///   === FILE: path ===
///   content
///   === END ===
/// that the AI is asked to return.
Map<String, String> parseFileBlocks(String text) {
  final re = RegExp(r'=== FILE: (.+?) ===\r?\n([\s\S]*?)\r?\n=== END ===');
  final out = <String, String>{};
  for (final m in re.allMatches(text)) {
    final path = m.group(1)!.trim();
    if (!_safePath(path)) continue;
    final content = _stripFence(m.group(2)!);
    out[path] = content.endsWith('\n') ? content : '$content\n';
  }
  return out;
}

bool _safePath(String p) {
  if (p.isEmpty || p.startsWith('/') || p.contains('..') || p.contains('\\')) {
    return false;
  }
  const blocked = [
    'android/',
    'ios/',
    'web/',
    'linux/',
    'macos/',
    'windows/',
    '.github/',
    'keys/',
  ];
  return !blocked.any((b) => p.startsWith(b));
}

String _stripFence(String c) {
  final t = c.trim();
  if (!t.startsWith('```')) return c;
  final nl = t.indexOf('\n');
  var body = nl == -1 ? '' : t.substring(nl + 1);
  body = body.trimRight();
  if (body.endsWith('```')) body = body.substring(0, body.length - 3);
  return body.trimRight();
}

String stripSqlFence(String s) {
  var t = s.trim();
  if (t.startsWith('```')) {
    final nl = t.indexOf('\n');
    t = nl == -1 ? '' : t.substring(nl + 1);
  }
  if (t.endsWith('```')) t = t.substring(0, t.length - 3);
  return t.trim();
}
