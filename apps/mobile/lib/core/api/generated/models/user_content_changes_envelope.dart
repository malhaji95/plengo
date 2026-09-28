// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_content_changes.dart';

part 'user_content_changes_envelope.g.dart';

@JsonSerializable()
class UserContentChangesEnvelope {
  const UserContentChangesEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory UserContentChangesEnvelope.fromJson(Map<String, Object?> json) => _$UserContentChangesEnvelopeFromJson(json);
  
  final bool success;
  final UserContentChanges data;
  final dynamic error;

  Map<String, Object?> toJson() => _$UserContentChangesEnvelopeToJson(this);
}
