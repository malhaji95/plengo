import 'dart:typed_data';

/// Where pack images live (spec §22.5).
abstract interface class PackFileStore {
  /// Stores [bytes] under [name] and returns the path to read it back.
  Future<String> write(String name, Uint8List bytes);
  Future<Uint8List?> read(String path);
  Future<void> delete(String path);

  /// Logout and account deletion remove every pack file.
  Future<void> deleteAll();
}

/// For tests and platforms without a file system.
class MemoryPackFiles implements PackFileStore {
  final files = <String, Uint8List>{};

  @override
  Future<String> write(String name, Uint8List bytes) async => (files['mem/$name'] = bytes, 'mem/$name').$2;

  @override
  Future<Uint8List?> read(String path) async => files[path];

  @override
  Future<void> delete(String path) async => files.remove(path);

  @override
  Future<void> deleteAll() async => files.clear();
}
