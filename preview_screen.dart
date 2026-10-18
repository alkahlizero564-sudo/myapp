import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/build_service.dart';
import '../services/store.dart';
import '../theme.dart';

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
