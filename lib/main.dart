import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' show ZipDecoder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ===== theme.dart =====
const kBg = Color(0xFF0F1720);
const kCard = Color(0xFF17212C);
const kLine = Color(0xFF263341);
const kField = Color(0xFF2F3F50);
const kAccent = Color(0xFF22B8A6);
const kMuted = Color(0xFF8FA1B3);
const kWarn = Color(0xFFF2B84B);
const kBad = Color(0xFFE5645A);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kAccent,
    brightness: Brightness.dark,
  ).copyWith(
    surface: kBg,
    primary: kAccent,
    onPrimary: const Color(0xFF06201C),
  );

  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBg,
      border: border(kField),
      enabledBorder: border(kField),
      focusedBorder: border(kAccent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: kField),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: kCard,
    ),
  );
}

/// Rounded dark panel used instead of Card, so the look does not depend on
/// the Flutter version's CardTheme API.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: child,
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, color: kMuted)),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });

  final String kicker;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: const TextStyle(fontSize: 13, color: kMuted)),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(fontSize: 14, height: 1.6, color: kMuted)),
      ],
    );
  }
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// ===== util.dart =====
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

// ===== store.dart =====
/// Names of the secure-storage entries (the keys list screen).
class K {
  static const ghToken = 'gh_token';
  static const ghRepo = 'gh_repo';
  static const sbToken = 'sb_token';
  static const sbRef = 'sb_ref';
  static const claude = 'claude_key';
  static const gemini = ['gemini_0', 'gemini_1', 'gemini_2', 'gemini_3', 'gemini_4'];

  static List<String> get all =>
      [ghToken, ghRepo, sbToken, sbRef, claude, ...gemini];
}

/// One of the two apps the user builds (id 1 or 2).
class AppProject {
  AppProject({
    required this.id,
    this.name = '',
    this.description = '',
    Map<String, String>? files,
    this.iconPath,
    this.supabaseLinked = false,
  }) : files = files ?? {};

  final int id;
  String name;
  String description;
  final Map<String, String> files;
  String? iconPath;
  bool supabaseLinked;

  /// Bumped whenever the files are replaced, so the editor can refresh.
  int rev = 0;

  /// Folder / Dart package name inside the repo. Fixed, so the Android
  /// package name never changes and new builds install over old ones.
  String get slug => 'app$id';

  /// APK file name = the name the user typed.
  String get fileName {
    final cleaned = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    return cleaned.isEmpty ? slug : cleaned;
  }

  void replaceFiles(Map<String, String> next) {
    files
      ..clear()
      ..addAll(next);
    final pubspec = files['pubspec.yaml'];
    if (pubspec != null) {
      files['pubspec.yaml'] = pubspec.replaceFirst(
        RegExp(r'^name:\s*.*$', multiLine: true),
        'name: $slug',
      );
    }
    rev++;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'files': files,
        'iconPath': iconPath,
        'supabaseLinked': supabaseLinked,
      };

  factory AppProject.fromJson(Map<String, dynamic> j) => AppProject(
        id: j['id'] as int,
        name: (j['name'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        files: ((j['files'] as Map?) ?? {})
            .map((k, v) => MapEntry(k as String, v as String)),
        iconPath: j['iconPath'] as String?,
        supabaseLinked: (j['supabaseLinked'] as bool?) ?? false,
      );
}

class Store extends ChangeNotifier {
  Store._();
  static final Store i = Store._();

  final _secure = const FlutterSecureStorage();
  final List<AppProject> projects = [AppProject(id: 1), AppProject(id: 2)];

  /// 'gemini' or 'claude': which AI writes the code.
  String provider = 'gemini';

  Directory? _dir;
  bool _loaded = false;

  Future<Directory> get dir async =>
      _dir ??= await getApplicationDocumentsDirectory();

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = File('${(await dir).path}/projects.json');
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        provider = (j['provider'] as String?) ?? 'gemini';
        final list = ((j['projects'] as List?) ?? []).cast<Map<String, dynamic>>();
        for (final m in list) {
          final p = AppProject.fromJson(m);
          final idx = projects.indexWhere((e) => e.id == p.id);
          if (idx >= 0) projects[idx] = p;
        }
      }
    } catch (_) {
      // A corrupt file just means we start empty.
    }
    notifyListeners();
  }

  Future<void> _write() async {
    final f = File('${(await dir).path}/projects.json');
    await f.writeAsString(jsonEncode({
      'provider': provider,
      'projects': projects.map((p) => p.toJson()).toList(),
    }));
  }

  /// Save and refresh the screens.
  Future<void> save() async {
    await _write();
    notifyListeners();
  }

  /// Save without rebuilding the screens (used while typing).
  Future<void> saveQuiet() => _write();

  Future<String> getKey(String k) async => (await _secure.read(key: k)) ?? '';

  Future<void> setKey(String k, String v) async {
    if (v.trim().isEmpty) {
      await _secure.delete(key: k);
    } else {
      await _secure.write(key: k, value: v.trim());
    }
  }

  Future<void> setIcon(AppProject p, String pickedPath) async {
    final d = await dir;
    final dest = File(
        '${d.path}/icon_${p.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(pickedPath).copy(dest.path);
    final old = p.iconPath;
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    p.iconPath = dest.path;
    await save();
  }
}

