// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'subject_list.dart';

part 'subject_list_envelope.g.dart';

@JsonSerializable()
class SubjectListEnvelope {
  const SubjectListEnvelope({required this.success, required this.data, required this.error});

  factory SubjectListEnvelope.fromJson(Map<String, Object?> json) => _$SubjectListEnvelopeFromJson(json);

  final bool success;
  final SubjectList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SubjectListEnvelopeToJson(this);
}
