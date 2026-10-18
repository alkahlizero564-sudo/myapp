import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'store.dart';
import 'util.dart';
import 'workflow_template.dart';

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