// ===== ai_service.dart =====
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

// ===== workflow_template.dart =====
/// The GitHub Actions workflow that the app pushes to
/// .github/workflows/build.yml in your repo before every build.
///
/// - Creates the android/ and web/ folders (flutter create) around the
///   generated lib/ and pubspec.yaml.
/// - Sets the app name, INTERNET permission, extra permissions and icon.
/// - Creates ONE signing key per app the first time (keys/appN.jks) and
///   reuses it afterwards, so every new APK installs over the old one.
const buildWorkflowYaml = r'''
name: build

on:
  workflow_dispatch:
    inputs:
      app:
        description: "app folder"
        required: true
      label:
        description: "app name"
        required: true
      mode:
        description: "apk or web"
        required: true
        default: apk

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 40
    env:
      APP: ${{ inputs.app }}
      LABEL: ${{ inputs.label }}
      MODE: ${{ inputs.mode }}
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Create platform folders
        working-directory: apps/${{ inputs.app }}
        run: |
          set -e
          rm -rf /tmp/bak && mkdir -p /tmp/bak
          cp -r lib /tmp/bak/lib
          cp pubspec.yaml /tmp/bak/pubspec.yaml
          flutter create . --org com.myapps --project-name "$APP" --platforms=android,web
          rm -rf lib && cp -r /tmp/bak/lib lib
          cp /tmp/bak/pubspec.yaml pubspec.yaml
          flutter pub get

      - name: App name and permissions
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}
        run: |
          python3 - <<'PY'
          import os, re
          p = "android/app/src/main/AndroidManifest.xml"
          s = open(p, encoding="utf-8").read()
          label = os.environ["LABEL"].replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;")
          s = re.sub(r'android:label="[^"]*"', 'android:label="' + label + '"', s, count=1)
          perms = ["android.permission.INTERNET"]
          if os.path.exists("android_permissions.txt"):
              for line in open("android_permissions.txt", encoding="utf-8"):
                  line = line.strip()
                  if re.fullmatch(r"android\.permission\.[A-Z_]+", line) and line not in perms:
                      perms.append(line)
          add = "".join('    <uses-permission android:name="%s"/>\n' % x for x in perms if x not in s)
          s = s.replace("<application", add + "    <application", 1)
          open(p, "w", encoding="utf-8").write(s)
          PY

      - name: Launcher icon
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}
        run: |
          if [ -f icon.png ]; then
            flutter pub add dev:flutter_launcher_icons
            printf '\nflutter_launcher_icons:\n  android: true\n  ios: false\n  image_path: "icon.png"\n' >> pubspec.yaml
            dart run flutter_launcher_icons
          fi

      - name: Fixed signing key for this app
        if: env.MODE == 'apk'
        run: |
          set -e
          mkdir -p keys
          KS="keys/${APP}.jks"
          if [ ! -f "$KS" ]; then
            PASS=$(openssl rand -hex 16)
            keytool -genkeypair -keystore "$KS" -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass "$PASS" -keypass "$PASS" -dname "CN=${APP}, O=My apps, C=SD"
            echo "$PASS" > "keys/${APP}.pass"
            git config user.name "github-actions"
            git config user.email "actions@github.com"
            git add keys
            git commit -m "add signing key for ${APP}"
            git push
          fi
          PASS=$(cat "keys/${APP}.pass")
          cat > "apps/${APP}/android/key.properties" <<EOF
          storePassword=$PASS
          keyPassword=$PASS
          keyAlias=upload
          storeFile=$GITHUB_WORKSPACE/$KS
          EOF

      - name: Sign release builds with that key
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}/android/app
        run: |
          python3 - <<'PY'
          import os, re
          kts = os.path.exists("build.gradle.kts")
          p = "build.gradle.kts" if kts else "build.gradle"
          s = open(p, encoding="utf-8").read()
          if "keystoreProperties" not in s:
              if kts:
                  head = "import java.util.Properties\nimport java.io.FileInputStream\n\n"
                  load = 'val keystoreProperties = Properties()\nval keystorePropertiesFile = rootProject.file("key.properties")\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n}\n\n'
                  signing = '    signingConfigs {\n        create("release") {\n            keyAlias = keystoreProperties["keyAlias"] as String\n            keyPassword = keystoreProperties["keyPassword"] as String\n            storeFile = file(keystoreProperties["storeFile"] as String)\n            storePassword = keystoreProperties["storePassword"] as String\n        }\n    }\n'
                  s = head + s
                  s = s.replace("android {", load + "android {\n" + signing, 1)
                  s = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")', s)
                  ok = 'getByName("release")' in s
              else:
                  load = "def keystoreProperties = new Properties()\ndef keystorePropertiesFile = rootProject.file('key.properties')\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n}\n\n"
                  signing = "    signingConfigs {\n        release {\n            keyAlias keystoreProperties['keyAlias']\n            keyPassword keystoreProperties['keyPassword']\n            storeFile file(keystoreProperties['storeFile'])\n            storePassword keystoreProperties['storePassword']\n        }\n    }\n"
                  s = s.replace("android {", load + "android {\n" + signing, 1)
                  s = re.sub(r'signingConfig\s+signingConfigs\.debug', 'signingConfig signingConfigs.release', s)
                  ok = "signingConfigs.release" in s
              if not ok:
                  raise SystemExit("Could not patch the release signing config")
              open(p, "w", encoding="utf-8").write(s)
          PY

      - name: Build APK
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}
        run: |
          flutter build apk --release
          mkdir -p dist
          cp build/app/outputs/flutter-apk/app-release.apk dist/app.apk

      - name: Build web preview
        if: env.MODE == 'web'
        working-directory: apps/${{ inputs.app }}
        run: flutter build web --release

      - name: Upload APK
        if: env.MODE == 'apk'
        uses: actions/upload-artifact@v4
        with:
          name: apk-${{ inputs.app }}
          path: apps/${{ inputs.app }}/dist/app.apk
          retention-days: 7

      - name: Upload web preview
        if: env.MODE == 'web'
        uses: actions/upload-artifact@v4
        with:
          name: web-${{ inputs.app }}
          path: apps/${{ inputs.app }}/build/web
          retention-days: 3
''';

