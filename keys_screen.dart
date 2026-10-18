import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';

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
