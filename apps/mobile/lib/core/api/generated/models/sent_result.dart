// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sent_result.g.dart';

@JsonSerializable()
class SentResult {
  const SentResult({
    required this.sent,
  });
  
  factory SentResult.fromJson(Map<String, Object?> json) => _$SentResultFromJson(json);
  
  final bool sent;

  Map<String, Object?> toJson() => _$SentResultToJson(this);
}