// ===== github_service.dart =====
class GitHubException implements Exception {
  GitHubException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RunResult {
  RunResult(this.id, this.conclusion);
  final int id;
  final String conclusion;
}

/// Everything about GitHub, done from inside the app: create the repo,
/// push the files, start the workflow, wait, read logs, download results.
class GitHubService {
  GitHubService._(this.token, this.owner, this.repo);

  final String token;
  String owner;
  String repo;
  String branch = 'main';

  static const _api = 'https://api.github.com';

  static Future<GitHubService> create() async {
    final token = await Store.i.getKey(K.ghToken);
    var repo = await Store.i.getKey(K.ghRepo);
    if (token.isEmpty) {
      throw GitHubException('أضف GitHub Access Token في قائمة المفاتيح.');
    }
    if (repo.isEmpty) repo = 'myapp';
    final s = GitHubService._(token, '', repo);
    if (repo.contains('/')) {
      final i = repo.indexOf('/');
      s.owner = repo.substring(0, i);
      s.repo = repo.substring(i + 1);
    } else {
      final me = await s._json('GET', '/user');
      s.owner = me['login'] as String;
    }
    await s._ensureRepo();
    return s;
  }

  Future<http.Response> _send(String method, String path, {Object? body}) async {
    final req = http.Request(method, Uri.parse('$_api$path'));
    req.followRedirects = false;
    req.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    });
    if (body != null) {
      req.headers['content-type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    return http.Response.fromStream(streamed);
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Object? body,
    List<int> ok = const [200, 201],
  }) async {
    final r = await _send(method, path, body: body);
    if (!ok.contains(r.statusCode)) {
      throw GitHubException('GitHub ${r.statusCode}: ${tail(bodyOf(r), 300)}');
    }
    final t = bodyOf(r);
    if (t.isEmpty) return {};
    final d = jsonDecode(t);
    return d is Map<String, dynamic> ? d : {'items': d};
  }

