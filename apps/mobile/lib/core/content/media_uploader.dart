import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';

/// Student uploads: at most 2 MB, PNG/JPEG/WebP (spec §12.4).
const maxStudentUploadBytes = 2 * 1024 * 1024;

/// The image type from its first bytes, or null when it is not an accepted image.
String? sniffImageType(Uint8List b) {
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'image/jpeg';
  if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
  if (b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

/// The direct-to-storage upload flow (spec §12.3): create → PUT the bytes to the presigned URL →
/// complete. Processing then runs on the server; the returned media id can be attached right away.
class MediaUploader {
  MediaUploader(this.client);

  final ApiClient client;

  Future<String> upload(Uint8List bytes, MediaKind kind) async {
    final type = sniffImageType(bytes);
    if (type == null) throw const ApiException('VALIDATION_ERROR', 'نوع الصورة غير مدعوم');
    if (bytes.length > maxStudentUploadBytes) {
      throw const ApiException('VALIDATION_ERROR', 'حجم الصورة أكبر من 2 ميغابايت');
    }
    return guardApi(() async {
      final created = (await client.api.uploads.studentCreateUpload(
        body: CreateUploadRequest(kind: kind, contentType: type, size: bytes.length),
      )).data;
      await client.uploadDio.request<void>(
        created.uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          method: created.method,
          headers: {...created.headers, Headers.contentLengthHeader: bytes.length},
          contentType: type,
        ),
      );
      await client.api.uploads.studentCompleteUpload(id: created.id);
      return created.id;
    });
  }

  /// Waits until the server has processed the image (avatars must be ready to attach).
  Future<MediaFile> waitReady(String id, {Duration every = const Duration(seconds: 1), int tries = 20}) =>
      guardApi(() async {
        for (var i = 0; ; i++) {
          final m = (await client.api.uploads.studentGetUpload(id: id)).data;
          if (m.status != MediaFileStatus.pending || i >= tries) return m;
          await Future<void>.delayed(every);
        }
      });
}
