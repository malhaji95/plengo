// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'answers.g.dart';

@JsonSerializable()
class Answers {
  const Answers({
    required this.number,
    required this.answer,
  });
  
  factory Answers.fromJson(Map<String, Object?> json) => _$AnswersFromJson(json);
  
  final int number;
  final String answer;

  Map<String, Object?> toJson() => _$AnswersToJson(this);
}
