import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/flags.dart';
import 'app/providers.dart';
import 'core/auth/token_store.dart';
import 'core/db/open_database.dart';
import 'core/platform/app_platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final info = await PackageInfo.fromPlatform();
  final env = AppEnvironment(platform: appPlatformName(), appVersion: info.version);
  final db = await openAppDatabase();

  Widget app = ProviderScope(
    overrides: [
      appEnvironmentProvider.overrideWithValue(env),
      tokenStoreProvider.overrideWithValue(env.isWeb ? MemoryTokenStore() : SecureTokenStore()),
      databaseProvider.overrideWithValue(db),
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
