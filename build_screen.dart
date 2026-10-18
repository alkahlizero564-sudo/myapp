import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../services/build_service.dart';
import '../services/store.dart';
import '../services/util.dart';
import '../theme.dart';

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
