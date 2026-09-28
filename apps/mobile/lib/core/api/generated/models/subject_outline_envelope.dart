// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'subject_outline.dart';

part 'subject_outline_envelope.g.dart';

@JsonSerializable()
class SubjectOutlineEnvelope {
  const SubjectOutlineEnvelope({required this.success, required this.data, required this.error});

  factory SubjectOutlineEnvelope.fromJson(Map<String, Object?> json) => _$SubjectOutlineEnvelopeFromJson(json);

  final bool success;
  final SubjectOutline data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SubjectOutlineEnvelopeToJson(this);
}
