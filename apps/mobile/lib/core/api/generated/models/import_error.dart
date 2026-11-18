// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'import_error.g.dart';

@JsonSerializable()
class ImportError {
  const ImportError({
    required this.rowNumber,
    required this.field,
    required this.message,
  });
  
  factory ImportError.fromJson(Map<String, Object?> json) => _$ImportErrorFromJson(json);
  
  final int rowNumber;
  @JsonKey(includeIfNull: true)
  final String? field;
  final String message;

  Map<String, Object?> toJson() => _$ImportErrorToJson(this);
}
