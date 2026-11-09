// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum SyncRejectionCode {
  @JsonValue('QUOTA_EXCEEDED')
  quotaExceeded('QUOTA_EXCEEDED'),
  @JsonValue('VALIDATION_ERROR')
  validationError('VALIDATION_ERROR'),
  @JsonValue('CONTENT_LOCKED')
  contentLocked('CONTENT_LOCKED'),
  @JsonValue('NOT_FOUND')
  notFound('NOT_FOUND');

  const SyncRejectionCode(this.json);

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError('Cannot convert enum value with null JSON representation to String. '
          'This usually happens for \$unknown or @JsonValue(null) entries.');
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();
}
