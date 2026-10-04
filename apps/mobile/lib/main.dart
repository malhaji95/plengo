import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/flags.dart';
import 'app/providers.dart';
import 'core/auth/token_store.dart';
import 'core/db/database_key.dart';
import 'core/db/open_database.dart';
import 'core/offline/native_pack_files.dart';
import 'core/platform/app_platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  LicenseRegistry.addLicense(_fontLicenses);
  await _decodeSplashLogo();

  final info = await PackageInfo.fromPlatform();
  final env = AppEnvironment(platform: appPlatformName(), appVersion: info.version);
  final db = await openAppDatabase();
  // Pack images: AES-GCM with a key derived from the device's database key (spec §22.5).
  final packFiles = env.isWeb ? null : await openNativePackFiles(await loadOrCreateDatabaseKey());

  Widget app = ProviderScope(
    overrides: [
      appEnvironmentProvider.overrideWithValue(env),
      tokenStoreProvider.overrideWithValue(env.isWeb ? MemoryTokenStore() : SecureTokenStore()),
      databaseProvider.overrideWithValue(db),
      if (packFiles != null) packFilesProvider.overrideWithValue(packFiles),
    ],
    child: const PlengoApp(),
  );

  if (AppFlags.sentryDsn.isEmpty) {
    runApp(app);
    return;
  }
  await SentryFlutter.init((options) {
    options.dsn = AppFlags.sentryDsn;
    options.release = 'plengo@${info.version}+${info.buildNumber}';
    options.sendDefaultPii = false;
  }, appRunner: () => runApp(app));
}

/// Both bundled fonts are under the SIL Open Font License, which travels with the app.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final (font, file) in [
    ('IBM Plex Sans Arabic', 'assets/fonts/OFL.txt'),
    ('Noto Kufi Arabic', 'assets/fonts/OFL-NotoKufiArabic.txt'),
  ]) {
    yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString(file));
  }
}

/// The splash shows the logo from its first frame instead of popping it in after the spinner.
Future<void> _decodeSplashLogo() async {
  final done = Completer<void>();
  final stream = const AssetImage('assets/brand/wordmark-color.png').resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, _) => done.isCompleted ? null : done.complete(),
    onError: (_, _) => done.isCompleted ? null : done.complete(),
  );
  stream.addListener(listener);
  await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  stream.removeListener(listener);
}
