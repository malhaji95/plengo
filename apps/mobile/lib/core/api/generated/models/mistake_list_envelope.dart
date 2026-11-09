// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mistake_list.dart';

part 'mistake_list_envelope.g.dart';

@JsonSerializable()
class MistakeListEnvelope {
  const MistakeListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory MistakeListEnvelope.fromJson(Map<String, Object?> json) => _$MistakeListEnvelopeFromJson(json);
  
  final bool success;
  final MistakeList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$MistakeListEnvelopeToJson(this);
}
