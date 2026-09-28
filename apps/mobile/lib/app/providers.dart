import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/generated/export.dart';
import '../core/auth/auth_repository.dart';
import '../core/auth/token_store.dart';
import '../core/config/version.dart';
import '../core/db/app_database.dart';
import '../core/home/home_repository.dart';
import '../core/home/push_messaging.dart';
import '../core/offline/pack_files.dart';
import 'flags.dart';

/// Values fixed for the lifetime of the process, provided by `main`.
class AppEnvironment {
  const AppEnvironment({required this.platform, required this.appVersion});

  /// 'android' | 'ios' | 'web'
  final String platform;
  final String appVersion;

  bool get isWeb => platform == 'web';
}

final appEnvironmentProvider = Provider<AppEnvironment>((ref) => throw UnimplementedError('override in main'));
final tokenStoreProvider = Provider<TokenStore>((ref) => throw UnimplementedError('override in main'));
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override in main'));

/// Encrypted pack image files (spec §22.5); `main` provides the real store on Android and iOS.
final packFilesProvider = Provider<PackFileStore>((ref) => MemoryPackFiles());

final apiClientProvider = Provider<ApiClient>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return ApiClient(
    baseUrl: AppFlags.apiBaseUrl,
    tokens: ref.watch(tokenStoreProvider),
    platform: env.platform,
    appVersion: env.appVersion,
    useCookies: env.isWeb,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).sessionExpired(),
    onUpdateRequired: () => ref.read(updateRequiredProvider.notifier).require(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(client: ref.watch(apiClientProvider), platform: ref.watch(appEnvironmentProvider).platform);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) => HomeRepository(ref.watch(apiClientProvider)));

/// Where push tokens come from; `main` swaps in FCM when the build carries Firebase config.
final pushMessagingProvider = Provider<PushMessaging>((ref) => const NoPushMessaging());

final pushRegistrationProvider = Provider<PushRegistration>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return PushRegistration(
    ref.watch(pushMessagingProvider),
    ref.watch(homeRepositoryProvider),
    platform: env.platform,
    appVersion: env.appVersion,
  );
});

/// Set when the API answers APP_UPDATE_REQUIRED or the config says this build is too old.
class UpdateRequiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void require() => state = true;
}

final updateRequiredProvider = NotifierProvider<UpdateRequiredNotifier, bool>(UpdateRequiredNotifier.new);

/// Remote config (spec §10.2), or null when it cannot be fetched (offline start must not block).
final remoteConfigProvider = FutureProvider<RemoteConfig?>((ref) async {
  try {
    return (await ref.watch(apiClientProvider).api.config.getConfig()).data;
  } catch (_) {
    return null;
  }
});

/// Signed-in student, or null when signed out. Loading while the session is restored.
class AuthController extends AsyncNotifier<Me?> {
  @override
  Future<Me?> build() async {
    await _checkMinimumVersion();
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> _checkMinimumVersion() async {
    final env = ref.read(appEnvironmentProvider);
    final config = await ref.read(remoteConfigProvider.future);
    if (config == null) return; // The server enforces the minimum version anyway.
    final min = switch (env.platform) {
      'ios' => config.minSupportedVersion.ios,
      'web' => config.minSupportedVersion.web,
      _ => config.minSupportedVersion.android,
    };
    if (compareVersions(env.appVersion, min) < 0) ref.read(updateRequiredProvider.notifier).require();
  }

  Future<void> login(String email, String password) async {
    final me = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password, appVersion: ref.read(appEnvironmentProvider).appVersion);
    state = AsyncData(me);
  }

  Future<void> logout() async {
    // Revoke this device's push token while the session can still authenticate the call.
    await ref.read(pushRegistrationProvider).stop();
    await ref.read(authRepositoryProvider).logout();
    await ref.read(databaseProvider).wipe();
    // Pack files go too (§22.5): their key is derived from this device's database key.
    await ref.read(packFilesProvider).deleteAll();
    state = const AsyncData(null);
  }

  /// Replace the signed-in profile after it changed on the server (e.g. a new placement).
  void setMe(Me me) => state = AsyncData(me);

  void sessionExpired() {
    if (state.value != null) state = const AsyncData(null);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Me?>(AuthController.new);

/// Appearance settings (spec §25): dark mode and three font-size steps, stored locally.
class AppearanceSettings {
  const AppearanceSettings({this.themeMode = ThemeMode.system, this.fontStep = 1});

  final ThemeMode themeMode;

  /// 0 = small, 1 = normal, 2 = large
  final int fontStep;

  static const fontScales = [0.9, 1.0, 1.15];
  double get textScale => fontScales[fontStep];

  AppearanceSettings copyWith({ThemeMode? themeMode, int? fontStep}) =>
      AppearanceSettings(themeMode: themeMode ?? this.themeMode, fontStep: fontStep ?? this.fontStep);
}

class AppearanceController extends Notifier<AppearanceSettings> {
  static const _themeKey = 'settings.theme_mode';
  static const _fontKey = 'settings.font_step';

  @override
  AppearanceSettings build() {
    unawaited(_load());
    return const AppearanceSettings();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final theme = await db.getValue(_themeKey);
    final font = int.tryParse(await db.getValue(_fontKey) ?? '');
    state = AppearanceSettings(
      themeMode: ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system),
      fontStep: font != null && font >= 0 && font <= 2 ? font : 1,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(databaseProvider).setValue(_themeKey, mode.name);
  }

  Future<void> setFontStep(int step) async {
    state = state.copyWith(fontStep: step.clamp(0, 2));
    await ref.read(databaseProvider).setValue(_fontKey, '${state.fontStep}');
  }
}

final appearanceProvider = NotifierProvider<AppearanceController, AppearanceSettings>(AppearanceController.new);
