import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/storage/secure_storage.dart';
import 'features/whats_new/application/whats_new_controller.dart';

Future<void> main() async {
  // Release builds must talk to the backend over HTTPS. This catches a build made
  // without `--dart-define-from-file=dart_defines/prod.json` (which would fall back
  // to the http://10.0.2.2 emulator default) before any request is sent.
  if (kReleaseMode && !AppConfig.apiBaseUrl.startsWith('https://')) {
    runApp(const _ConfigErrorApp());
    return;
  }

  // "What's new" shows after updates only: a fresh install (no saved session on the
  // first run) is marked as already seen.
  WidgetsFlutterBinding.ensureInitialized();
  var hasSavedSession = false;
  try {
    final token = await SecureStorage(const FlutterSecureStorage()).readAccessToken();
    hasSavedSession = token != null && token.isNotEmpty;
  } catch (_) {}
  await WhatsNewController.markFreshInstall(hasSavedSession: hasSavedSession);

  runApp(const ProviderScope(child: HudaayahApp()));
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This build is misconfigured (insecure API address). '
              'Please install the latest version.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
