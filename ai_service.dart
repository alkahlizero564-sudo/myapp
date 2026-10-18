import 'dart:convert';

import 'package:http/http.dart' as http;

import 'store.dart';
import 'util.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks to Gemini or Claude. Generated apps are ALWAYS Flutter (Dart).
class AiService {
  /// Change here if Google publishes a different model id.
  static const geminiModel = 'gemini-3.8-flash';
  static const claudeModel = 'claude-sonnet-5-5';

  static String _system(AppProject p) => '''
You are a senior Flutter engineer. You write complete Flutter (Dart) Android apps that compile on the first try.

OUTPUT FORMAT (strict). For every file write exactly:
=== FILE: relative/path ===
full file content
=== END ===
Write nothing outside these blocks. No markdown fences.

RULES
- The app is ALWAYS Flutter/Dart, whatever language the description is written in.
- Dart 3 with null safety and Material 3. Use APIs that exist on the current stable Flutter.
- Always include pubspec.yaml and lib/main.dart. The pubspec "name" must be exactly "${p.slug}", with environment sdk ">=3.3.0 <4.0.0", the flutter sdk dependency and flutter: uses-material-design: true. List every package you import.
- Split bigger apps into several files under lib/ (screens, models, services).
- Use only popular, stable pub.dev packages that need no API key to build.
- Never create android/, ios/, web/, .github/ or keys/ files; they are generated. If the app needs Android permissions other than INTERNET, list them one per line in android_permissions.txt, for example android.permission.CAMERA.
- If the description is in Arabic, the whole UI must be Arabic with RTL support.
- Real, working features only: no placeholders, no TODO comments, handle loading and error states.
- Keep data on the device with shared_preferences unless the description asks for a backend.
''';

  static const _reviseExtra = '''

You are EDITING an existing project. Return ONLY the files you changed or added, each with its COMPLETE new content (never partial snippets). Keep everything that already works.
''';

  static const _sqlSystem = '''
You write PostgreSQL for Supabase. Return ONLY SQL, no explanation, no markdown fences.

RULES
- Design the tables the app(s) below need. If there are two apps, design ONE shared schema that both use.
- Idempotent: create table if not exists; add columns with create table only; before every create policy run drop policy if exists.
- Enable row level security on every table and add clear policies using auth.uid() (own rows, plus public read only where the app obviously needs it).
- Use uuid primary keys with default gen_random_uuid(), created_at timestamptz default now().
- NEVER use drop table, drop schema, drop column, truncate, delete from or alter table ... drop.
''';

  static Future<Map<String, String>> generateApp(AppProject p) async {
    final text = await _ask(_system(p), 'Build this app:\n\n${p.description}');
    final files = _parse(text);
    if (!files.containsKey('pubspec.yaml') || !files.containsKey('lib/main.dart')) {
      throw AiException('الرد ناقص: لا يحتوي pubspec.yaml أو lib/main.dart. أعد المحاولة.');
    }
    return files;
  }

  /// Returns only the changed files; the caller merges them.
  static Future<Map<String, String>> reviseApp(
    AppProject p, {
    String instruction = '',
    String? buildLog,
  }) async {
    final b = StringBuffer('CURRENT PROJECT FILES\n');
    p.files.forEach((path, c) => b.write('=== FILE: $path ===\n$c\n=== END ===\n'));
    if (buildLog != null) {
      b.write(
          '\nThe GitHub Actions build FAILED with this log:\n${tail(buildLog, 6000)}\n\n'
          'Find the root cause and fix the Dart code or pubspec.yaml so the build succeeds. '
          'Typical causes: wrong or missing package, bad import, null-safety error, an API that does not exist.\n');
    }
    if (instruction.trim().isNotEmpty) {
      b.write('\nCHANGE REQUEST: $instruction\n');
    }
    if (buildLog == null && instruction.trim().isEmpty) {
      b.write('\nReview the whole project and fix every compile error and bug you can find.\n');
    }
    return _parse(await _ask(_system(p) + _reviseExtra, b.toString()));
  }

