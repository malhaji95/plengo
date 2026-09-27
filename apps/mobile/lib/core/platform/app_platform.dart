import 'package:flutter/foundation.dart';

/// Platform name the API expects in `X-App-Platform` and session records.
String appPlatformName() {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}
