// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_deck_list.dart';

part 'student_deck_list_envelope.g.dart';

@JsonSerializable()
class StudentDeckListEnvelope {
  const StudentDeckListEnvelope({required this.success, required this.data, required this.error});

  factory StudentDeckListEnvelope.fromJson(Map<String, Object?> json) => _$StudentDeckListEnvelopeFromJson(json);

  final bool success;
  final StudentDeckList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentDeckListEnvelopeToJson(this);
}
