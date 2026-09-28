import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/offline/pack_files_io.dart';

/// Pack images are encrypted at rest (spec §22.5).
void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('packs'));
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('round-trips with the derived key and stores no plaintext', () async {
    final key = await EncryptedPackFiles.deriveKey('ab' * 32);
    final files = EncryptedPackFiles(dir, key);
    final image = Uint8List.fromList(List.generate(4096, (i) => i % 251));
    final path = await files.write('m1-1', image);
    final raw = await File(path).readAsBytes();
    expect(raw.length, image.length + 12 + 16);
    expect(String.fromCharCodes(raw).contains(String.fromCharCodes(image.sublist(0, 64))), isFalse);
    expect(await files.read(path), image);
  });

  test('another device key cannot read the file, and tampering is detected', () async {
    final files = EncryptedPackFiles(dir, await EncryptedPackFiles.deriveKey('ab' * 32));
    final path = await files.write('m1-1', Uint8List.fromList([1, 2, 3]));
    final other = EncryptedPackFiles(dir, await EncryptedPackFiles.deriveKey('cd' * 32));
    expect(await other.read(path), isNull);
    final bytes = await File(path).readAsBytes();
    bytes[20] ^= 0xFF;
    await File(path).writeAsBytes(bytes);
    expect(await files.read(path), isNull);
  });

  test('deleteAll removes every pack file (logout)', () async {
    final files = EncryptedPackFiles(dir, SecretKey(List.filled(32, 7)));
    await files.write('a', Uint8List(10));
    await files.deleteAll();
    expect(await dir.exists(), isFalse);
  });
}