  Future<void> _ensureRepo() async {
    final r = await _send('GET', '/repos/$owner/$repo');
    if (r.statusCode == 200) {
      final m = jsonDecode(bodyOf(r)) as Map<String, dynamic>;
      branch = (m['default_branch'] as String?) ?? 'main';
      return;
    }
    if (r.statusCode != 404) {
      throw GitHubException('GitHub ${r.statusCode}: ${tail(bodyOf(r), 300)}');
    }
    // Missing: create it as a PRIVATE repo (the signing keys live inside).
    final c = await _send('POST', '/user/repos', body: {
      'name': repo,
      'private': true,
      'auto_init': true,
      'description': 'Apps built by My apps',
    });
    if (c.statusCode != 201) {
      throw GitHubException('تعذر إنشاء المستودع (${c.statusCode}): ${tail(bodyOf(c), 300)}');
    }
    branch = 'main';
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> putFile(String path, List<int> bytes, String message) async {
    final enc = path.split('/').map(Uri.encodeComponent).join('/');
    final newB64 = base64Encode(bytes);
    String? sha;
    final g = await _send('GET', '/repos/$owner/$repo/contents/$enc?ref=$branch');
    if (g.statusCode == 200) {
      final m = jsonDecode(bodyOf(g)) as Map<String, dynamic>;
      sha = m['sha'] as String?;
      final old = ((m['content'] as String?) ?? '').replaceAll('\n', '');
      if (old == newB64) return; // unchanged, no commit needed
    } else if (g.statusCode != 404) {
      throw GitHubException('GitHub ${g.statusCode}: ${tail(bodyOf(g), 300)}');
    }
    final p = await _send('PUT', '/repos/$owner/$repo/contents/$enc', body: {
      'message': message,
      'content': newB64,
      'branch': branch,
      if (sha != null) 'sha': sha,
    });
    if (p.statusCode != 200 && p.statusCode != 201) {
      final hint = path.startsWith('.github/')
          ? ' (الـ Token يحتاج صلاحيتي repo و workflow)'
          : '';
      throw GitHubException('تعذر رفع $path (${p.statusCode})$hint: ${tail(bodyOf(p), 300)}');
    }
  }

  Future<void> pushProject(AppProject p) async {
    await putFile('.github/workflows/build.yml', utf8.encode(buildWorkflowYaml),
        'update build workflow');
    for (final e in p.files.entries) {
      await putFile('apps/${p.slug}/${e.key}', utf8.encode(e.value),
          'update ${p.slug}');
    }
    final icon = p.iconPath;
    if (icon != null && File(icon).existsSync()) {
      await putFile('apps/${p.slug}/icon.png', await File(icon).readAsBytes(),
          'icon ${p.slug}');
    }
  }

  Future<void> dispatch(AppProject p, String mode) async {
    final body = {
      'ref': branch,
      'inputs': {
        'app': p.slug,
        'label': p.name.trim().isEmpty ? p.slug : p.name.trim(),
        'mode': mode,
      },
    };
    // A workflow file that was just pushed can take a few seconds to register.
    for (var i = 0; i < 6; i++) {
      final r = await _send(
          'POST', '/repos/$owner/$repo/actions/workflows/build.yml/dispatches',
          body: body);
      if (r.statusCode == 204) return;
      if ((r.statusCode == 404 || r.statusCode == 422) && i < 5) {
        await Future.delayed(const Duration(seconds: 4));
        continue;
      }
      throw GitHubException('تعذر تشغيل البناء (${r.statusCode}): ${tail(bodyOf(r), 300)}');
    }
  }

  Future<RunResult> waitForRun(DateTime since, {void Function(String)? onStatus}) async {
    int? found;
    for (var i = 0; i < 40 && found == null; i++) {
      await Future.delayed(const Duration(seconds: 4));
      final j = await _json('GET',
          '/repos/$owner/$repo/actions/workflows/build.yml/runs?event=workflow_dispatch&per_page=10');
      for (final r in (j['workflow_runs'] as List? ?? [])) {
        final m = r as Map<String, dynamic>;
        final created = DateTime.parse(m['created_at'] as String);
        if (!created.isBefore(since.subtract(const Duration(seconds: 10)))) {
          found = m['id'] as int;
          break;
        }
      }
    }
    if (found == null) throw GitHubException('لم يبدأ البناء على GitHub.');
    final runId = found;
    final deadline = DateTime.now().add(const Duration(minutes: 35));
    while (DateTime.now().isBefore(deadline)) {
      final j = await _json('GET', '/repos/$owner/$repo/actions/runs/$runId');
      final status = j['status'] as String?;
      onStatus?.call(status == 'queued' ? 'في قائمة الانتظار…' : 'البناء جارٍ…');
      if (status == 'completed') {
        return RunResult(runId, (j['conclusion'] as String?) ?? 'unknown');
      }
      await Future.delayed(const Duration(seconds: 10));
    }
    throw GitHubException('انتهت مهلة البناء.');
  }

  Future<String> failureLog(int runId) async {
    final j = await _json('GET', '/repos/$owner/$repo/actions/runs/$runId/jobs');
    for (final x in (j['jobs'] as List? ?? [])) {
      final m = x as Map<String, dynamic>;
      if (m['conclusion'] != 'failure') continue;
      final steps = ((m['steps'] as List?) ?? []).cast<Map<String, dynamic>>();
      final failed = steps
          .where((s) => s['conclusion'] == 'failure')
          .map((s) => s['name'])
          .join(', ');
      final bytes = await _download('/repos/$owner/$repo/actions/jobs/${m['id']}/logs');
      final text = utf8.decode(bytes, allowMalformed: true);
      return 'Failed step: $failed\n${tail(text, 7000)}';
    }
    return 'No failed job log was found.';
  }

  Future<List<int>> artifactZip(int runId, String name) async {
    final j = await _json('GET', '/repos/$owner/$repo/actions/runs/$runId/artifacts');
    for (final a in (j['artifacts'] as List? ?? [])) {
      final m = a as Map<String, dynamic>;
      if (m['name'] == name) {
        return _download('/repos/$owner/$repo/actions/artifacts/${m['id']}/zip');
      }
    }
    throw GitHubException('لم ينتج البناء الملف المطلوب ($name).');
  }

  /// GitHub answers with a redirect to a signed URL. Follow it by hand so the
  /// Authorization header is NOT sent to the storage host.
  Future<List<int>> _download(String path) async {
    final r = await _send('GET', path);
    if (r.statusCode == 301 || r.statusCode == 302 || r.statusCode == 307) {
      final loc = r.headers['location'];
      if (loc == null) throw GitHubException('رابط التنزيل غير موجود.');
      final d = await http.get(Uri.parse(loc)).timeout(const Duration(minutes: 5));
      if (d.statusCode != 200) {
        throw GitHubException('فشل التنزيل (${d.statusCode}).');
      }
      return d.bodyBytes;
    }
    if (r.statusCode == 200) return r.bodyBytes;
    throw GitHubException('فشل التنزيل (${r.statusCode}): ${tail(bodyOf(r), 200)}');
  }
}

// ===== supabase_service.dart =====
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

// ===== build_service.dart =====
enum Stage { push, building, fixing, done }

typedef Report = void Function(Stage stage, String message);

class BuildFailure implements Exception {
  BuildFailure(this.log);
  final String log;

