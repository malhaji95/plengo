// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'read_result.g.dart';

@JsonSerializable()
class ReadResult {
  const ReadResult({required this.unreadCount});

  factory ReadResult.fromJson(Map<String, Object?> json) => _$ReadResultFromJson(json);

  final int unreadCount;

  Map<String, Object?> toJson() => _$ReadResultToJson(this);
}