  static Future<String> generateSql(List<AppProject> apps) async {
    final b = StringBuffer();
    for (final a in apps) {
      b.write('--- App ${a.id}: ${a.name} ---\nDescription: ${a.description}\nSource:\n');
      a.files.forEach((path, c) {
        if (path.startsWith('lib/')) b.write('// $path\n$c\n');
      });
    }
    return stripSqlFence(await _ask(_sqlSystem, b.toString()));
  }

  static Future<Map<String, String>> integrateSupabase(
    AppProject p,
    String sql,
    String url,
    String anonKey,
  ) async {
    final b = StringBuffer('CURRENT PROJECT FILES\n');
    p.files.forEach((path, c) => b.write('=== FILE: $path ===\n$c\n=== END ===\n'));
    b.write('\nSUPABASE URL: $url\nSUPABASE ANON KEY: $anonKey\n\n'
        'DATABASE SCHEMA (already created):\n$sql\n\n'
        'TASK: connect this app to the Supabase backend with the supabase_flutter package. '
        'Add supabase_flutter to pubspec.yaml, call WidgetsFlutterBinding.ensureInitialized() and '
        'Supabase.initialize(url:, anonKey:) in main(), and read/write the tables above instead of '
        'local storage where it makes sense. Respect the row level security policies (sign the user '
        'in when a policy needs auth.uid()). Never use a service role key. Keep the UI working.\n');
    return _parse(await _ask(_system(p) + _reviseExtra, b.toString()));
  }

  static Map<String, String> _parse(String text) {
    final files = parseFileBlocks(text);
    if (files.isEmpty || countFileMarkers(text) > files.length) {
      throw AiException('الرد جاء ناقصاً أو مقطوعاً. أعد المحاولة، أو بسّط الوصف.');
    }
    return files;
  }

  static Future<String> _ask(String system, String prompt) =>
      Store.i.provider == 'claude' ? _claude(system, prompt) : _gemini(system, prompt);

  /// Tries every Gemini key you saved, moving on when one is rate limited.
  static Future<String> _gemini(String system, String prompt) async {
    final keys = <String>[];
    for (final k in K.gemini) {
      final v = await Store.i.getKey(k);
      if (v.isNotEmpty) keys.add(v);
    }
    if (keys.isEmpty) throw AiException('أضف مفتاح Gemini في قائمة المفاتيح.');

    var last = '';
    for (final key in keys) {
      final res = await http
          .post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent'),
            headers: {
              'content-type': 'application/json',
              'x-goog-api-key': key,
            },
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': system}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 30000},
            }),
          )
          .timeout(const Duration(minutes: 6));
      final text = bodyOf(res);
      if (res.statusCode == 200) {
        final j = jsonDecode(text) as Map<String, dynamic>;
        final first = (j['candidates'] as List?)?.firstOrNull as Map?;
        final parts = (first?['content'] as Map?)?['parts'] as List?;
        final out = parts?.map((e) => (e as Map)['text'] ?? '').join() ?? '';
        if (out.isNotEmpty) return out;
        last = 'رد فارغ من Gemini';
        continue;
      }
      last = 'Gemini ${res.statusCode}: ${tail(text, 300)}';
      if (![429, 500, 503, 403].contains(res.statusCode)) break;
    }
    throw AiException(last);
  }

  static Future<String> _claude(String system, String prompt) async {
    final key = await Store.i.getKey(K.claude);
    if (key.isEmpty) throw AiException('أضف مفتاح Claude في قائمة المفاتيح.');
    final res = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'content-type': 'application/json',
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': claudeModel,
            'max_tokens': 16000,
            'system': system,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }),
        )
        .timeout(const Duration(minutes: 8));
    final text = bodyOf(res);
    if (res.statusCode != 200) {
      throw AiException('Claude ${res.statusCode}: ${tail(text, 300)}');
    }
    final j = jsonDecode(text) as Map<String, dynamic>;
    return (j['content'] as List).map((e) => (e as Map)['text'] ?? '').join();
  }
}
