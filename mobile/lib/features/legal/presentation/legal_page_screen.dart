import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';

/// Shows a Hudaayah legal page (privacy, terms, delete-account) inside the app.
///
/// JavaScript is disabled (the pages are static). Navigation to any host other
/// than the legal host (e.g. the Quran Foundation link) opens externally.
class LegalPageScreen extends StatefulWidget {
  const LegalPageScreen({super.key, required this.page});

  /// One of `privacy`, `terms`, `delete-account`.
  final String page;

  static String? titleFor(String page) => switch (page) {
        'privacy' => 'Privacy Policy',
        'terms' => 'Terms of Use',
        'delete-account' => 'Delete account',
        _ => null,
      };

  static String? urlFor(String page) => switch (page) {
        'privacy' => AppConfig.privacyPolicyUrl,
        'terms' => AppConfig.termsUrl,
        'delete-account' => AppConfig.deleteAccountUrl,
        _ => null,
      };

  @override
  State<LegalPageScreen> createState() => _LegalPageScreenState();
}

class _LegalPageScreenState extends State<LegalPageScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final url = LegalPageScreen.urlFor(widget.page);
    if (url == null) return;
    final allowedHost = Uri.parse(AppConfig.privacyPolicyUrl).host;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.host == allowedHost) {
              return NavigationDecision.navigate;
            }
            if (uri != null) {
              launchUrl(uri, mode: LaunchMode.externalApplication)
                  .catchError((_) => false);
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _progress = 0;
            });
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) setState(() => _hasError = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final title = LegalPageScreen.titleFor(widget.page);
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Page not found')),
      body: controller == null
          ? const Center(child: Text('This page is not available.'))
          : Stack(
              children: [
                Positioned.fill(child: WebViewWidget(controller: controller)),
                if (_hasError)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Could not load this page. Check your connection and try again.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _retry,
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_progress < 100)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _progress == 0 ? null : _progress / 100,
                    ),
                  ),
              ],
            ),
    );
  }
}
