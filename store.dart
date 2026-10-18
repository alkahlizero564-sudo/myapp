import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

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
