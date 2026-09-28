// The platform's pack file store: encrypted files on Android and iOS, none on web.
export 'pack_files_stub.dart' if (dart.library.io) 'pack_files_io.dart';
