import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';
import '../services/store.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'preview_screen.dart';

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