  @override
  String toString() => 'فشل البناء بعد عدة محاولات. راجع السجل.';
}

class BuildService {
  static const maxAttempts = 3;

  /// Pushes the app, builds it on GitHub ([mode] 'apk' or 'web') and returns
  /// the artifact zip. When a build fails, the AI reads the error log, fixes
  /// the code and the build runs again (up to [maxAttempts] times).
  static Future<List<int>> run(
    AppProject p,
    String mode,
    Report report,
    void Function(String) log,
  ) async {
    if (p.files.isEmpty) throw AiException('ابنِ التطبيق أولاً.');
    final gh = await GitHubService.create();

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      report(Stage.push, 'رفع الملفات إلى المستودع (محاولة $attempt)…');
      await gh.pushProject(p);

      report(Stage.building, 'تشغيل GitHub Actions…');
      final since = DateTime.now().toUtc();
      await gh.dispatch(p, mode);
      final run = await gh.waitForRun(
        since,
        onStatus: (s) => report(Stage.building, s),
      );

      if (run.conclusion == 'success') {
        final zip = await gh.artifactZip(run.id, '$mode-${p.slug}');
        report(Stage.done, 'اكتمل البناء.');
        return zip;
      }

      final failLog = await gh.failureLog(run.id);
      log('--- فشل البناء (محاولة $attempt) ---\n${tail(failLog, 2500)}');
      if (attempt == maxAttempts) throw BuildFailure(failLog);

      report(Stage.fixing, 'الذكاء الاصطناعي يقرأ الخطأ ويصلح الكود…');
      final fixed = await AiService.reviseApp(p, buildLog: failLog);
      p.replaceFiles({...p.files, ...fixed});
      await Store.i.save();
    }
    throw AiException('تعذر إكمال البناء.');
  }
}

/// Reads a zip into name -> bytes (skips folders and unsafe names).
Map<String, List<int>> unzip(List<int> zip) {
  final archive = ZipDecoder().decodeBytes(zip);
  final out = <String, List<int>>{};
  for (final f in archive) {
    if (!f.isFile || f.name.contains('..')) continue;
    out[f.name] = f.content as List<int>;
  }
  return out;
}

