import 'package:archive/archive.dart';

import 'ai_service.dart';
import 'github_service.dart';
import 'store.dart';
import 'util.dart';

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
