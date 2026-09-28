// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_deck.dart';

part 'student_deck_envelope.g.dart';

@JsonSerializable()
class StudentDeckEnvelope {
  const StudentDeckEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory StudentDeckEnvelope.fromJson(Map<String, Object?> json) => _$StudentDeckEnvelopeFromJson(json);
  
  final bool success;
  final StudentDeck data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentDeckEnvelopeToJson(this);
}