// ===== keys_screen.dart =====
class KeysScreen extends StatefulWidget {
  const KeysScreen({super.key});

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  final Map<String, TextEditingController> _c = {
    for (final k in K.all) k: TextEditingController(),
  };
  bool _ready = false;
  String _provider = Store.i.provider;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final k in K.all) {
      _c[k]!.text = await Store.i.getKey(k);
    }
    if (_c[K.ghRepo]!.text.isEmpty) _c[K.ghRepo]!.text = 'myapp';
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _save() async {
    for (final k in K.all) {
      await Store.i.setKey(k, _c[k]!.text);
    }
    Store.i.provider = _provider;
    await Store.i.save();
    if (mounted) snack(context, 'تم حفظ المفاتيح');
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String key, String label, {String? hint, bool secret = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c[key],
        obscureText: secret,
        autocorrect: false,
        enableSuggestions: false,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _section(String title, List<Widget> children, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const ScreenHeader(
          kicker: 'My apps · القائمة 1',
          title: 'المفاتيح',
          subtitle: 'تُحفظ مفاتيحك مشفّرة على جهازك فقط، وتُستخدم للتوليد والبناء والربط.',
        ),
        const SizedBox(height: 18),
        _section('الذكاء الاصطناعي الذي يكتب الكود', [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'gemini', label: Text('Gemini')),
              ButtonSegment(value: 'claude', label: Text('Claude')),
            ],
            selected: {_provider},
            onSelectionChanged: (s) => setState(() => _provider = s.first),
          ),
        ]),
        _section('GitHub', [
          _field(K.ghToken, 'Access Token', hint: 'ghp_••••••••'),
          _field(K.ghRepo, 'اسم المستودع', hint: 'myapp', secret: false),
        ]),
        _section('Supabase', [
          _field(K.sbToken, 'Access Token', hint: 'sbp_••••••••'),
          _field(K.sbRef, 'Project Ref', hint: 'abcdefghijklmnop', secret: false),
        ]),
        _section(
          'Gemini',
          [
            _field(K.gemini[0], 'مفتاح API الأساسي', hint: 'AIza••••••••'),
            for (var i = 1; i < K.gemini.length; i++)
              _field(K.gemini[i], 'مفتاح Gemini ${i + 1} (اختياري)'),
          ],
          trailing: const Text('النموذج: Gemini 3.8 Flash',
              style: TextStyle(fontSize: 12, color: kAccent)),
        ),
        _section('Claude', [
          _field(K.claude, 'مفتاح API', hint: 'sk-ant-••••••••'),
        ]),
        FilledButton(onPressed: _save, child: const Text('حفظ المفاتيح')),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ===== apps_screen.dart =====
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  bool _linking = false;

  /// One shared schema for both apps, created in Supabase automatically.
  Future<void> _linkBoth() async {
    final ps = Store.i.projects;
    if (ps.any((p) => p.files.isEmpty)) {
      snack(context, 'ابنِ التطبيقين أولاً.');
      return;
    }
    setState(() => _linking = true);
    try {
      final sql = await AiService.generateSql(ps);
      await SupabaseService.runSql(sql);
      final url = await SupabaseService.url();
      final key = await SupabaseService.anonKey();
      for (final p in ps) {
        final changed = await AiService.integrateSupabase(p, sql, url, key);
        p.replaceFiles({...p.files, ...changed});
        p.supabaseLinked = true;
      }
      await Store.i.save();
      if (mounted) snack(context, 'تم ربط التطبيقين عبر Supabase.');
    } catch (e) {
      if (mounted) snack(context, '$e');
    }
    if (mounted) setState(() => _linking = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.i,
      builder: (context, _) {
        final ps = Store.i.projects;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(
              kicker: 'My apps · القائمة 2',
              title: 'التطبيقات',
              subtitle: 'صف الفكرة، ودع الذكاء الاصطناعي يبني تطبيق Flutter كاملاً.',
            ),
            const SizedBox(height: 18),
            AppCard(key: const ValueKey(1), project: ps[0], title: 'التطبيق الأول'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _linking ? null : _linkBoth,
              icon: _linking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: const Text('ربط التطبيقين عبر Supabase'),
            ),
            const SizedBox(height: 16),
            AppCard(key: const ValueKey(2), project: ps[1], title: 'التطبيق الثاني'),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class AppCard extends StatefulWidget {
  const AppCard({super.key, required this.project, required this.title});

  final AppProject project;
  final String title;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  final TextEditingController _code = TextEditingController();
  String? _path;
  String? _busy;
  int _rev = -1;
  Timer? _debounce;

  AppProject get p => widget.project;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: p.name);
    _desc = TextEditingController(text: p.description);
    _sync();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _desc.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Refresh the code box after the AI replaced the files.
  void _sync() {
    _rev = p.rev;
    final paths = p.files.keys.toList()..sort();
    if (_path == null || !p.files.containsKey(_path)) {
      _path = paths.contains('lib/main.dart')
          ? 'lib/main.dart'
          : (paths.isEmpty ? null : paths.first);
    }
    _code.text = _path == null ? '' : (p.files[_path] ?? '');
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), Store.i.saveQuiet);
  }

  Future<void> _run(String label, Future<void> Function() job) async {
    setState(() => _busy = label);
    try {
      await job();
    } catch (e) {
      if (mounted) snack(context, '$e');
    }
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _pickIcon() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 92,
    );
    if (x == null) return;
    await Store.i.setIcon(p, x.path);
  }

  Future<void> _generate() => _run('جارٍ بناء تطبيق Flutter بالذكاء الاصطناعي…', () async {
        if (p.description.trim().isEmpty) {
          throw AiException('اكتب وصف التطبيق أولاً.');
        }
        final files = await AiService.generateApp(p);
        p.supabaseLinked = false;
        p.replaceFiles(files);
        await Store.i.save();
      });

  Future<void> _revise() async {
    if (p.files.isEmpty) {
      snack(context, 'ابنِ التطبيق أولاً.');
      return;
    }
    final ctl = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تعديل وإصلاح الكود'),
        content: TextField(
          controller: ctl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'اكتب التعديل المطلوب، أو اتركه فارغاً ليفحص الكود ويصلح الأخطاء تلقائياً',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ابدأ')),
        ],
      ),
    );
    final instruction = ctl.text;
    ctl.dispose();
    if (go != true) return;
    await _run('جارٍ التعديل والإصلاح…', () async {
      final changed = await AiService.reviseApp(p, instruction: instruction);
      p.replaceFiles({...p.files, ...changed});
      await Store.i.save();
    });
  }

  Future<void> _linkSupabase() => _run('أجهّز Supabase…', () async {
        if (p.files.isEmpty) throw AiException('ابنِ التطبيق أولاً.');
        final sql = await AiService.generateSql([p]);
        await SupabaseService.runSql(sql);
        final url = await SupabaseService.url();
        final key = await SupabaseService.anonKey();
        final changed = await AiService.integrateSupabase(p, sql, url, key);
        p.replaceFiles({...p.files, ...changed});
        p.supabaseLinked = true;
        await Store.i.save();
        if (mounted) snack(context, 'تم الربط وإنشاء الجداول والصلاحيات.');
      });

  void _preview() {
    if (p.files.isEmpty) {
      snack(context, 'ابنِ التطبيق أولاً.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreviewScreen(project: p)),
    );
  }

  Widget _icon() {
    final path = p.iconPath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: p.id == 1 ? const Color(0xFF1F7A6E) : const Color(0xFF8A5A1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.phone_android, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rev != p.rev) _sync();
    final paths = p.files.keys.toList()..sort();
    final busy = _busy != null;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _icon(),
              const SizedBox(width: 14),
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy ? null : _pickIcon,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('اختيار الأيقونة من المعرض'),
          ),
          const SizedBox(height: 14),
          const FieldLabel('اسم التطبيق (هو اسم ملف الـ APK)'),
          TextField(
            controller: _name,
            onChanged: (v) {
              p.name = v;
              _scheduleSave();
            },
            decoration: const InputDecoration(hintText: 'مثال: متجري'),
          ),
          const SizedBox(height: 14),
          const FieldLabel('1 · وصف التطبيق (يُبنى دائماً بـ Flutter)'),
          TextField(
            controller: _desc,
            minLines: 3,
            maxLines: 6,
            onChanged: (v) {
              p.description = v;
              _scheduleSave();
            },
            decoration: const InputDecoration(hintText: 'اكتب فكرة التطبيق هنا…'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: busy ? null : _generate,
            child: const Text('ابنِ تطبيق Flutter بالذكاء الاصطناعي'),
          ),
          const SizedBox(height: 16),
          const FieldLabel('2 · الكود (Flutter)'),
          if (paths.isEmpty)
            const Text('سيظهر الكود المولّد هنا.', style: TextStyle(color: kMuted))
          else ...[
            DropdownButton<String>(
              value: _path,
              isExpanded: true,
              items: [
                for (final x in paths) DropdownMenuItem(value: x, child: Text(x, textDirection: TextDirection.ltr)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _path = v;
                  _code.text = p.files[v] ?? '';
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _code,
              minLines: 8,
              maxLines: 14,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              onChanged: (v) {
                final path = _path;
                if (path != null) p.files[path] = v;
                _scheduleSave();
              },
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : _preview,
                  child: const Text('معاينة فعلية'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : _revise,
                  child: const Text('تعديل وإصلاح الكود'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'المعاينة تُبنى كنسخة ويب عبر GitHub وتظهر داخل التطبيق.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _linkSupabase,
            icon: Icon(p.supabaseLinked ? Icons.check_circle : Icons.cloud_outlined),
            label: Text('ربط ${widget.title} بـ Supabase'),
          ),
          const SizedBox(height: 4),
          const Text(
            'ينشئ SQL والجداول والصلاحيات تلقائياً دون فتح Supabase.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
          if (busy) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Expanded(child: Text(_busy!, style: const TextStyle(color: kAccent))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===== build_screen.dart =====
class BuildScreen extends StatefulWidget {
  const BuildScreen({super.key});

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  static const _labels = {
    Stage.push: 'رفع الملفات إلى المستودع',
    Stage.building: 'بناء APK عبر GitHub Actions',
    Stage.fixing: 'فحص الأخطاء وإصلاحها تلقائياً',
    Stage.done: 'جاهز للتنزيل',
  };

  int _sel = 0;
  bool _busy = false;
  final Map<Stage, String> _status = {
    for (final s in Stage.values) s: 'بانتظار',
  };
  final StringBuffer _log = StringBuffer();
  String? _apkPath;

  void _report(Stage s, String msg) {
    if (!mounted) return;
    setState(() {
      if (s == Stage.push) {
        for (final k in Stage.values) {
          _status[k] = 'بانتظار';
        }
      }
      for (final k in Stage.values) {
        if (k.index < s.index) _status[k] = 'تم';
      }
      if (s == Stage.fixing) _status[Stage.building] = 'فشل';
      _status[s] = s == Stage.done ? 'تم' : 'جارٍ…';
      _log.writeln(msg);
    });
  }

  Future<void> _build() async {
    final p = Store.i.projects[_sel];
    setState(() {
      _busy = true;
      _apkPath = null;
      _log.clear();
      for (final k in Stage.values) {
        _status[k] = 'بانتظار';
      }
    });
    try {
      final zip = await BuildService.run(p, 'apk', _report, (t) {
        if (mounted) setState(() => _log.writeln(t));
      });
      final files = unzip(zip);
      final apk = files.entries.firstWhere(
        (e) => e.key.toLowerCase().endsWith('.apk'),
        orElse: () => throw StateError('لم أجد ملف APK داخل الناتج.'),
      );
      final base = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final out = File('${base.path}/${p.fileName}.apk');
      await out.writeAsBytes(apk.value);
      if (mounted) setState(() => _apkPath = out.path);
    } catch (e) {
      if (mounted) {
        setState(() => _log.writeln('خطأ: $e'));
        snack(context, '$e');
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Color _dot(String status) {
    switch (status) {
      case 'تم':
        return kAccent;
      case 'فشل':
        return kBad;
      case 'بانتظار':
        return const Color(0xFF3A4A5B);
      default:
        return kWarn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.i,
      builder: (context, _) {
        final projects = Store.i.projects;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(
              kicker: 'My apps · القائمة 3',
              title: 'البناء',
              subtitle: 'ابنِ ملف APK عبر GitHub من داخل التطبيق، دون فتح GitHub.',
            ),
            const SizedBox(height: 18),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('اختر التطبيق'),
                  SegmentedButton<int>(
                    segments: [
                      for (var i = 0; i < projects.length; i++)
                        ButtonSegment(
                          value: i,
                          label: Text(i == 0 ? 'التطبيق الأول' : 'التطبيق الثاني'),
                        ),
                    ],
                    selected: {_sel},
                    onSelectionChanged:
                        _busy ? null : (s) => setState(() => _sel = s.first),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _busy ? null : _build,
                    child: const Text('ابنِ APK'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'مفتاح التوقيع ثابت لكل تطبيق، فكل نسخة جديدة تتحدّث فوق القديمة.',
                    style: TextStyle(fontSize: 12, color: kAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('مراحل البناء',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final s in Stage.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _dot(_status[s]!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_labels[s]!)),
                          Text(_status[s]!,
                              style: const TextStyle(fontSize: 12, color: kMuted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('سجل البناء',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1017),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kField),
                    ),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: SelectableText(
                        _log.isEmpty
                            ? 'سيظهر سجل البناء هنا مباشرة.'
                            : tail(_log.toString(), 5000),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF9BE7DC),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'عند فشل البناء يقرأ التطبيق الخطأ، يصلح الكود بالذكاء الاصطناعي، ويعيد المحاولة تلقائياً (حتى 3 مرات).',
                    style: TextStyle(fontSize: 12, height: 1.5, color: kMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _apkPath == null ? null : () => OpenFilex.open(_apkPath!),
              icon: const Icon(Icons.download),
              label: const Text('تنزيل / تثبيت APK'),
            ),
            if (_apkPath != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'تم حفظ الملف: $_apkPath',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12, color: kMuted),
              ),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

// ===== preview_screen.dart =====
/// Real preview: GitHub builds a Flutter Web version, the app downloads it,
/// serves it on 127.0.0.1 and shows it in a WebView.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.project});

  final AppProject project;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  HttpServer? _server;
  WebViewController? _web;
  String _message = 'جارٍ تجهيز المعاينة…';
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final zip = await BuildService.run(
        widget.project,
        'web',
        (stage, msg) {
          if (mounted) setState(() => _message = msg);
        },
        (_) {},
      );
      final files = unzip(zip);

      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/preview_${widget.project.slug}');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
      for (final e in files.entries) {
        final f = File('${dir.path}/${e.key}');
        await f.create(recursive: true);
        await f.writeAsBytes(e.value);
      }

      final handler = createStaticHandler(dir.path, defaultDocument: 'index.html');
      final server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
      _server = server;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse('http://127.0.0.1:${server.port}/'));
      if (mounted) setState(() => _web = controller);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final web = _web;
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة فعلية')),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(_error!, style: const TextStyle(color: kBad)),
              ),
            )
          : web == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_message, style: const TextStyle(color: kMuted)),
                      const SizedBox(height: 6),
                      const Text('قد يستغرق بضع دقائق.',
                          style: TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ),
                )
              : WebViewWidget(controller: web),
    );
  }
}

// ===== main.dart =====
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.i.load();
  runApp(const MyApps());
}

class MyApps extends StatelessWidget {
  const MyApps({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My apps',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [KeysScreen(), AppsScreen(), BuildScreen()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.vpn_key_outlined),
            selectedIcon: Icon(Icons.vpn_key),
            label: 'المفاتيح',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'التطبيقات',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'البناء',
          ),
        ],
      ),
    );
  }
}
