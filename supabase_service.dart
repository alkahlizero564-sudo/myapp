import 'dart:convert';

import 'package:http/http.dart' as http;

import 'store.dart';
import 'util.dart';

class SupabaseException implements Exception {
  SupabaseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Runs SQL and reads the public key through Supabase's Management API,
/// so you never open the Supabase dashboard.
class SupabaseService {
  static const _api = 'https://api.supabase.com/v1';

  static Future<String> _token() async {
    final t = await Store.i.getKey(K.sbToken);
    if (t.isEmpty) throw SupabaseException('أضف Access Token الخاص بـ Supabase في قائمة المفاتيح.');
    return t;
  }

  static Future<String> ref() async {
    final r = await Store.i.getKey(K.sbRef);
    if (r.isEmpty) throw SupabaseException('أضف Project Ref الخاص بـ Supabase في قائمة المفاتيح.');
    return r;
  }

  static Future<String> url() async => 'https://${await ref()}.supabase.co';

  /// Refuses SQL that would delete data or tables.
  static void ensureSafe(String sql) {
    final bad = RegExp(
      r'\b(drop\s+(table|schema|database|column|function|extension|view|type)|truncate|delete\s+from|alter\s+table\s+\S+\s+drop)\b',
      caseSensitive: false,
    );
    if (bad.hasMatch(sql)) {
      throw SupabaseException('أوقفت التنفيذ: الكود المولّد يحتوي أمراً يحذف بيانات أو جداول.');
    }
  }

  static Future<void> runSql(String sql) async {
    ensureSafe(sql);
    final res = await http
        .post(
          Uri.parse('$_api/projects/${await ref()}/database/query'),
          headers: {
            'Authorization': 'Bearer ${await _token()}',
            'content-type': 'application/json',
          },
          body: jsonEncode({'query': sql}),
        )
        .timeout(const Duration(minutes: 2));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw SupabaseException('Supabase ${res.statusCode}: ${tail(bodyOf(res), 400)}');
    }
  }

  /// The anon (publishable) key. It is safe inside an app because the
  /// row level security policies protect the data. The service role key is
  /// never read or used.
  static Future<String> anonKey() async {
    final res = await http.get(
      Uri.parse('$_api/projects/${await ref()}/api-keys'),
      headers: {'Authorization': 'Bearer ${await _token()}'},
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      throw SupabaseException('Supabase ${res.statusCode}: ${tail(bodyOf(res), 300)}');
    }
    final list = (jsonDecode(bodyOf(res)) as List).cast<Map<String, dynamic>>();
    for (final m in list) {
      if (m['name'] == 'anon') return m['api_key'] as String;
    }
    for (final m in list) {
      if (m['type'] == 'publishable') return m['api_key'] as String;
    }
    throw SupabaseException('لم أجد مفتاح anon في المشروع.');
  }
}
