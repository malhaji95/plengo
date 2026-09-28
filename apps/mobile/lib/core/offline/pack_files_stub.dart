import 'pack_files.dart';

/// No pack files on web (spec §22.8).
Future<PackFileStore?> openNativePackFiles(String databaseKeyHex) async => null;
