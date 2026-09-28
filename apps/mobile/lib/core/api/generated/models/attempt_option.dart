// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'attempt_option.g.dart';

@JsonSerializable()
class AttemptOption {
  const AttemptOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
  
  factory AttemptOption.fromJson(Map<String, Object?> json) => _$AttemptOptionFromJson(json);
  
  final String id;
  final String text;
  @JsonKey(includeIfNull: true)
  final bool? isCorrect;

  Map<String, Object?> toJson() => _$AttemptOptionToJson(this);
}
