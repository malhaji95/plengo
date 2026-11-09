// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'resume_list.dart';

part 'resume_list_envelope.g.dart';

@JsonSerializable()
class ResumeListEnvelope {
  const ResumeListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory ResumeListEnvelope.fromJson(Map<String, Object?> json) => _$ResumeListEnvelopeFromJson(json);
  
  final bool success;
  final ResumeList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$ResumeListEnvelopeToJson(this);
}
