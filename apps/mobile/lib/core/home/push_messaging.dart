import 'dart:async';

import 'home_repository.dart';

/// The device side of push (spec §20.3): where a push token comes from. The FCM plugin needs the
/// Firebase project files (google-services.json, GoogleService-Info.plist) that only exist in
/// release configuration, so builds without them use [NoPushMessaging]: the in-app inbox still
/// works, only the system notification is missing.
abstract interface class PushMessaging {
  /// Asks for permission where the OS requires it; null when push is unavailable or refused.
  Future<String?> token();

  Stream<String> get tokenRefreshes;
}

class NoPushMessaging implements PushMessaging {
  const NoPushMessaging();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}

/// Keeps the server's copy of this device's push token current while signed in, and revokes it at
/// sign-out so a shared device stops receiving the previous student's notifications.
class PushRegistration {
  PushRegistration(this.messaging, this.repository, {required this.platform, required this.appVersion});

  final PushMessaging messaging;
  final HomeRepository repository;
  final String platform;
  final String appVersion;

  String? _registered;
  StreamSubscription<String>? _refreshes;

  String? get registeredToken => _registered;

  Future<void> start() async {
    _refreshes ??= messaging.tokenRefreshes.listen((t) => unawaited(_register(t)));
    final token = await messaging.token();
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    if (token == _registered) return;
    try {
      await repository.registerPushToken(token, platform: platform, appVersion: appVersion);
      _registered = token;
    } catch (_) {
      // Retried at the next start; the inbox does not depend on it.
    }
  }

  /// Stops listening without calling the server (the account is gone, and its tokens with it).
  Future<void> forget() async {
    unawaited(_refreshes?.cancel());
    _refreshes = null;
    _registered = null;
  }

  Future<void> stop() async {
    // Not awaited: nothing depends on it, and some streams complete cancel on the root zone.
    unawaited(_refreshes?.cancel());
    _refreshes = null;
    final token = _registered;
    _registered = null;
    if (token == null) return;
    try {
      await repository.revokePushToken(token);
    } catch (_) {
      // Offline sign-out: the server drops tokens FCM reports as unregistered.
    }
  }
}
