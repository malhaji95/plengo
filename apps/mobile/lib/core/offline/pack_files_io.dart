import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import 'pack_files.dart';

/// The pack file store of Android and iOS, under the app's private support directory.
Future<PackFileStore?> openNativePackFiles(String databaseKeyHex) async => EncryptedPackFiles(
  Directory('${(await getApplicationSupportDirectory()).path}/packs'),
  await EncryptedPackFiles.deriveKey(databaseKeyHex),
);

/// Pack images encrypted with AES-256-GCM in the app's private directory. The key is derived
/// (HKDF-SHA256) from the per-device database key kept in Keychain/Keystore, so it never touches
/// disk. File layout: 12-byte nonce, ciphertext, 16-byte tag.
class EncryptedPackFiles implements PackFileStore {
  EncryptedPackFiles(this.dir, this._key);

  final Directory dir;
  final SecretKey _key;
  static final _aes = AesGcm.with256bits();

  static Future<SecretKey> deriveKey(String databaseKeyHex) {
    final secret = [
      for (var i = 0; i < databaseKeyHex.length; i += 2) int.parse(databaseKeyHex.substring(i, i + 2), radix: 16),
    ];
    return Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    ).deriveKey(secretKey: SecretKey(secret), info: utf8.encode('plengo-offline-images-v1'), nonce: const []);
  }

  @override
  Future<String> write(String name, Uint8List bytes) async {
    await dir.create(recursive: true);
    final box = await _aes.encrypt(bytes, secretKey: _key);
    final file = File('${dir.path}/$name.bin');
    await file.writeAsBytes(box.concatenation(), flush: true);
    return file.path;
  }

  @override
  Future<Uint8List?> read(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final box = SecretBox.fromConcatenation(
        await file.readAsBytes(),
        nonceLength: _aes.nonceLength,
        macLength: _aes.macAlgorithm.macLength,
      );
      return Uint8List.fromList(await _aes.decrypt(box, secretKey: _key));
    } on SecretBoxAuthenticationError {
      return null; // tampered with or written under another key
    }
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteAll() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
