// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'accuracy.g.dart';

@JsonSerializable()
class Accuracy {
  const Accuracy({required this.answered, required this.correct, required this.accuracyPercent});

  factory Accuracy.fromJson(Map<String, Object?> json) => _$AccuracyFromJson(json);

  final int answered;
  final int correct;
  @JsonKey(includeIfNull: true)
  final int? accuracyPercent;

  Map<String, Object?> toJson() => _$AccuracyToJson(this);
}
