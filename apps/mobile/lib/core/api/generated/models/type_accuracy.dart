// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'type_accuracy_type.dart';

part 'type_accuracy.g.dart';

@JsonSerializable()
class TypeAccuracy {
  const TypeAccuracy({
    required this.answered,
    required this.correct,
    required this.accuracyPercent,
    required this.type,
  });
  
  factory TypeAccuracy.fromJson(Map<String, Object?> json) => _$TypeAccuracyFromJson(json);
  
  final int answered;
  final int correct;
  @JsonKey(includeIfNull: true)
  final int? accuracyPercent;
  final TypeAccuracyType type;

  Map<String, Object?> toJson() => _$TypeAccuracyToJson(this);
}
