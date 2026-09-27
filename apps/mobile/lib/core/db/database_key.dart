import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-device SQLCipher key kept in Keychain/Keystore (spec §22.5). Generated on first launch.
Future<String> loadOrCreateDatabaseKey([FlutterSecureStorage storage = const FlutterSecureStorage()]) async {
  const name = 'db.encryption_key';
  final existing = await storage.read(key: name);
  if (existing != null) return existing;
  final random = Random.secure();
  final key = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  await storage.write(key: name, value: key);
  return key;
}
